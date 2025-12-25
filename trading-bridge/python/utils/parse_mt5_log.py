#!/usr/bin/env python3
"""
CLI tool for parsing MT5 mobile app logs
"""
import sys
import json
import csv
import argparse
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from log_parser import MT5LogParser, EventType


def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Parse MT5 mobile app logs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Parse from file
  python parse_mt5_log.py -i log.txt
  
  # Parse from stdin
  cat log.txt | python parse_mt5_log.py
  
  # Output as JSON
  python parse_mt5_log.py -i log.txt -f json
  
  # Output as CSV
  python parse_mt5_log.py -i log.txt -f csv -o output.csv
  
  # Filter by account
  python parse_mt5_log.py -i log.txt --account 411534497
  
  # Filter by event type
  python parse_mt5_log.py -i log.txt --event connection_url
  
  # Show summary only
  python parse_mt5_log.py -i log.txt --summary
"""
    )
    
    parser.add_argument(
        '-i', '--input',
        type=str,
        help='Input log file (default: stdin)'
    )
    
    parser.add_argument(
        '-o', '--output',
        type=str,
        help='Output file (default: stdout)'
    )
    
    parser.add_argument(
        '-f', '--format',
        choices=['json', 'csv', 'text'],
        default='text',
        help='Output format (default: text)'
    )
    
    parser.add_argument(
        '--account',
        type=str,
        help='Filter by account ID'
    )
    
    parser.add_argument(
        '--event',
        type=str,
        help='Filter by event type'
    )
    
    parser.add_argument(
        '--start',
        type=str,
        help='Start time filter (ISO format: YYYY-MM-DD HH:MM:SS)'
    )
    
    parser.add_argument(
        '--end',
        type=str,
        help='End time filter (ISO format: YYYY-MM-DD HH:MM:SS)'
    )
    
    parser.add_argument(
        '--summary',
        action='store_true',
        help='Show summary statistics only'
    )
    
    parser.add_argument(
        '--save-to-data',
        action='store_true',
        help='Save parsed logs to data directory'
    )
    
    return parser.parse_args()


def output_text(entries, file=None):
    """Output entries in text format"""
    output = file if file else sys.stdout
    
    for entry in entries:
        server_info = f" [Server: {entry.server}]" if entry.server else ""
        print(
            f"{entry.timestamp.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]} "
            f"[{entry.level.value:7s}] "
            f"Account:{entry.account_id} "
            f"Event:{entry.event_type.value:25s} "
            f"{entry.message[:80]}{server_info}",
            file=output
        )


def output_json(entries, file=None):
    """Output entries in JSON format"""
    output = file if file else sys.stdout
    data = [entry.to_dict() for entry in entries]
    json.dump(data, output, indent=2)
    if file:
        output.write('\n')


def output_csv(entries, file=None):
    """Output entries in CSV format"""
    output = file if file else sys.stdout
    
    if not entries:
        return
    
    fieldnames = ['timestamp', 'level', 'account_id', 'event_type', 'message', 'server']
    writer = csv.DictWriter(output, fieldnames=fieldnames)
    writer.writeheader()
    
    for entry in entries:
        writer.writerow({
            'timestamp': entry.timestamp.isoformat(),
            'level': entry.level.value,
            'account_id': entry.account_id,
            'event_type': entry.event_type.value,
            'message': entry.message,
            'server': entry.server or ''
        })


def save_to_data_dir(entries):
    """Save entries to data directory"""
    # Create data directory
    data_dir = Path(__file__).parent.parent.parent / 'data' / 'logs'
    data_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate filename with timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    json_file = data_dir / f'mt5_log_{timestamp}.json'
    
    # Save as JSON
    with open(json_file, 'w', encoding='utf-8') as f:
        data = [entry.to_dict() for entry in entries]
        json.dump(data, f, indent=2)
    
    print(f"Saved {len(entries)} entries to: {json_file}", file=sys.stderr)
    return json_file


def main():
    """Main entry point"""
    args = parse_args()
    
    # Read input
    if args.input:
        with open(args.input, 'r', encoding='utf-8') as f:
            text = f.read()
    else:
        text = sys.stdin.read()
    
    # Parse logs
    parser = MT5LogParser()
    entries = parser.parse_text(text)
    
    if not entries:
        print("No log entries found", file=sys.stderr)
        return 1
    
    # Apply filters cumulatively
    if args.account:
        entries = [e for e in entries if e.account_id == args.account]
    
    if args.event:
        try:
            event_type = EventType(args.event)
            entries = [e for e in entries if e.event_type == event_type]
        except ValueError:
            print(f"Invalid event type: {args.event}", file=sys.stderr)
            print(f"Valid types: {[e.value for e in EventType]}", file=sys.stderr)
            return 1
    
    if args.start:
        start = datetime.fromisoformat(args.start)
        entries = [e for e in entries if e.timestamp >= start]
    
    if args.end:
        end = datetime.fromisoformat(args.end)
        entries = [e for e in entries if e.timestamp <= end]
    
    # Show summary if requested (from filtered entries)
    if args.summary:
        # Temporarily set parser entries to filtered entries for summary
        original_entries = parser.entries
        parser.entries = entries
        summary = parser.get_summary()
        parser.entries = original_entries
        print(json.dumps(summary, indent=2))
        return 0
    
    # Save to data directory if requested
    if args.save_to_data:
        save_to_data_dir(entries)
    
    # Output results
    output_file = None
    if args.output:
        output_file = open(args.output, 'w', encoding='utf-8')
    
    try:
        if args.format == 'json':
            output_json(entries, output_file)
        elif args.format == 'csv':
            output_csv(entries, output_file)
        else:
            output_text(entries, output_file)
    finally:
        if output_file:
            output_file.close()
    
    # Print stats to stderr
    print(f"Processed {len(entries)} log entries", file=sys.stderr)
    
    return 0


if __name__ == '__main__':
    sys.exit(main())

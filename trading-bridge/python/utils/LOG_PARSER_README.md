# MT5 Mobile Log Parser

Utility for parsing and analyzing MetaTrader 5 (MT5) mobile app logs.

## Overview

This utility parses raw log output from the MT5 mobile application, extracting structured information about connection events, service requests, and trading operations.

## Features

- **Parse MT5 mobile logs** - Extract structured data from raw log text
- **Multiple output formats** - Text, JSON, and CSV
- **Event classification** - Automatically categorize log events
- **Filtering** - Filter by account, event type, or time range
- **Summary statistics** - Get quick overview of log contents
- **Data storage** - Save parsed logs to data directory

## Installation

The parser is located in `trading-bridge/python/utils/` and requires Python 3.7+.

No additional dependencies are required - it uses only Python standard library.

## Usage

### Command Line Tool

```bash
# Parse from file
python parse_mt5_log.py -i log.txt

# Parse from stdin
cat log.txt | python parse_mt5_log.py

# Output as JSON
python parse_mt5_log.py -i log.txt -f json

# Output as CSV
python parse_mt5_log.py -i log.txt -f csv -o output.csv

# Show summary only
python parse_mt5_log.py -i log.txt --summary

# Filter by account ID
python parse_mt5_log.py -i log.txt --account 411534497

# Filter by event type
python parse_mt5_log.py -i log.txt --event connection_url

# Save to data directory
python parse_mt5_log.py -i log.txt --save-to-data
```

### As Python Module

```python
from log_parser import MT5LogParser, EventType

# Parse text
parser = MT5LogParser()
entries = parser.parse_text(log_text)

# Parse file
entries = parser.parse_file('path/to/log.txt')

# Get summary
summary = parser.get_summary()

# Filter entries
connection_events = parser.filter_by_event_type(EventType.CONNECTION_URL)
account_entries = parser.filter_by_account('411534497')

# Access parsed data
for entry in entries:
    print(f"{entry.timestamp} - {entry.event_type.value}: {entry.message}")
```

## Log Format

The parser recognizes the following MT5 mobile log format:

```
[个] YYYY.MM.DD HH:MM:SS.mmm Level 'AccountID': message
```

Where:
- `个` - Optional Chinese character prefix (on some lines)
- `YYYY.MM.DD` - Date (e.g., 2025.12.25)
- `HH:MM:SS.mmm` - Time with milliseconds (e.g., 03:58:12.224)
- `Level` - Log level (Debug, Service, Info, Warning, Error)
- `AccountID` - MT5 account number
- `message` - Log message text

## Event Types

The parser automatically classifies log entries into event types:

| Event Type | Description |
|------------|-------------|
| `connection_params` | Request for connection parameters |
| `connection_url` | Connection URL created |
| `websocket_success` | WebSocket connection established |
| `instruments_request` | Request to get instruments list |
| `instruments_success` | Instruments list received |
| `orders_request` | Request to get orders list |
| `order_events_subscribe` | Subscribe to order events |
| `user_events_subscribe` | Subscribe to user events |
| `balance_request` | Request account balance |
| `account_info_request` | Request account information |
| `unknown` | Unrecognized event |

## Output Formats

### Text Format (Default)

Human-readable format with aligned columns:

```
2025-12-25 03:58:12.224 [Debug  ] Account:411534497 Event:connection_params         request for connection params
2025-12-25 03:58:12.227 [Debug  ] Account:411534497 Event:connection_url            connection url created (server: wss://...)
```

### JSON Format

Structured JSON array with full details:

```json
[
  {
    "timestamp": "2025-12-25T03:58:12.224000",
    "level": "Debug",
    "account_id": "411534497",
    "message": "request for connection params",
    "event_type": "connection_params",
    "server": null,
    "raw_line": "..."
  }
]
```

### CSV Format

Comma-separated values for spreadsheet import:

```csv
timestamp,level,account_id,event_type,message,server
2025-12-25T03:58:12.224000,Debug,411534497,connection_params,request for connection params,
```

### Summary Format

Statistics about the log:

```json
{
  "total_entries": 11,
  "account_ids": ["411534497"],
  "event_counts": {
    "connection_params": 1,
    "connection_url": 1,
    "websocket_success": 2,
    ...
  },
  "servers": ["wss://rtapi-sg.domain_placeholder/rtapi/mt5/real8"],
  "time_range": {
    "start": "2025-12-25T03:58:12.224000",
    "end": "2025-12-25T03:58:12.746000"
  }
}
```

## Example

Given this raw MT5 mobile log:

```
Trading Log from my phone
个 25 December 2025 GMT
个 2025.12.25 03:58:12.224 Debug '411534497": request for connection params
2025.12.25 03:58:12.227 Debug '411534497': connection url created (server: wss://rtapi-sg.domain_placeholder/rtapi/mt5/real8)
2025.12.25 03:58:12.234 Service '411534497": request get list of instruments
```

The parser extracts:
- **Timestamps** - Precise timing of each event
- **Account ID** - MT5 account number
- **Event types** - Classified connection and service events
- **Server info** - WebSocket server URL when present
- **Messages** - Full log message text

## Data Storage

Parsed logs can be saved to the `trading-bridge/data/logs/` directory:

```bash
python parse_mt5_log.py -i log.txt --save-to-data
```

Files are saved as JSON with timestamp in filename:
- `mt5_log_20251225_035812.json`

By default, files are saved to `trading-bridge/data/logs/`. You can customize this location by setting the `MT5_LOG_DATA_DIR` environment variable:

```bash
export MT5_LOG_DATA_DIR=/path/to/custom/logs
python parse_mt5_log.py -i log.txt --save-to-data
```

This allows you to build a history of MT5 connection events for analysis.

## Use Cases

1. **Connection Monitoring** - Track connection establishment and failures
2. **Performance Analysis** - Measure time between requests and responses
3. **Debugging** - Investigate connection issues with detailed logs
4. **Audit Trail** - Maintain records of trading system connections
5. **Pattern Detection** - Identify recurring connection problems

## Integration

This parser can be integrated with:
- Trading monitoring systems
- Alert/notification systems (when specific events occur)
- Performance dashboards
- Database logging (store parsed events in DB)
- Automated testing (validate expected connection sequences)

## Limitations

- Only parses the specific MT5 mobile log format shown above
- Does not parse other MT5 log formats (desktop, server logs)
- Event classification based on message keywords (may miss variants)
- Assumes logs are UTF-8 encoded

## Future Enhancements

Potential improvements:
- Support for more log formats (desktop MT5, MT4 logs)
- Database storage (SQLite, PostgreSQL)
- Real-time log streaming and parsing
- Alert rules (notify on specific events)
- Web dashboard for log visualization
- Integration with existing trading bridge monitoring

## Support

For issues or questions about the log parser:
1. Check the example in `log_parser.py` main() function
2. Run with `-h` flag for help: `python parse_mt5_log.py -h`
3. Review the log format documentation above
4. Check that your logs match the expected format

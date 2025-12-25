"""
MT5 Mobile App Log Parser
Parses logs from MetaTrader 5 mobile application
"""
import re
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from enum import Enum


class LogLevel(Enum):
    """Log level enumeration"""
    DEBUG = "Debug"
    SERVICE = "Service"
    INFO = "Info"
    WARNING = "Warning"
    ERROR = "Error"


class EventType(Enum):
    """Event type classification"""
    CONNECTION_PARAMS = "connection_params"
    CONNECTION_URL = "connection_url"
    WEBSOCKET_SUCCESS = "websocket_success"
    INSTRUMENTS_REQUEST = "instruments_request"
    INSTRUMENTS_SUCCESS = "instruments_success"
    ORDERS_REQUEST = "orders_request"
    ORDER_EVENTS_SUBSCRIBE = "order_events_subscribe"
    USER_EVENTS_SUBSCRIBE = "user_events_subscribe"
    BALANCE_REQUEST = "balance_request"
    ACCOUNT_INFO_REQUEST = "account_info_request"
    UNKNOWN = "unknown"


@dataclass
class LogEntry:
    """Parsed log entry"""
    timestamp: datetime
    level: LogLevel
    account_id: str
    message: str
    event_type: EventType
    server: Optional[str] = None
    raw_line: str = ""
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return {
            'timestamp': self.timestamp.isoformat(),
            'level': self.level.value,
            'account_id': self.account_id,
            'message': self.message,
            'event_type': self.event_type.value,
            'server': self.server,
            'raw_line': self.raw_line
        }


class MT5LogParser:
    """Parser for MT5 mobile app logs"""
    
    # Regex pattern for log line
    # Format: [optional prefix] YYYY.MM.DD HH:MM:SS.mmm Level 'AccountID': message
    # Handles various quote formats around account ID
    LOG_PATTERN = re.compile(
        r"^(?:个\s+)?(\d{4}\.\d{2}\.\d{2})\s+(\d{2}:\d{2}:\d{2}\.\d{3})\s+"
        r"(\w+)\s+['\"]?(\d+)['\"]?\s*:\s*(.+)$"
    )
    
    # Server URL pattern
    SERVER_PATTERN = re.compile(r"server:\s*(wss?://[^\)]+)")
    
    def __init__(self):
        """Initialize parser"""
        self.entries: List[LogEntry] = []
    
    def parse_line(self, line: str) -> Optional[LogEntry]:
        """
        Parse a single log line
        
        Args:
            line: Raw log line
            
        Returns:
            Parsed LogEntry or None if line doesn't match pattern
        """
        line = line.strip()
        if not line:
            return None
        
        # Skip header lines (but not log lines with 个 prefix followed by timestamp)
        if line.startswith('Trading Log'):
            return None
        if line.startswith('个') and not re.search(r'\d{4}\.\d{2}\.\d{2}', line):
            return None
        
        match = self.LOG_PATTERN.match(line)
        if not match:
            return None
        
        date_str, time_str, level_str, account_id, message = match.groups()
        
        # Parse timestamp
        timestamp_str = f"{date_str} {time_str}"
        timestamp = datetime.strptime(timestamp_str, "%Y.%m.%d %H:%M:%S.%f")
        
        # Parse level
        try:
            level = LogLevel(level_str)
        except ValueError:
            level = LogLevel.INFO
        
        # Classify event type
        event_type = self._classify_event(message)
        
        # Extract server if present
        server = None
        server_match = self.SERVER_PATTERN.search(message)
        if server_match:
            server = server_match.group(1)
        
        return LogEntry(
            timestamp=timestamp,
            level=level,
            account_id=account_id,
            message=message,
            event_type=event_type,
            server=server,
            raw_line=line
        )
    
    def _classify_event(self, message: str) -> EventType:
        """
        Classify event type based on message content
        
        Args:
            message: Log message
            
        Returns:
            EventType classification
        """
        message_lower = message.lower()
        
        if 'request for connection params' in message_lower:
            return EventType.CONNECTION_PARAMS
        elif 'connection url created' in message_lower:
            return EventType.CONNECTION_URL
        elif 'success websocket connection' in message_lower or 'success get' in message_lower:
            if 'websocket' in message_lower:
                return EventType.WEBSOCKET_SUCCESS
            elif 'instruments' in message_lower:
                return EventType.INSTRUMENTS_SUCCESS
        elif 'request get list of instruments' in message_lower:
            return EventType.INSTRUMENTS_REQUEST
        elif 'request get list of orders' in message_lower:
            return EventType.ORDERS_REQUEST
        elif 'request order events subscribe' in message_lower:
            return EventType.ORDER_EVENTS_SUBSCRIBE
        elif 'request user events subscribe' in message_lower:
            return EventType.USER_EVENTS_SUBSCRIBE
        elif 'request account balance' in message_lower:
            return EventType.BALANCE_REQUEST
        elif 'request get account info' in message_lower:
            return EventType.ACCOUNT_INFO_REQUEST
        else:
            return EventType.UNKNOWN
    
    def parse_text(self, text: str) -> List[LogEntry]:
        """
        Parse multi-line log text
        
        Args:
            text: Multi-line log text
            
        Returns:
            List of parsed log entries
        """
        self.entries = []
        for line in text.split('\n'):
            entry = self.parse_line(line)
            if entry:
                self.entries.append(entry)
        return self.entries
    
    def parse_file(self, filepath: str) -> List[LogEntry]:
        """
        Parse log file
        
        Args:
            filepath: Path to log file
            
        Returns:
            List of parsed log entries
        """
        with open(filepath, 'r', encoding='utf-8') as f:
            return self.parse_text(f.read())
    
    def get_summary(self, entries: Optional[List[LogEntry]] = None) -> Dict:
        """
        Get summary statistics of parsed logs
        
        Args:
            entries: Optional list of entries to summarize. If None, uses self.entries
        
        Returns:
            Dictionary with summary statistics
        """
        entries_to_summarize = entries if entries is not None else self.entries
        
        if not entries_to_summarize:
            return {}
        
        account_ids = set(e.account_id for e in entries_to_summarize)
        event_counts = {}
        for entry in entries_to_summarize:
            event_type = entry.event_type.value
            event_counts[event_type] = event_counts.get(event_type, 0) + 1
        
        servers = set(e.server for e in entries_to_summarize if e.server)
        
        return {
            'total_entries': len(entries_to_summarize),
            'account_ids': list(account_ids),
            'event_counts': event_counts,
            'servers': list(servers),
            'time_range': {
                'start': min(e.timestamp for e in entries_to_summarize).isoformat(),
                'end': max(e.timestamp for e in entries_to_summarize).isoformat()
            } if entries_to_summarize else None
        }
    
    def filter_by_account(self, account_id: str) -> List[LogEntry]:
        """Filter entries by account ID"""
        return [e for e in self.entries if e.account_id == account_id]
    
    def filter_by_event_type(self, event_type: EventType) -> List[LogEntry]:
        """Filter entries by event type"""
        return [e for e in self.entries if e.event_type == event_type]
    
    def filter_by_time_range(self, start: datetime, end: datetime) -> List[LogEntry]:
        """Filter entries by time range"""
        return [e for e in self.entries if start <= e.timestamp <= end]


def main():
    """Example usage"""
    sample_log = """Trading Log from my phone
个 25 December 2025 GMT
个 2025.12.25 03:58:12.224 Debug '411534497": request for connection params
2025.12.25 03:58:12.227 Debug '411534497': connection url created (server: wss://rtapi-sg.domain_placeholder/rtapi/mt5/real8)
2025.12.25 03:58:12.234 Service '411534497": request get list of instruments
2025.12.25 03:58:12.244 Service '411534497': request order events subscribe
2025.12.25 03:58:12.682 Service '411534497": Success get list of instruments
2025.12.25 03:58:12.713 Debug '411534497": RetailQuotes: success websocket connection - Exness-MT5Real8
2025.12.25 03:58:12.742 Debug '411534497: RetailEvents: success websocket connection - Exness-MT5Real8
2025.12.25 03:58:12.744 Service '411534497": request get list of orders
2025.12.25 03:58:12.744 Service '411534497': request user events subscribe
2025.12.25 03:58:12.746 Service 411534497': request account balance
2025.12.25 03:58:12.746 Service 411534497: request get account info
"""
    
    parser = MT5LogParser()
    entries = parser.parse_text(sample_log)
    
    print(f"Parsed {len(entries)} log entries")
    print("\nSummary:")
    import json
    print(json.dumps(parser.get_summary(), indent=2))
    
    print("\nEntries:")
    for entry in entries:
        print(f"{entry.timestamp} [{entry.level.value}] {entry.account_id}: {entry.event_type.value}")


if __name__ == "__main__":
    main()

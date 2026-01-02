"""
Trade Signal Manager
Manages trade signals, validation, and queue operations
"""
from dataclasses import dataclass, asdict
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum
import json


class TradeAction(Enum):
    """Trade action types"""
    BUY = "BUY"
    SELL = "SELL"
    CLOSE = "CLOSE"
    MODIFY = "MODIFY"


@dataclass
class TradeSignal:
    """Trade signal data structure"""
    symbol: str
    action: str  # BUY, SELL, CLOSE, MODIFY
    broker: str
    lot_size: float
    stop_loss: Optional[float] = None
    take_profit: Optional[float] = None
    comment: str = ""
    timestamp: Optional[datetime] = None
    signal_id: Optional[str] = None
    
    def __post_init__(self):
        """Initialize timestamp and signal_id if not provided"""
        if self.timestamp is None:
            self.timestamp = datetime.now()
        if self.signal_id is None:
            self.signal_id = f"{self.symbol}_{self.action}_{int(self.timestamp.timestamp())}"
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert signal to dictionary"""
        data = asdict(self)
        if isinstance(data['timestamp'], datetime):
            data['timestamp'] = data['timestamp'].isoformat()
        return data
    
    def to_json(self) -> str:
        """Convert signal to JSON string"""
        return json.dumps(self.to_dict())
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TradeSignal':
        """Create signal from dictionary"""
        if 'timestamp' in data and isinstance(data['timestamp'], str):
            data['timestamp'] = datetime.fromisoformat(data['timestamp'])
        return cls(**data)
    
    @classmethod
    def from_json(cls, json_str: str) -> 'TradeSignal':
        """Create signal from JSON string"""
        data = json.loads(json_str)
        return cls.from_dict(data)
    
    def validate(self) -> tuple[bool, Optional[str]]:
        """
        Validate signal parameters
        
        Returns:
            (is_valid, error_message)
        """
        # Validate symbol
        if not self.symbol or len(self.symbol) < 3:
            return False, "Invalid symbol"
        
        # Validate action
        try:
            TradeAction(self.action.upper())
        except ValueError:
            return False, f"Invalid action: {self.action}"
        
        # Validate lot size
        if self.lot_size <= 0:
            return False, "Lot size must be positive"
        
        # Validate stop loss and take profit if provided
        if self.stop_loss is not None and self.stop_loss <= 0:
            return False, "Stop loss must be positive"
        
        if self.take_profit is not None and self.take_profit <= 0:
            return False, "Take profit must be positive"
        
        # Validate stop loss < take profit for BUY
        if self.action.upper() == "BUY" and self.stop_loss and self.take_profit:
            if self.stop_loss >= self.take_profit:
                return False, "Stop loss must be less than take profit for BUY"
        
        # Validate stop loss > take profit for SELL
        if self.action.upper() == "SELL" and self.stop_loss and self.take_profit:
            if self.stop_loss <= self.take_profit:
                return False, "Stop loss must be greater than take profit for SELL"
        
        return True, None


class SignalManager:
    """Manages trade signal queue and history"""
    
    def __init__(self, max_queue_size: int = 1000, max_history: int = 10000):
        """
        Initialize SignalManager
        
        Args:
            max_queue_size: Maximum number of signals in queue
            max_history: Maximum number of signals in history
        """
        self.queue: List[TradeSignal] = []
        self.history: List[TradeSignal] = []
        self.max_queue_size = max_queue_size
        self.max_history = max_history
        self.processed_signals: set = set()  # For deduplication
    
    def add_signal(self, signal: TradeSignal) -> tuple[bool, Optional[str]]:
        """
        Add signal to queue
        
        Args:
            signal: Trade signal to add
            
        Returns:
            (success, error_message)
        """
        # Validate signal
        is_valid, error = signal.validate()
        if not is_valid:
            return False, error
        
        # Check for duplicates
        if signal.signal_id in self.processed_signals:
            return False, "Duplicate signal"
        
        # Check queue size
        if len(self.queue) >= self.max_queue_size:
            return False, "Queue is full"
        
        # Add to queue
        self.queue.append(signal)
        self.processed_signals.add(signal.signal_id)
        
        return True, None
    
    def get_signals(self, count: Optional[int] = None) -> List[TradeSignal]:
        """
        Get signals from queue
        
        Args:
            count: Number of signals to retrieve (None = all)
            
        Returns:
            List of trade signals
        """
        if count is None:
            signals = self.queue.copy()
            self.queue.clear()
        else:
            signals = self.queue[:count]
            self.queue = self.queue[count:]
        
        # Add to history
        self.history.extend(signals)
        
        # Trim history if needed
        if len(self.history) > self.max_history:
            self.history = self.history[-self.max_history:]
        
        return signals
    
    def get_queue_size(self) -> int:
        """Get current queue size"""
        return len(self.queue)
    
    def clear_queue(self):
        """Clear signal queue"""
        self.queue.clear()
    
    def get_history(self, limit: Optional[int] = None) -> List[TradeSignal]:
        """
        Get signal history
        
        Args:
            limit: Maximum number of signals to return
            
        Returns:
            List of historical signals
        """
        if limit is None:
            return self.history.copy()
        return self.history[-limit:] if limit > 0 else []
    
    def get_signal_by_id(self, signal_id: str) -> Optional[TradeSignal]:
        """
        Get signal by ID from history
        
        Args:
            signal_id: Signal ID to search for
            
        Returns:
            Trade signal or None
        """
        for signal in reversed(self.history):
            if signal.signal_id == signal_id:
                return signal
        return None


"""
Base Broker Abstract Class
Defines interface for all broker implementations
"""
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from dataclasses import dataclass


@dataclass
class BrokerConfig:
    """Broker configuration"""
    name: str
    api_url: str
    account_id: str
    api_key: Optional[str] = None
    api_secret: Optional[str] = None
    enabled: bool = True
    rate_limit: Optional[Dict[str, int]] = None


@dataclass
class OrderResult:
    """Order execution result"""
    success: bool
    order_id: Optional[str] = None
    message: Optional[str] = None
    error_code: Optional[str] = None


@dataclass
class Position:
    """Open position information"""
    symbol: str
    volume: float
    type: str  # BUY or SELL
    open_price: float
    current_price: float
    profit: float
    swap: float
    commission: float
    position_id: Optional[str] = None


@dataclass
class AccountInfo:
    """Account information"""
    balance: float
    equity: float
    margin: float
    free_margin: float
    margin_level: float
    currency: str = "USD"


class BaseBroker(ABC):
    """Abstract base class for broker implementations"""
    
    def __init__(self, config: BrokerConfig):
        """
        Initialize broker
        
        Args:
            config: Broker configuration
        """
        self.config = config
        self.name = config.name
        self.enabled = config.enabled
    
    @abstractmethod
    def place_order(self, symbol: str, action: str, lot_size: float,
                   stop_loss: Optional[float] = None,
                   take_profit: Optional[float] = None,
                   comment: str = "") -> OrderResult:
        """
        Place order on broker
        
        Args:
            symbol: Trading symbol (e.g., 'EURUSD')
            action: Order action ('BUY' or 'SELL')
            lot_size: Position size in lots
            stop_loss: Stop loss price (optional)
            take_profit: Take profit price (optional)
            comment: Order comment
            
        Returns:
            OrderResult with execution details
        """
        pass
    
    @abstractmethod
    def get_account_info(self) -> AccountInfo:
        """
        Get account information
        
        Returns:
            AccountInfo with account details
        """
        pass
    
    @abstractmethod
    def get_positions(self, symbol: Optional[str] = None) -> List[Position]:
        """
        Get open positions
        
        Args:
            symbol: Filter by symbol (None = all positions)
            
        Returns:
            List of open positions
        """
        pass
    
    @abstractmethod
    def close_position(self, position_id: str) -> OrderResult:
        """
        Close a position
        
        Args:
            position_id: Position ID to close
            
        Returns:
            OrderResult with execution details
        """
        pass
    
    @abstractmethod
    def modify_position(self, position_id: str, stop_loss: Optional[float] = None,
                       take_profit: Optional[float] = None) -> OrderResult:
        """
        Modify position (stop loss/take profit)
        
        Args:
            position_id: Position ID to modify
            stop_loss: New stop loss price
            take_profit: New take profit price
            
        Returns:
            OrderResult with execution details
        """
        pass
    
    def is_enabled(self) -> bool:
        """Check if broker is enabled"""
        return self.enabled
    
    def get_name(self) -> str:
        """Get broker name"""
        return self.name
    
    def validate_symbol(self, symbol: str) -> bool:
        """
        Validate trading symbol
        
        Args:
            symbol: Symbol to validate
            
        Returns:
            True if valid
        """
        # Basic validation - override in subclasses for broker-specific rules
        return symbol and len(symbol) >= 3
    
    def calculate_lot_size(self, risk_percent: float, stop_loss_pips: float,
                         account_balance: float) -> float:
        """
        Calculate lot size based on risk percentage
        
        Args:
            risk_percent: Risk percentage (e.g., 1.0 for 1%)
            stop_loss_pips: Stop loss in pips
            account_balance: Account balance
            
        Returns:
            Lot size
        """
        # Basic calculation - override in subclasses for broker-specific rules
        risk_amount = account_balance * (risk_percent / 100.0)
        # Simplified calculation (should use pip value for symbol)
        lot_size = risk_amount / (stop_loss_pips * 10)  # Approximate
        return round(lot_size, 2)


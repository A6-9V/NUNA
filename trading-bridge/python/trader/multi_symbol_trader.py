"""
Multi-Symbol Trading Manager
Manages trading across multiple symbols and brokers
"""
import json
from typing import Dict, List, Set, Optional
from pathlib import Path
from datetime import datetime

# NOTE:
# This project is commonly executed by adding `trading-bridge/python` to `sys.path`
# (see `services/background_service.py`). In that mode, `bridge`, `brokers`, and
# `trader` are treated as top-level packages, so using `..bridge` style relative
# imports will fail with "attempted relative import beyond top-level package".
from bridge.signal_manager import TradeSignal
from brokers.base_broker import BaseBroker, OrderResult
from brokers.broker_factory import BrokerFactory


class MultiSymbolTrader:
    """Manages trading across multiple symbols and brokers"""
    
    def __init__(self, bridge=None, broker_manager=None):
        """
        Initialize MultiSymbolTrader
        
        Args:
            bridge: MQL5Bridge instance (optional)
            broker_manager: Dictionary of broker_name -> broker_instance (optional)
        """
        self.bridge = bridge
        self.brokers: Dict[str, BaseBroker] = broker_manager or {}
        self.symbols: Set[str] = set()
        self.symbol_configs: Dict[str, Dict] = {}
        self.active_positions: Dict[str, Dict] = {}
        
        # Load symbol configurations
        self._load_symbol_configs()
        
        # Load brokers if not provided
        if not self.brokers:
            self.brokers = BrokerFactory.create_all_brokers()
    
    def _load_symbol_configs(self):
        """Load symbol configurations from file"""
        config_file = Path(__file__).parent.parent.parent / "config" / "symbols.json"
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    configs = json.load(f)
                    symbols = configs.get('symbols', [])
                    
                    for symbol_config in symbols:
                        symbol = symbol_config.get('symbol', '')
                        broker = symbol_config.get('broker', '')
                        if symbol and broker:
                            self.add_symbol(symbol, broker, symbol_config)
            except Exception as e:
                print(f"Error loading symbol configs: {e}")
    
    def add_symbol(self, symbol: str, broker: str, config: Optional[Dict] = None):
        """
        Add symbol to trade
        
        Args:
            symbol: Trading symbol (e.g., 'EURUSD')
            broker: Broker name (e.g., 'EXNESS')
            config: Symbol-specific configuration
        """
        symbol_key = f"{symbol}@{broker}"
        self.symbols.add(symbol_key)
        
        if config is None:
            config = {}
        
        self.symbol_configs[symbol_key] = {
            'symbol': symbol,
            'broker': broker,
            'enabled': config.get('enabled', True),
            'risk_percent': config.get('risk_percent', 1.0),
            'max_positions': config.get('max_positions', 1),
            'min_lot_size': config.get('min_lot_size', 0.01),
            'max_lot_size': config.get('max_lot_size', 10.0)
        }
        
        print(f"[SYMBOL] Added: {symbol} @ {broker}")
    
    def execute_trade(self, symbol: str, broker: str, action: str,
                     lot_size: float, stop_loss: Optional[float] = None,
                     take_profit: Optional[float] = None,
                     comment: str = "") -> OrderResult:
        """
        Execute trade on symbol via broker
        
        Args:
            symbol: Trading symbol
            broker: Broker name
            action: Trade action (BUY/SELL)
            lot_size: Position size in lots
            stop_loss: Stop loss price
            take_profit: Take profit price
            comment: Trade comment
            
        Returns:
            OrderResult
        """
        symbol_key = f"{symbol}@{broker}"
        
        # Check if symbol is configured
        if symbol_key not in self.symbols:
            return OrderResult(
                success=False,
                message=f"Symbol {symbol} not configured for broker {broker}",
                error_code="SYMBOL_NOT_CONFIGURED"
            )
        
        # Check if broker exists
        if broker not in self.brokers:
            return OrderResult(
                success=False,
                message=f"Broker {broker} not available",
                error_code="BROKER_NOT_FOUND"
            )
        
        broker_instance = self.brokers[broker]
        
        # Check symbol configuration
        config = self.symbol_configs.get(symbol_key, {})
        if not config.get('enabled', True):
            return OrderResult(
                success=False,
                message=f"Symbol {symbol} is disabled",
                error_code="SYMBOL_DISABLED"
            )
        
        # Validate lot size
        min_lot = config.get('min_lot_size', 0.01)
        max_lot = config.get('max_lot_size', 10.0)
        if lot_size < min_lot or lot_size > max_lot:
            return OrderResult(
                success=False,
                message=f"Lot size {lot_size} out of range [{min_lot}, {max_lot}]",
                error_code="INVALID_LOT_SIZE"
            )
        
        # Check position limits
        max_positions = config.get('max_positions', 1)
        current_positions = self._count_positions(symbol_key)
        if current_positions >= max_positions:
            return OrderResult(
                success=False,
                message=f"Maximum positions ({max_positions}) reached for {symbol}",
                error_code="MAX_POSITIONS_REACHED"
            )
        
        # Option 1: Direct API call (if broker supports it)
        if broker_instance:
            result = broker_instance.place_order(
                symbol=symbol,
                action=action,
                lot_size=lot_size,
                stop_loss=stop_loss,
                take_profit=take_profit,
                comment=comment
            )
            
            if result.success:
                # Track position
                self._add_position(symbol_key, result.order_id, action, lot_size)
            
            return result
        
        # Option 2: Via MQL5 bridge
        if self.bridge:
            signal = TradeSignal(
                symbol=symbol,
                action=action,
                broker=broker,
                lot_size=lot_size,
                stop_loss=stop_loss,
                take_profit=take_profit,
                comment=comment
            )
            
            success, error = self.bridge.send_signal(signal)
            if success:
                return OrderResult(
                    success=True,
                    message="Signal sent to MQL5 bridge",
                    order_id=signal.signal_id
                )
            else:
                return OrderResult(
                    success=False,
                    message=error or "Failed to send signal",
                    error_code="BRIDGE_ERROR"
                )
        
        return OrderResult(
            success=False,
            message="No broker or bridge available",
            error_code="NO_EXECUTION_METHOD"
        )
    
    def _count_positions(self, symbol_key: str) -> int:
        """Count current positions for symbol"""
        count = 0
        for pos_key, pos_data in self.active_positions.items():
            if pos_key.startswith(symbol_key):
                count += 1
        return count
    
    def _add_position(self, symbol_key: str, order_id: str, action: str, lot_size: float):
        """Add position to tracking"""
        position_key = f"{symbol_key}_{order_id}"
        self.active_positions[position_key] = {
            'symbol_key': symbol_key,
            'order_id': order_id,
            'action': action,
            'lot_size': lot_size,
            'timestamp': datetime.now().isoformat()
        }
    
    def monitor_positions(self) -> Dict[str, List]:
        """
        Monitor all positions across brokers
        
        Returns:
            Dictionary of broker_name -> list of positions
        """
        all_positions = {}
        
        for broker_name, broker in self.brokers.items():
            try:
                positions = broker.get_positions()
                all_positions[broker_name] = positions
                
                # Update active positions tracking
                for pos in positions:
                    symbol_key = f"{pos.symbol}@{broker_name}"
                    if pos.position_id:
                        position_key = f"{symbol_key}_{pos.position_id}"
                        self.active_positions[position_key] = {
                            'symbol_key': symbol_key,
                            'position_id': pos.position_id,
                            'volume': pos.volume,
                            'type': pos.type,
                            'profit': pos.profit,
                            'timestamp': datetime.now().isoformat()
                        }
            except Exception as e:
                print(f"[ERROR] {broker_name}: {e}")
                all_positions[broker_name] = []
        
        return all_positions
    
    def get_symbol_config(self, symbol: str, broker: str) -> Optional[Dict]:
        """
        Get symbol configuration
        
        Args:
            symbol: Trading symbol
            broker: Broker name
            
        Returns:
            Symbol configuration or None
        """
        symbol_key = f"{symbol}@{broker}"
        return self.symbol_configs.get(symbol_key)
    
    def get_all_symbols(self) -> List[Dict]:
        """
        Get all configured symbols
        
        Returns:
            List of symbol configurations
        """
        return list(self.symbol_configs.values())
    
    def enable_symbol(self, symbol: str, broker: str):
        """Enable trading for symbol"""
        symbol_key = f"{symbol}@{broker}"
        if symbol_key in self.symbol_configs:
            self.symbol_configs[symbol_key]['enabled'] = True
    
    def disable_symbol(self, symbol: str, broker: str):
        """Disable trading for symbol"""
        symbol_key = f"{symbol}@{broker}"
        if symbol_key in self.symbol_configs:
            self.symbol_configs[symbol_key]['enabled'] = False


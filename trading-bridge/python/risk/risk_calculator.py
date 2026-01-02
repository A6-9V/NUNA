"""
Risk Management and Position Sizing Calculator
Automatically calculates TP, SL, lot size, and pending orders
"""

import json
import logging
from typing import Dict, Optional, Tuple
from dataclasses import dataclass


@dataclass
class PositionSize:
    """Position sizing result"""
    lot_size: float
    risk_amount: float
    stop_loss_pips: float
    take_profit_pips: float
    position_value: float


class RiskCalculator:
    """
    Automatic risk calculation for trading positions
    Calculates lot size, TP, SL, and manages pending orders
    """
    
    def __init__(self, config_path: str = None):
        self.logger = logging.getLogger(__name__)
        self.config = self._load_config(config_path)
        
        # Standard pip values for different symbol types
        self.pip_values = {
            'forex_standard': 0.0001,  # EURUSD, GBPUSD, etc.
            'forex_jpy': 0.01,         # USDJPY, EURJPY, etc.
            'gold': 0.01,              # XAUUSD
            'crypto': 1.0,             # BTCUSD, ETHUSD
            'index': 1.0               # US30, NAS100, etc.
        }
    
    def _load_config(self, config_path: str) -> Dict:
        """Load risk management configuration"""
        if config_path:
            try:
                with open(config_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                self.logger.error(f"Failed to load config: {e}")
        
        # Default configuration
        return {
            "max_risk_per_trade_percent": 1.0,
            "max_daily_loss_percent": 5.0,
            "max_open_positions": 3,
            "auto_calculate_lot_size": True,
            "use_trailing_stop": True,
            "trailing_stop_points": 50,
            "break_even_points": 30
        }
    
    def get_symbol_type(self, symbol: str) -> str:
        """
        Determine symbol type for pip calculation
        
        Args:
            symbol: Trading symbol
            
        Returns:
            Symbol type string
        """
        symbol = symbol.upper()
        
        if 'JPY' in symbol:
            return 'forex_jpy'
        elif any(pair in symbol for pair in ['EUR', 'GBP', 'AUD', 'NZD', 'USD', 'CAD', 'CHF']):
            return 'forex_standard'
        elif 'XAU' in symbol or 'GOLD' in symbol:
            return 'gold'
        elif any(crypto in symbol for crypto in ['BTC', 'ETH', 'LTC', 'XRP']):
            return 'crypto'
        elif any(index in symbol for index in ['US30', 'NAS100', 'SPX500', 'GER40', 'UK100']):
            return 'index'
        else:
            return 'forex_standard'  # Default
    
    def calculate_lot_size(self,
                          account_balance: float,
                          risk_percent: float,
                          entry_price: float,
                          stop_loss_price: float,
                          symbol: str,
                          min_lot: float = 0.01,
                          max_lot: float = 10.0) -> float:
        """
        Calculate optimal lot size based on risk parameters
        
        Args:
            account_balance: Current account balance
            risk_percent: Risk percentage per trade (e.g., 1.0 for 1%)
            entry_price: Planned entry price
            stop_loss_price: Stop loss price
            symbol: Trading symbol
            min_lot: Minimum lot size
            max_lot: Maximum lot size
            
        Returns:
            Calculated lot size
        """
        # Calculate risk amount in account currency
        risk_amount = account_balance * (risk_percent / 100)
        
        # Get pip value
        symbol_type = self.get_symbol_type(symbol)
        pip_size = self.pip_values.get(symbol_type, 0.0001)
        
        # Calculate stop loss in pips
        sl_pips = abs(entry_price - stop_loss_price) / pip_size
        
        if sl_pips == 0:
            self.logger.warning(f"Stop loss is 0 pips for {symbol}")
            return min_lot
        
        # Calculate pip value in account currency (assuming USD account)
        # For standard lot (100,000 units), 1 pip = $10 for most pairs
        # Adjust for different symbol types
        if symbol_type == 'forex_standard':
            pip_value_per_lot = 10.0
        elif symbol_type == 'forex_jpy':
            pip_value_per_lot = 10.0
        elif symbol_type == 'gold':
            pip_value_per_lot = 1.0
        elif symbol_type == 'crypto':
            pip_value_per_lot = 0.01
        elif symbol_type == 'index':
            pip_value_per_lot = 1.0
        else:
            pip_value_per_lot = 10.0
        
        # Calculate lot size
        # risk_amount = lot_size * sl_pips * pip_value_per_lot
        # lot_size = risk_amount / (sl_pips * pip_value_per_lot)
        lot_size = risk_amount / (sl_pips * pip_value_per_lot)
        
        # Round to 2 decimal places and constrain to min/max
        lot_size = round(lot_size, 2)
        lot_size = max(min_lot, min(lot_size, max_lot))
        
        self.logger.info(f"Calculated lot size for {symbol}: {lot_size} "
                        f"(Risk: ${risk_amount:.2f}, SL: {sl_pips:.1f} pips)")
        
        return lot_size
    
    def calculate_take_profit(self,
                            entry_price: float,
                            stop_loss_price: float,
                            direction: str,
                            tp_ratio: float = 2.0) -> float:
        """
        Calculate take profit based on risk-reward ratio
        
        Args:
            entry_price: Entry price
            stop_loss_price: Stop loss price
            direction: 'BUY' or 'SELL'
            tp_ratio: Risk-reward ratio (default 2.0 = 1:2)
            
        Returns:
            Take profit price
        """
        # Calculate stop loss distance
        sl_distance = abs(entry_price - stop_loss_price)
        
        # Calculate take profit distance
        tp_distance = sl_distance * tp_ratio
        
        # Calculate take profit price
        if direction.upper() == 'BUY':
            tp_price = entry_price + tp_distance
        else:  # SELL
            tp_price = entry_price - tp_distance
        
        return round(tp_price, 5)
    
    def calculate_dynamic_stop_loss(self,
                                   candles: list,
                                   direction: str,
                                   atr_multiplier: float = 1.5,
                                   atr_period: int = 14) -> float:
        """
        Calculate dynamic stop loss using ATR (Average True Range)
        
        Args:
            candles: List of OHLCV candles
            direction: 'BUY' or 'SELL'
            atr_multiplier: Multiplier for ATR (default 1.5)
            atr_period: ATR calculation period (default 14)
            
        Returns:
            Stop loss price
        """
        if len(candles) < atr_period + 1:
            # Fallback to swing high/low
            if direction.upper() == 'BUY':
                return min(c['low'] for c in candles[-10:])
            else:
                return max(c['high'] for c in candles[-10:])
        
        # Calculate ATR
        atr = self._calculate_atr(candles, atr_period)
        current_price = candles[-1]['close']
        
        # Calculate stop loss
        if direction.upper() == 'BUY':
            sl_price = current_price - (atr * atr_multiplier)
        else:  # SELL
            sl_price = current_price + (atr * atr_multiplier)
        
        return round(sl_price, 5)
    
    def calculate_dynamic_take_profit(self,
                                     candles: list,
                                     entry_price: float,
                                     stop_loss_price: float,
                                     direction: str,
                                     min_ratio: float = 2.0) -> float:
        """
        Calculate dynamic take profit using recent price action
        
        Args:
            candles: List of OHLCV candles
            entry_price: Entry price
            stop_loss_price: Stop loss price
            direction: 'BUY' or 'SELL'
            min_ratio: Minimum risk-reward ratio
            
        Returns:
            Take profit price
        """
        # Get recent swing high/low
        recent_candles = candles[-50:] if len(candles) >= 50 else candles
        
        if direction.upper() == 'BUY':
            # Find nearest resistance
            swing_high = max(c['high'] for c in recent_candles)
            
            # Use swing high if it provides better than min_ratio
            sl_distance = abs(entry_price - stop_loss_price)
            potential_tp = swing_high
            tp_distance = abs(potential_tp - entry_price)
            
            if tp_distance / sl_distance >= min_ratio:
                return round(potential_tp, 5)
            else:
                # Fallback to fixed ratio
                return self.calculate_take_profit(entry_price, stop_loss_price, direction, min_ratio)
        
        else:  # SELL
            # Find nearest support
            swing_low = min(c['low'] for c in recent_candles)
            
            # Use swing low if it provides better than min_ratio
            sl_distance = abs(entry_price - stop_loss_price)
            potential_tp = swing_low
            tp_distance = abs(entry_price - potential_tp)
            
            if tp_distance / sl_distance >= min_ratio:
                return round(potential_tp, 5)
            else:
                # Fallback to fixed ratio
                return self.calculate_take_profit(entry_price, stop_loss_price, direction, min_ratio)
    
    def calculate_pending_order(self,
                               entry_price: float,
                               direction: str,
                               symbol: str,
                               distance_points: int = 10) -> Dict:
        """
        Calculate pending order parameters
        
        Args:
            entry_price: Desired entry price
            direction: 'BUY' or 'SELL'
            symbol: Trading symbol
            distance_points: Distance in points from current price
            
        Returns:
            Pending order parameters
        """
        # Get symbol-specific pip size
        symbol_type = self.get_symbol_type(symbol)
        pip_size = self.pip_values.get(symbol_type, 0.0001)
        
        if direction.upper() == 'BUY':
            # Buy Stop (enter on breakout above)
            order_type = 'BUY_STOP'
            order_price = entry_price + (distance_points * pip_size)
        else:  # SELL
            # Sell Stop (enter on breakout below)
            order_type = 'SELL_STOP'
            order_price = entry_price - (distance_points * pip_size)
        
        return {
            'order_type': order_type,
            'order_price': round(order_price, 5),
            'distance_points': distance_points,
            'pip_size': pip_size
        }
    
    def calculate_position_sizing(self,
                                 symbol: str,
                                 account_balance: float,
                                 risk_percent: float,
                                 entry_price: float,
                                 stop_loss_price: float,
                                 take_profit_price: float,
                                 min_lot: float = 0.01,
                                 max_lot: float = 10.0) -> PositionSize:
        """
        Complete position sizing calculation
        
        Args:
            symbol: Trading symbol
            account_balance: Current account balance
            risk_percent: Risk percentage per trade
            entry_price: Entry price
            stop_loss_price: Stop loss price
            take_profit_price: Take profit price
            min_lot: Minimum lot size
            max_lot: Maximum lot size
            
        Returns:
            PositionSize object with all calculations
        """
        # Calculate lot size
        lot_size = self.calculate_lot_size(
            account_balance, risk_percent, entry_price, 
            stop_loss_price, symbol, min_lot, max_lot
        )
        
        # Calculate pip values
        symbol_type = self.get_symbol_type(symbol)
        pip_size = self.pip_values.get(symbol_type, 0.0001)
        
        # Calculate pips
        sl_pips = abs(entry_price - stop_loss_price) / pip_size
        tp_pips = abs(take_profit_price - entry_price) / pip_size
        
        # Calculate risk amount
        risk_amount = account_balance * (risk_percent / 100)
        
        # Calculate position value
        position_value = lot_size * 100000  # Standard lot size
        
        return PositionSize(
            lot_size=lot_size,
            risk_amount=risk_amount,
            stop_loss_pips=sl_pips,
            take_profit_pips=tp_pips,
            position_value=position_value
        )
    
    def validate_risk_limits(self,
                           account_balance: float,
                           current_positions: int,
                           daily_loss: float,
                           proposed_risk: float) -> Tuple[bool, str]:
        """
        Validate if trade respects risk limits
        
        Args:
            account_balance: Current account balance
            current_positions: Number of currently open positions
            daily_loss: Daily loss so far (negative value)
            proposed_risk: Risk amount for proposed trade
            
        Returns:
            Tuple of (is_valid, reason)
        """
        # Check max positions
        max_positions = self.config.get('max_open_positions', 3)
        if current_positions >= max_positions:
            return False, f"Maximum positions reached ({max_positions})"
        
        # Check daily loss limit
        max_daily_loss_percent = self.config.get('max_daily_loss_percent', 5.0)
        max_daily_loss = account_balance * (max_daily_loss_percent / 100)
        
        if abs(daily_loss) >= max_daily_loss:
            return False, f"Daily loss limit reached (${abs(daily_loss):.2f})"
        
        # Check if proposed trade would exceed daily loss limit
        potential_loss = abs(daily_loss) + proposed_risk
        if potential_loss > max_daily_loss:
            return False, f"Trade would exceed daily loss limit"
        
        return True, "Risk limits validated"
    
    def _calculate_atr(self, candles: list, period: int = 14) -> float:
        """
        Calculate Average True Range
        
        Args:
            candles: List of OHLCV candles
            period: ATR period
            
        Returns:
            ATR value
        """
        if len(candles) < period + 1:
            return 0
        
        true_ranges = []
        
        for i in range(1, len(candles)):
            high = candles[i]['high']
            low = candles[i]['low']
            prev_close = candles[i-1]['close']
            
            tr = max(
                high - low,
                abs(high - prev_close),
                abs(low - prev_close)
            )
            true_ranges.append(tr)
        
        # Calculate average of last 'period' true ranges
        atr = sum(true_ranges[-period:]) / period
        
        return atr

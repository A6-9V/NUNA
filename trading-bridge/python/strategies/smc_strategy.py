"""
Smart Money Concepts (SMC) Strategy Implementation
Includes: Order Blocks, Fair Value Gaps, Liquidity Zones, Breaker Blocks
Combined with: Trend Breakout and Multi-Timeframe Indicators
"""

import json
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import logging


class SMCStrategy:
    """
    Smart Money Concepts strategy implementation
    """
    
    def __init__(self, config_path: str = None):
        self.logger = logging.getLogger(__name__)
        self.config = self._load_config(config_path)
        
    def _load_config(self, config_path: str) -> Dict:
        """Load strategy configuration"""
        if config_path:
            try:
                with open(config_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                self.logger.error(f"Failed to load config: {e}")
        
        # Default configuration
        return {
            "smc": {
                "order_blocks": True,
                "fair_value_gaps": True,
                "liquidity_zones": True,
                "breaker_blocks": True
            },
            "trend_breakout": {
                "structure_break": True,
                "choch": True,  # Change of Character
                "bos": True     # Break of Structure
            },
            "indicators": {
                "primary_timeframe": "H1",
                "secondary_timeframe": "M15",
                "entry_timeframe": "M5",
                "ema_fast": 9,
                "ema_slow": 21,
                "rsi_period": 14,
                "rsi_overbought": 70,
                "rsi_oversold": 30
            }
        }
    
    def detect_order_blocks(self, candles: List[Dict], timeframe: str = "H1") -> List[Dict]:
        """
        Detect order blocks (OB) - areas where smart money placed orders
        
        An order block is typically:
        - A candle that precedes a strong move
        - High volume candle
        - Often engulfs previous candles
        
        Args:
            candles: List of OHLCV candles
            timeframe: Timeframe for analysis
            
        Returns:
            List of order block zones
        """
        order_blocks = []
        
        if len(candles) < 5:
            return order_blocks
        
        for i in range(2, len(candles) - 2):
            current = candles[i]
            prev = candles[i-1]
            next_candle = candles[i+1]
            
            # Bullish Order Block
            # Look for a down candle followed by strong up move
            if (current['close'] < current['open'] and  # Down candle
                next_candle['close'] > next_candle['open'] and  # Up candle
                next_candle['close'] - next_candle['open'] > current['open'] - current['close'] * 2):
                
                order_blocks.append({
                    'type': 'bullish',
                    'timeframe': timeframe,
                    'high': current['high'],
                    'low': current['low'],
                    'timestamp': current['timestamp'],
                    'strength': self._calculate_ob_strength(candles, i)
                })
            
            # Bearish Order Block
            # Look for an up candle followed by strong down move
            elif (current['close'] > current['open'] and  # Up candle
                  next_candle['close'] < next_candle['open'] and  # Down candle
                  next_candle['open'] - next_candle['close'] > current['close'] - current['open'] * 2):
                
                order_blocks.append({
                    'type': 'bearish',
                    'timeframe': timeframe,
                    'high': current['high'],
                    'low': current['low'],
                    'timestamp': current['timestamp'],
                    'strength': self._calculate_ob_strength(candles, i)
                })
        
        return order_blocks
    
    def detect_fair_value_gaps(self, candles: List[Dict]) -> List[Dict]:
        """
        Detect Fair Value Gaps (FVG) - price imbalances
        
        FVG occurs when:
        - There's a gap between candle[i-1].low and candle[i+1].high (bullish)
        - There's a gap between candle[i-1].high and candle[i+1].low (bearish)
        
        Args:
            candles: List of OHLCV candles
            
        Returns:
            List of fair value gaps
        """
        fvgs = []
        
        if len(candles) < 3:
            return fvgs
        
        for i in range(1, len(candles) - 1):
            prev = candles[i-1]
            current = candles[i]
            next_candle = candles[i+1]
            
            # Bullish FVG
            if prev['high'] < next_candle['low']:
                gap_size = next_candle['low'] - prev['high']
                fvgs.append({
                    'type': 'bullish',
                    'high': next_candle['low'],
                    'low': prev['high'],
                    'gap_size': gap_size,
                    'timestamp': current['timestamp'],
                    'filled': False
                })
            
            # Bearish FVG
            elif prev['low'] > next_candle['high']:
                gap_size = prev['low'] - next_candle['high']
                fvgs.append({
                    'type': 'bearish',
                    'high': prev['low'],
                    'low': next_candle['high'],
                    'gap_size': gap_size,
                    'timestamp': current['timestamp'],
                    'filled': False
                })
        
        return fvgs
    
    def detect_liquidity_zones(self, candles: List[Dict]) -> List[Dict]:
        """
        Detect liquidity zones - areas where stop losses are likely placed
        
        Liquidity typically sits:
        - Above/below swing highs/lows
        - At round numbers
        - At previous day high/low
        
        Args:
            candles: List of OHLCV candles
            
        Returns:
            List of liquidity zones
        """
        liquidity_zones = []
        
        if len(candles) < 20:
            return liquidity_zones
        
        # Find swing highs and lows
        for i in range(10, len(candles) - 10):
            current = candles[i]
            
            # Check for swing high
            is_swing_high = True
            for j in range(i-5, i+5):
                if j != i and candles[j]['high'] > current['high']:
                    is_swing_high = False
                    break
            
            if is_swing_high:
                liquidity_zones.append({
                    'type': 'high',
                    'level': current['high'],
                    'timestamp': current['timestamp'],
                    'strength': self._calculate_liquidity_strength(candles, i, 'high')
                })
            
            # Check for swing low
            is_swing_low = True
            for j in range(i-5, i+5):
                if j != i and candles[j]['low'] < current['low']:
                    is_swing_low = False
                    break
            
            if is_swing_low:
                liquidity_zones.append({
                    'type': 'low',
                    'level': current['low'],
                    'timestamp': current['timestamp'],
                    'strength': self._calculate_liquidity_strength(candles, i, 'low')
                })
        
        return liquidity_zones
    
    def detect_breaker_blocks(self, candles: List[Dict], order_blocks: List[Dict]) -> List[Dict]:
        """
        Detect breaker blocks - failed order blocks that become support/resistance
        
        A breaker block forms when:
        - An order block is broken
        - Price returns to test it from the other side
        
        Args:
            candles: List of OHLCV candles
            order_blocks: Previously detected order blocks
            
        Returns:
            List of breaker blocks
        """
        breaker_blocks = []
        
        for ob in order_blocks:
            ob_time = ob['timestamp']
            
            # Find candles after the order block
            future_candles = [c for c in candles if c['timestamp'] > ob_time]
            
            if not future_candles:
                continue
            
            # Check if order block was broken
            broken = False
            break_candle = None
            
            for candle in future_candles:
                if ob['type'] == 'bullish' and candle['low'] < ob['low']:
                    broken = True
                    break_candle = candle
                    break
                elif ob['type'] == 'bearish' and candle['high'] > ob['high']:
                    broken = True
                    break_candle = candle
                    break
            
            if broken and break_candle:
                breaker_blocks.append({
                    'type': 'bearish' if ob['type'] == 'bullish' else 'bullish',
                    'original_ob_type': ob['type'],
                    'high': ob['high'],
                    'low': ob['low'],
                    'break_timestamp': break_candle['timestamp'],
                    'original_timestamp': ob_time
                })
        
        return breaker_blocks
    
    def detect_trend_breakout(self, candles: List[Dict]) -> Dict:
        """
        Detect trend breakouts using structure breaks
        
        Types:
        - BOS (Break of Structure): Continuation pattern
        - CHOCH (Change of Character): Reversal pattern
        
        Args:
            candles: List of OHLCV candles
            
        Returns:
            Dictionary with breakout information
        """
        if len(candles) < 50:
            return {'type': None, 'direction': None}
        
        # Identify market structure (higher highs, higher lows for uptrend)
        highs = [c['high'] for c in candles[-50:]]
        lows = [c['low'] for c in candles[-50:]]
        
        # Simple trend detection
        recent_highs = highs[-10:]
        recent_lows = lows[-10:]
        
        # Check for higher highs and higher lows (uptrend)
        hh = recent_highs[-1] > max(recent_highs[:-1])
        hl = recent_lows[-1] > min(recent_lows[:-1])
        
        # Check for lower highs and lower lows (downtrend)
        lh = recent_highs[-1] < max(recent_highs[:-1])
        ll = recent_lows[-1] < min(recent_lows[:-1])
        
        if hh and hl:
            return {
                'type': 'BOS',
                'direction': 'bullish',
                'strength': 'strong' if hh and hl else 'weak'
            }
        elif lh and ll:
            return {
                'type': 'BOS',
                'direction': 'bearish',
                'strength': 'strong' if lh and ll else 'weak'
            }
        elif hh and ll:
            return {
                'type': 'CHOCH',
                'direction': 'bullish_reversal',
                'strength': 'medium'
            }
        elif lh and hl:
            return {
                'type': 'CHOCH',
                'direction': 'bearish_reversal',
                'strength': 'medium'
            }
        
        return {'type': None, 'direction': None, 'strength': None}
    
    def calculate_entry_signal(self, 
                              symbol: str,
                              candles_h1: List[Dict],
                              candles_m15: List[Dict],
                              candles_m5: List[Dict]) -> Optional[Dict]:
        """
        Calculate entry signal using multi-timeframe analysis
        
        Args:
            symbol: Trading symbol
            candles_h1: H1 timeframe candles
            candles_m15: M15 timeframe candles
            candles_m5: M5 timeframe candles
            
        Returns:
            Entry signal dictionary or None
        """
        # Detect SMC elements
        ob_h1 = self.detect_order_blocks(candles_h1, "H1")
        fvg_h1 = self.detect_fair_value_gaps(candles_h1)
        liq_zones = self.detect_liquidity_zones(candles_h1)
        
        # Detect trend breakout
        breakout = self.detect_trend_breakout(candles_h1)
        
        if not breakout['type']:
            return None
        
        # Check alignment across timeframes
        current_price_h1 = candles_h1[-1]['close']
        current_price_m15 = candles_m15[-1]['close']
        current_price_m5 = candles_m5[-1]['close']
        
        # Calculate indicators
        ema_fast_m5 = self._calculate_ema(candles_m5, self.config['indicators']['ema_fast'])
        ema_slow_m5 = self._calculate_ema(candles_m5, self.config['indicators']['ema_slow'])
        rsi_m5 = self._calculate_rsi(candles_m5, self.config['indicators']['rsi_period'])
        
        # Entry logic
        signal = None
        
        # Bullish entry conditions
        if (breakout['direction'] in ['bullish', 'bullish_reversal'] and
            ema_fast_m5 > ema_slow_m5 and
            rsi_m5 > 30 and rsi_m5 < 70 and
            len(ob_h1) > 0 and ob_h1[-1]['type'] == 'bullish'):
            
            signal = {
                'symbol': symbol,
                'direction': 'BUY',
                'entry_price': current_price_m5,
                'stop_loss': self._calculate_stop_loss(candles_m5, 'BUY', ob_h1),
                'take_profit': None,  # Will be calculated based on TP ratio
                'timestamp': datetime.now().isoformat(),
                'confidence': self._calculate_confidence(breakout, ob_h1, fvg_h1, rsi_m5),
                'reason': f"SMC Bullish: {breakout['type']}, OB confirmed, EMAs aligned"
            }
        
        # Bearish entry conditions
        elif (breakout['direction'] in ['bearish', 'bearish_reversal'] and
              ema_fast_m5 < ema_slow_m5 and
              rsi_m5 > 30 and rsi_m5 < 70 and
              len(ob_h1) > 0 and ob_h1[-1]['type'] == 'bearish'):
            
            signal = {
                'symbol': symbol,
                'direction': 'SELL',
                'entry_price': current_price_m5,
                'stop_loss': self._calculate_stop_loss(candles_m5, 'SELL', ob_h1),
                'take_profit': None,  # Will be calculated based on TP ratio
                'timestamp': datetime.now().isoformat(),
                'confidence': self._calculate_confidence(breakout, ob_h1, fvg_h1, rsi_m5),
                'reason': f"SMC Bearish: {breakout['type']}, OB confirmed, EMAs aligned"
            }
        
        return signal
    
    def _calculate_ob_strength(self, candles: List[Dict], index: int) -> float:
        """Calculate order block strength (0-1)"""
        if index < 1 or index >= len(candles) - 1:
            return 0.5
        
        current = candles[index]
        next_candle = candles[index + 1]
        
        # Calculate strength based on:
        # 1. Size of the impulse move after OB (50% weight)
        # 2. Volume comparison if available (30% weight)
        # 3. Number of candles the OB holds (20% weight)
        
        strength = 0.0
        
        # 1. Impulse move strength
        ob_size = abs(current['high'] - current['low'])
        impulse_size = abs(next_candle['high'] - next_candle['low'])
        if ob_size > 0:
            impulse_ratio = min(impulse_size / ob_size, 3.0) / 3.0  # Normalize to 0-1
            strength += impulse_ratio * 0.5
        
        # 2. Volume strength (if available)
        if 'volume' in current and 'volume' in next_candle:
            avg_volume = sum(c.get('volume', 0) for c in candles[max(0, index-5):index]) / 5
            if avg_volume > 0:
                volume_ratio = min(current['volume'] / avg_volume, 2.0) / 2.0
                strength += volume_ratio * 0.3
        else:
            strength += 0.15  # Default if no volume data
        
        # 3. Holding power (how many candles respect the OB)
        held_count = 0
        for i in range(index + 1, min(index + 10, len(candles))):
            if current['type'] == 'bullish' and candles[i]['low'] >= current['low']:
                held_count += 1
            elif current['type'] == 'bearish' and candles[i]['high'] <= current['high']:
                held_count += 1
            else:
                break
        strength += min(held_count / 5.0, 1.0) * 0.2
        
        return min(strength, 1.0)
    
    def _calculate_liquidity_strength(self, candles: List[Dict], index: int, level_type: str) -> float:
        """Calculate liquidity zone strength (0-1)"""
        if index < 10 or index >= len(candles) - 10:
            return 0.5
        
        current = candles[index]
        level = current['high'] if level_type == 'high' else current['low']
        
        strength = 0.0
        
        # 1. Number of times level was tested (40% weight)
        touch_count = 0
        for i in range(max(0, index - 20), min(index + 20, len(candles))):
            if i == index:
                continue
            candle = candles[i]
            if level_type == 'high':
                if abs(candle['high'] - level) / level < 0.001:  # Within 0.1%
                    touch_count += 1
            else:
                if abs(candle['low'] - level) / level < 0.001:
                    touch_count += 1
        
        strength += min(touch_count / 5.0, 1.0) * 0.4
        
        # 2. Time since formation (30% weight) - older = stronger
        lookback = index
        age_ratio = min(lookback / 50.0, 1.0)
        strength += age_ratio * 0.3
        
        # 3. Distance from current price (30% weight) - closer = stronger
        current_price = candles[-1]['close']
        distance = abs(level - current_price) / current_price
        proximity_score = max(1.0 - (distance * 10), 0.0)  # Closer levels score higher
        strength += proximity_score * 0.3
        
        return min(strength, 1.0)
    
    def _calculate_ema(self, candles: List[Dict], period: int) -> float:
        """Calculate Exponential Moving Average"""
        if len(candles) < period:
            return 0
        
        closes = [c['close'] for c in candles[-period:]]
        multiplier = 2 / (period + 1)
        ema = closes[0]
        
        for close in closes[1:]:
            ema = (close * multiplier) + (ema * (1 - multiplier))
        
        return ema
    
    def _calculate_rsi(self, candles: List[Dict], period: int = 14) -> float:
        """Calculate Relative Strength Index"""
        if len(candles) < period + 1:
            return 50
        
        closes = [c['close'] for c in candles[-(period+1):]]
        gains = []
        losses = []
        
        for i in range(1, len(closes)):
            change = closes[i] - closes[i-1]
            if change > 0:
                gains.append(change)
                losses.append(0)
            else:
                gains.append(0)
                losses.append(abs(change))
        
        avg_gain = sum(gains) / period
        avg_loss = sum(losses) / period
        
        if avg_loss == 0:
            return 100
        
        rs = avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))
        
        return rsi
    
    def _calculate_stop_loss(self, candles: List[Dict], direction: str, order_blocks: List[Dict]) -> float:
        """Calculate stop loss based on order blocks and ATR"""
        if not order_blocks:
            # Fallback to recent swing
            recent_candles = candles[-20:]
            if direction == 'BUY':
                return min(c['low'] for c in recent_candles)
            else:
                return max(c['high'] for c in recent_candles)
        
        latest_ob = order_blocks[-1]
        if direction == 'BUY':
            return latest_ob['low'] * 0.999  # Slightly below OB
        else:
            return latest_ob['high'] * 1.001  # Slightly above OB
    
    def _calculate_confidence(self, breakout: Dict, order_blocks: List[Dict], 
                            fvgs: List[Dict], rsi: float) -> float:
        """Calculate signal confidence (0-1)"""
        confidence = 0.5  # Base confidence
        
        # Add confidence for strong breakout
        if breakout.get('strength') == 'strong':
            confidence += 0.2
        
        # Add confidence for order block confirmation
        if order_blocks:
            confidence += 0.15
        
        # Add confidence for FVG presence
        if fvgs:
            confidence += 0.1
        
        # Adjust for RSI (avoid extremes)
        if 40 <= rsi <= 60:
            confidence += 0.05
        
        return min(confidence, 1.0)

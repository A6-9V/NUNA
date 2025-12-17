"""
Exness Broker API Implementation
"""
import requests
import time
from typing import Dict, List, Optional, Any
from datetime import datetime

from .base_broker import BaseBroker, BrokerConfig, OrderResult, Position, AccountInfo


class ExnessAPI(BaseBroker):
    """Exness broker API implementation"""
    
    def __init__(self, config: BrokerConfig):
        """
        Initialize Exness API
        
        Args:
            config: Broker configuration
        """
        super().__init__(config)
        self.session = requests.Session()
        self.base_url = config.api_url.rstrip('/')
        self.account_id = config.account_id
        
        # Setup session headers
        if config.api_key:
            self.session.headers.update({
                'Authorization': f'Bearer {config.api_key}',
                'Content-Type': 'application/json',
                'X-Account-ID': config.account_id
            })
        
        # Rate limiting
        self.last_request_time = 0
        self.min_request_interval = 0.1  # 100ms between requests
        self.rate_limit = config.rate_limit or {'requests_per_minute': 60}
    
    def _rate_limit(self):
        """Apply rate limiting"""
        current_time = time.time()
        elapsed = current_time - self.last_request_time
        if elapsed < self.min_request_interval:
            time.sleep(self.min_request_interval - elapsed)
        self.last_request_time = time.time()
    
    def _make_request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        """
        Make HTTP request to Exness API
        
        Args:
            method: HTTP method (GET, POST, etc.)
            endpoint: API endpoint
            **kwargs: Additional request parameters
            
        Returns:
            Response data as dictionary
        """
        self._rate_limit()
        
        url = f"{self.base_url}{endpoint}"
        
        try:
            response = self.session.request(method, url, timeout=10, **kwargs)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            # Don't expose API details in error
            return {'error': 'API request failed', 'details': str(e)}
    
    def place_order(self, symbol: str, action: str, lot_size: float,
                   stop_loss: Optional[float] = None,
                   take_profit: Optional[float] = None,
                   comment: str = "") -> OrderResult:
        """
        Place order via Exness API
        
        Args:
            symbol: Trading symbol
            action: Order action (BUY/SELL)
            lot_size: Position size in lots
            stop_loss: Stop loss price
            take_profit: Take profit price
            comment: Order comment
            
        Returns:
            OrderResult
        """
        if not self.validate_symbol(symbol):
            return OrderResult(
                success=False,
                message=f"Invalid symbol: {symbol}",
                error_code="INVALID_SYMBOL"
            )
        
        # Prepare order data
        order_data = {
            'symbol': symbol,
            'side': action.upper(),
            'volume': lot_size,
            'account_id': self.account_id
        }
        
        if stop_loss:
            order_data['stop_loss'] = stop_loss
        
        if take_profit:
            order_data['take_profit'] = take_profit
        
        if comment:
            order_data['comment'] = comment
        
        # Make API request
        response = self._make_request('POST', '/orders', json=order_data)
        
        if 'error' in response:
            return OrderResult(
                success=False,
                message=response.get('error', 'Unknown error'),
                error_code=response.get('error_code', 'API_ERROR')
            )
        
        return OrderResult(
            success=True,
            order_id=response.get('order_id'),
            message=response.get('message', 'Order placed successfully')
        )
    
    def get_account_info(self) -> AccountInfo:
        """
        Get Exness account information
        
        Returns:
            AccountInfo
        """
        response = self._make_request('GET', f'/accounts/{self.account_id}')
        
        if 'error' in response:
            # Return default values on error
            return AccountInfo(
                balance=0.0,
                equity=0.0,
                margin=0.0,
                free_margin=0.0,
                margin_level=0.0
            )
        
        return AccountInfo(
            balance=float(response.get('balance', 0)),
            equity=float(response.get('equity', 0)),
            margin=float(response.get('margin', 0)),
            free_margin=float(response.get('free_margin', 0)),
            margin_level=float(response.get('margin_level', 0)),
            currency=response.get('currency', 'USD')
        )
    
    def get_positions(self, symbol: Optional[str] = None) -> List[Position]:
        """
        Get open positions from Exness
        
        Args:
            symbol: Filter by symbol (None = all)
            
        Returns:
            List of positions
        """
        endpoint = '/positions'
        if symbol:
            endpoint += f'?symbol={symbol}'
        
        response = self._make_request('GET', endpoint)
        
        if 'error' in response or 'positions' not in response:
            return []
        
        positions = []
        for pos_data in response.get('positions', []):
            position = Position(
                symbol=pos_data.get('symbol', ''),
                volume=float(pos_data.get('volume', 0)),
                type=pos_data.get('type', 'BUY'),
                open_price=float(pos_data.get('open_price', 0)),
                current_price=float(pos_data.get('current_price', 0)),
                profit=float(pos_data.get('profit', 0)),
                swap=float(pos_data.get('swap', 0)),
                commission=float(pos_data.get('commission', 0)),
                position_id=pos_data.get('position_id')
            )
            positions.append(position)
        
        return positions
    
    def close_position(self, position_id: str) -> OrderResult:
        """
        Close position on Exness
        
        Args:
            position_id: Position ID to close
            
        Returns:
            OrderResult
        """
        response = self._make_request('DELETE', f'/positions/{position_id}')
        
        if 'error' in response:
            return OrderResult(
                success=False,
                message=response.get('error', 'Failed to close position'),
                error_code=response.get('error_code', 'CLOSE_ERROR')
            )
        
        return OrderResult(
            success=True,
            order_id=response.get('order_id'),
            message='Position closed successfully'
        )
    
    def modify_position(self, position_id: str, stop_loss: Optional[float] = None,
                       take_profit: Optional[float] = None) -> OrderResult:
        """
        Modify position on Exness
        
        Args:
            position_id: Position ID
            stop_loss: New stop loss
            take_profit: New take profit
            
        Returns:
            OrderResult
        """
        update_data = {}
        if stop_loss is not None:
            update_data['stop_loss'] = stop_loss
        if take_profit is not None:
            update_data['take_profit'] = take_profit
        
        if not update_data:
            return OrderResult(
                success=False,
                message='No modifications specified',
                error_code='NO_MODIFICATIONS'
            )
        
        response = self._make_request('PATCH', f'/positions/{position_id}', json=update_data)
        
        if 'error' in response:
            return OrderResult(
                success=False,
                message=response.get('error', 'Failed to modify position'),
                error_code=response.get('error_code', 'MODIFY_ERROR')
            )
        
        return OrderResult(
            success=True,
            order_id=response.get('order_id'),
            message='Position modified successfully'
        )


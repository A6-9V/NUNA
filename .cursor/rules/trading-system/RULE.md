---
description: "Trading system development standards for Python-MQL5 bridge, multi-broker APIs, and automated trading"
alwaysApply: false
globs: ["trading-bridge/**/*.py", "**/*.mq5", "trading-bridge/**/*.ps1"]
---

# Trading System Development Standards

When working with the trading system (Python-MQL5 bridge, broker APIs, trading strategies), follow these standards:

## Python Trading Code Standards

### Code Structure
- Use dataclasses for trade signals and configurations
- Implement abstract base classes for brokers
- Use factory pattern for broker instantiation
- Separate concerns: bridge, brokers, strategies, services

### Error Handling
- Always wrap broker API calls in try-except blocks
- Never expose API keys or credentials in error messages
- Log errors to files (not console) with sanitized messages
- Implement retry logic with exponential backoff for API calls

### Security
- Never hardcode API keys or credentials
- Use Windows Credential Manager for credential storage
- Validate all inputs before sending to brokers
- Sanitize logs to remove sensitive data

### Signal Management
- Use queue-based signal processing
- Validate signals before queuing
- Implement signal deduplication
- Track signal history for debugging

### Broker Integration
- Implement abstract base class `BaseBroker`
- Each broker must implement: `place_order()`, `get_account_info()`, `get_positions()`
- Use factory pattern: `BrokerFactory.create_broker(name, config)`
- Handle broker-specific errors gracefully

## MQL5 Integration Patterns

### EA Structure
- Use ZeroMQ or Named Pipes for Python communication
- Implement reconnection logic for bridge connection
- Validate all signals before execution
- Log all trades and errors

### Communication Protocol
- Use JSON for message format
- Implement request-response pattern
- Include error codes in responses
- Handle timeout scenarios

### Signal Format
```json
{
  "symbol": "EURUSD",
  "action": "BUY",
  "broker": "EXNESS",
  "lot_size": 0.01,
  "stop_loss": 1.0850,
  "take_profit": 1.0900,
  "comment": "Strategy signal"
}
```

## Multi-Broker Support

### Configuration
- Store broker configs in `trading-bridge/config/brokers.json` (gitignored)
- Use template file `brokers.json.example` for documentation
- Load configs securely via `CredentialManager`

### Broker Implementation
- Each broker extends `BaseBroker`
- Implement broker-specific API client
- Handle rate limiting per broker
- Support multiple accounts per broker

## Multi-Symbol Trading

### Symbol Configuration
- Store symbol configs in `trading-bridge/config/symbols.json`
- Support per-symbol risk management
- Track positions per symbol
- Implement symbol-specific strategies

### Risk Management
- Calculate position size based on account risk
- Set stop loss and take profit per symbol
- Monitor total exposure across symbols
- Implement position limits per symbol

## Background Services

### Service Structure
- Run as background process (hidden window)
- Implement health checks
- Auto-restart on failure
- Log to files (not console)

### Monitoring
- Monitor bridge connection status
- Track signal queue size
- Monitor broker API health
- Alert on critical errors

## Code Examples

### Broker Implementation
```python
from brokers.base_broker import BaseBroker

class ExnessAPI(BaseBroker):
    def place_order(self, symbol: str, action: str, lot_size: float,
                   stop_loss: float, take_profit: float) -> Dict:
        # Implementation
        pass
```

### Signal Creation
```python
from bridge.signal_manager import TradeSignal

signal = TradeSignal(
    symbol="EURUSD",
    action="BUY",
    broker="EXNESS",
    lot_size=0.01,
    stop_loss=1.0850,
    take_profit=1.0900
)
```

## Best Practices

1. **Never log credentials**: Sanitize all logs
2. **Validate inputs**: Check all signal parameters
3. **Handle errors gracefully**: Don't crash on API errors
4. **Use queues**: Don't block on broker API calls
5. **Monitor health**: Implement health check endpoints
6. **Secure storage**: Use CredentialManager for all secrets
7. **Test thoroughly**: Test with demo accounts first

## References

- See `trading-bridge/SECURITY.md` for security guidelines
- See `trading-bridge/CONFIGURATION.md` for setup instructions
- See `trading-bridge/README.md` for architecture overview


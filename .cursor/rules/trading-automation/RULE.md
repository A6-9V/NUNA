# Trading Automation Rules for Cursor AI

## Overview
Rules for working with the 18-Symbol Trading System with SMC strategy, automated risk management, and multi-team communication.

## Code Style and Standards

### Python Trading Code
- Use type hints for all function parameters and return values
- Follow PEP 8 style guide
- Use dataclasses for structured data
- Implement comprehensive logging
- Add docstrings to all public methods

Example:
```python
from typing import Dict, List, Optional
from dataclasses import dataclass
import logging

@dataclass
class TradeSignal:
    """Represents a trading signal"""
    symbol: str
    direction: str  # 'BUY' or 'SELL'
    entry_price: float
    stop_loss: float
    take_profit: float
    confidence: float

def calculate_entry_signal(
    symbol: str,
    candles: List[Dict],
    config: Dict
) -> Optional[TradeSignal]:
    """
    Calculate entry signal for a symbol
    
    Args:
        symbol: Trading symbol
        candles: Historical candle data
        config: Strategy configuration
        
    Returns:
        TradeSignal if conditions met, None otherwise
    """
    logger = logging.getLogger(__name__)
    logger.info(f"Analyzing {symbol}")
    # Implementation...
```

### PowerShell Scripts
- Use approved verbs (Get-, Set-, New-, Remove-)
- Add comment-based help
- Implement proper error handling
- Use Write-Host with colors for user feedback
- Store sensitive data in Windows Credential Manager

Example:
```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Setup trading configuration
.DESCRIPTION
    Configures the trading system with proper security
#>

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Starting configuration..." -ForegroundColor Cyan

try {
    # Implementation
    Write-Host "[OK] Configuration complete" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed: $_" -ForegroundColor Red
    exit 1
}
```

## Security Requirements

### Credential Management
1. **NEVER** hardcode credentials in code
2. **ALWAYS** use Windows Credential Manager for sensitive data
3. **NEVER** commit credential files to git
4. Use environment variables as fallback only

```python
# Good - Using Credential Manager
from security.credential_manager import CredentialManager
cm = CredentialManager()
api_key = cm.get_credential("EXNESS_API_KEY")

# Bad - Hardcoded
api_key = "sk_live_12345..."  # NEVER DO THIS
```

### Configuration Files
- All `.json` config files with credentials must be in `.gitignore`
- Provide `.example` templates for all configs
- Document required credentials in README
- Use separate config files for different environments

### API Security
- Implement rate limiting
- Use HTTPS for all API calls
- Validate all inputs
- Log security events

## Trading System Architecture

### Module Structure
```
trading-bridge/
├── python/
│   ├── strategies/          # Trading strategies
│   │   ├── __init__.py
│   │   └── smc_strategy.py
│   ├── risk/                # Risk management
│   │   ├── __init__.py
│   │   └── risk_calculator.py
│   ├── communications/      # Multi-team communication
│   ├── bridge/              # MQL5 bridge
│   ├── brokers/             # Broker APIs
│   └── trader/              # Multi-symbol trader
├── config/                  # Configuration (gitignored)
│   ├── symbols.json
│   ├── capital-allocation.json
│   └── communication-teams.json
└── logs/                    # Logs (gitignored)
```

### Key Components

#### 1. SMC Strategy (strategies/smc_strategy.py)
- Order block detection
- Fair value gap identification
- Liquidity zone mapping
- Trend breakout detection
- Multi-timeframe analysis

#### 2. Risk Calculator (risk/risk_calculator.py)
- Automatic lot size calculation
- TP/SL calculation
- Position sizing
- Risk limit validation

#### 3. Communication System
- WhatsApp/Twilio integration
- Telegram notifications
- Perplexity AI research
- OpenAI/ChatGPT analysis

## Development Guidelines

### Adding New Symbols
1. Add symbol to `capital-allocation.json`
2. Add configuration to `symbols-18-trading.json.example`
3. Update symbol type in `risk_calculator.py` if needed
4. Test with small position sizes first

### Modifying Strategies
1. Create new strategy class inheriting from base
2. Implement required methods
3. Add comprehensive unit tests
4. Document strategy logic
5. Test on historical data before live trading

### Risk Management Rules
- **NEVER** bypass risk validation
- **ALWAYS** set stop losses
- **ALWAYS** validate lot sizes
- Implement circuit breakers for excessive losses
- Log all risk calculations

## Testing Requirements

### Strategy Testing
```python
def test_smc_order_blocks():
    """Test order block detection"""
    strategy = SMCStrategy()
    test_candles = load_test_data("EURUSD_H1")
    
    order_blocks = strategy.detect_order_blocks(test_candles)
    
    assert len(order_blocks) > 0
    assert order_blocks[0]['type'] in ['bullish', 'bearish']
```

### Risk Testing
```python
def test_lot_size_calculation():
    """Test lot size calculation"""
    calculator = RiskCalculator()
    
    lot_size = calculator.calculate_lot_size(
        account_balance=1000,
        risk_percent=1.0,
        entry_price=1.1000,
        stop_loss_price=1.0950,
        symbol="EURUSD"
    )
    
    assert 0.01 <= lot_size <= 10.0
    assert lot_size == pytest.approx(expected_size, rel=0.01)
```

## Configuration Management

### Symbol Configuration
Each symbol must have:
- Broker assignment
- Risk parameters
- Strategy settings
- TP/SL configuration
- Pending order settings

### Capital Tiers
Define clear tiers based on capital:
- Micro: $10-$50 → 1 symbol
- Mini: $51-$150 → 3 symbols
- Standard: $151-$500 → 6 symbols
- Advanced: $501-$2000 → 12 symbols
- Professional: $2001+ → 18 symbols

## Logging Standards

### Log Levels
- `DEBUG`: Detailed diagnostic information
- `INFO`: General information about system operation
- `WARNING`: Warning messages for unusual situations
- `ERROR`: Error messages for failures
- `CRITICAL`: Critical issues requiring immediate attention

### Log Format
```python
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/trading_YYYYMMDD.log'),
        logging.StreamHandler()
    ]
)
```

## GitHub Copilot Integration

### Using Copilot for Trading Code
- Use descriptive variable names for better suggestions
- Write clear function signatures with type hints
- Add inline comments for complex logic
- Review all AI-generated code for correctness

### Cursor AI Commands
When working with Cursor:
- "@workspace /explain" - Explain trading logic
- "@workspace /fix" - Fix bugs in strategy code
- "@workspace /test" - Generate test cases
- "@workspace /docs" - Generate documentation

### Jules Agent (Google AI) Integration
- Use for high-level system decisions
- Coordinate between different teams
- Analyze market conditions
- Optimize strategy parameters

## Communication Protocol

### Notification Priorities
1. **Urgent**: Trade execution, margin calls, system errors
2. **Important**: New signals, position updates, daily reports
3. **Info**: System status, performance metrics

### Team Communication Flow
```
Market Event → Perplexity Analysis → GPT Decision → WhatsApp/Telegram Alert
                                   ↓
                        Trade Signal → Risk Validation → Execution
```

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Configuration files reviewed
- [ ] Credentials stored securely
- [ ] Risk limits configured
- [ ] Communication channels tested
- [ ] Logs directory created
- [ ] Backup plan in place

### Post-Deployment
- [ ] Monitor first trades closely
- [ ] Verify notifications working
- [ ] Check log files for errors
- [ ] Validate risk calculations
- [ ] Confirm TP/SL placement

## Emergency Procedures

### Stopping the System
```powershell
# Emergency stop
Stop-Process -Name "python" -Force
Stop-Process -Name "terminal64" -Force  # MT5

# Verify stopped
Get-Process | Where-Object {$_.Name -like "*python*"}
```

### Recovering from Errors
1. Check logs for error details
2. Verify configuration files
3. Test credentials in Credential Manager
4. Restart services one by one
5. Monitor closely after restart

## Performance Optimization

### Strategy Performance
- Cache frequently accessed data
- Use vectorized operations where possible
- Minimize API calls
- Implement efficient data structures

### System Performance
- Monitor CPU and memory usage
- Optimize database queries
- Use asynchronous operations
- Implement connection pooling

## Documentation Requirements

### Code Documentation
- Module-level docstrings
- Class and method docstrings
- Inline comments for complex logic
- Type hints for all functions

### Configuration Documentation
- README in each config directory
- Examples for all config files
- Security notes for sensitive settings
- Update logs for configuration changes

## Continuous Improvement

### Review Process
1. Weekly performance review
2. Monthly strategy optimization
3. Quarterly system audit
4. Regular security updates

### Metrics to Track
- Win rate per symbol
- Average risk/reward ratio
- System uptime
- Execution speed
- Communication latency

## Support Resources

### Internal Documentation
- `18-SYMBOL-TRADING-GUIDE.md` - Complete system guide
- `CONFIGURATION.md` - Configuration details
- `SECURITY.md` - Security practices
- `README.md` - Quick start guide

### External Resources
- Exness API documentation
- MT5 documentation
- Python trading libraries
- SMC strategy resources

## Version Control

### Commit Messages
```
feat: Add ETHUSD to trading symbols
fix: Correct lot size calculation for gold
docs: Update configuration guide
refactor: Improve order block detection
test: Add unit tests for risk calculator
```

### Branch Strategy
- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: New features
- `fix/*`: Bug fixes
- `hotfix/*`: Emergency fixes

## Final Notes

When working with this trading system:
1. **Safety first** - Always validate before executing
2. **Test thoroughly** - Use demo accounts for testing
3. **Monitor closely** - Especially during initial deployment
4. **Document changes** - Keep documentation up to date
5. **Security always** - Never compromise on security

Remember: This system trades real money. Every change should be carefully considered and thoroughly tested.

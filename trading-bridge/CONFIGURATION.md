# Trading Bridge Configuration Guide

Complete configuration guide for the trading bridge system.

## Broker Configuration

### Setup Broker API Keys

1. Copy `config/brokers.json.example` to `config/brokers.json`
2. Edit `config/brokers.json` with your broker details
3. Store API keys securely using CredentialManager

### Exness Configuration

```json
{
  "brokers": [
    {
      "name": "EXNESS",
      "api_url": "https://api.exness.com",
      "account_id": "YOUR_ACCOUNT_ID",
      "api_key": "YOUR_API_KEY",
      "api_secret": "YOUR_API_SECRET",
      "enabled": true
    }
  ]
}
```

### Storing Credentials Securely

**Option 1: Windows Credential Manager (Recommended)**

```python
from security.credential_manager import CredentialManager

cm = CredentialManager()
cm.store_credential("EXNESS_API_KEY", "your_api_key_here")
cm.store_credential("EXNESS_API_SECRET", "your_api_secret_here")
```

**Option 2: Environment Variables**

Set environment variables:
- `TRADINGBRIDGE_EXNESS_API_KEY`
- `TRADINGBRIDGE_EXNESS_API_SECRET`

## Symbol Configuration

### Setup Trading Symbols

1. Copy `config/symbols.json.example` to `config/symbols.json`
2. Configure symbols you want to trade

### Example Configuration

```json
{
  "symbols": [
    {
      "symbol": "EURUSD",
      "broker": "EXNESS",
      "enabled": true,
      "risk_percent": 1.0,
      "max_positions": 1,
      "min_lot_size": 0.01,
      "max_lot_size": 10.0
    }
  ]
}
```

### Symbol Parameters

- **symbol**: Trading symbol (e.g., "EURUSD")
- **broker**: Broker name (must match broker config)
- **enabled**: Enable/disable trading for this symbol
- **risk_percent**: Risk percentage per trade (1.0 = 1%)
- **max_positions**: Maximum concurrent positions
- **min_lot_size**: Minimum lot size
- **max_lot_size**: Maximum lot size

## MQL5 EA Configuration

### Setup MQL5 Expert Advisor

1. Copy `mql5/Experts/PythonBridgeEA.mq5` to your MT5 Experts directory
2. Compile the EA in MetaEditor (F7)
3. Attach EA to chart
4. Configure parameters:
   - **BridgePort**: 5500 (default)
   - **BrokerName**: "EXNESS"
   - **AutoExecute**: true/false
   - **DefaultLotSize**: 0.01

### MQL5 EA Location

Default MT5 Experts directory:
```
C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\
```

## Bridge Configuration

### Port Configuration

Default bridge port: **5500**

To change port:
1. Edit `python/services/background_service.py`
2. Change `bridge_port` parameter
3. Update MQL5 EA `BridgePort` parameter

### Firewall Rules

Allow port 5500 (or your custom port) through Windows Firewall:
```powershell
New-NetFirewallRule -DisplayName "Trading Bridge" -Direction Inbound -LocalPort 5500 -Protocol TCP -Action Allow
```

## VPS Configuration

### Laptop-VPS Sync

**Option 1: Git Sync (Recommended)**

1. Push code to GitHub from laptop
2. VPS pulls automatically via `trading-bridge-service.ps1`

**Option 2: OneDrive Sync**

1. Both devices connected to OneDrive
2. Files sync automatically

### VPS Service Configuration

Edit `vps-services/trading-bridge-service.ps1` to configure:
- Sync interval (default: 5 minutes)
- GitHub repository URL
- Sync method

## Auto-Start Configuration

### Windows Scheduled Task

Run `setup-trading-auto-start.ps1` to create auto-start task.

Task configuration:
- **Trigger**: At startup
- **Action**: Run `start-trading-system-admin.ps1`
- **Run as**: Administrator
- **Restart**: Up to 3 times on failure

### Manual Start

```powershell
.\start-trading-system-admin.ps1
```

## Logging Configuration

### Log Locations

- Bridge logs: `trading-bridge/logs/mql5_bridge_YYYYMMDD.log`
- Service logs: `trading-bridge/logs/trading_service_YYYYMMDD.log`
- Orchestrator logs: `trading-bridge/logs/orchestrator_YYYYMMDD.log`

### Log Levels

Configure in Python files:
- `logging.INFO` - Standard information
- `logging.DEBUG` - Detailed debugging
- `logging.WARNING` - Warnings
- `logging.ERROR` - Errors

## Testing Configuration

### Test Broker Connection

```python
from brokers.broker_factory import BrokerFactory

broker = BrokerFactory.create_broker("EXNESS")
if broker:
    account_info = broker.get_account_info()
    print(f"Balance: {account_info.balance}")
```

### Test Bridge Connection

```python
from bridge.mql5_bridge import MQL5Bridge

bridge = MQL5Bridge(port=5500)
bridge.start()  # In separate thread
```

## Troubleshooting

### Broker API Not Working

1. Verify API keys in CredentialManager
2. Check API URL is correct
3. Verify account ID
4. Check broker API documentation

### Bridge Not Connecting

1. Verify Python service is running
2. Check port 5500 is not in use
3. Verify firewall rules
4. Check logs for errors

### MQL5 EA Not Receiving Signals

1. Verify EA is attached to chart
2. Check bridge connection status
3. Verify AutoExecute is enabled
4. Check EA logs in MT5


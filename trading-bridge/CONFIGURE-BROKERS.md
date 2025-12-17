# Configure Brokers for Trading System

## Quick Setup Guide

### Step 1: Edit Broker Configuration

Edit `trading-bridge/config/brokers.json` with your broker details:

```json
{
  "brokers": [
    {
      "name": "EXNESS",
      "api_url": "https://api.exness.com",
      "account_id": "YOUR_ACCOUNT_ID",
      "api_key": "YOUR_API_KEY_HERE",
      "api_secret": "YOUR_API_SECRET_HERE",
      "enabled": true,
      "rate_limit": {
        "requests_per_minute": 60,
        "requests_per_second": 10
      }
    }
  ],
  "default_broker": "EXNESS"
}
```

### Step 2: Store API Keys Securely

**IMPORTANT**: Never store API keys directly in `brokers.json`. Use Windows Credential Manager:

#### Option A: Using PowerShell (Recommended)

```powershell
# Store Exness API Key
python -c "from trading_bridge.python.security.credential_manager import CredentialManager; cm = CredentialManager(); cm.store_credential('EXNESS_API_KEY', 'your_actual_api_key_here')"

# Store Exness API Secret
python -c "from trading_bridge.python.security.credential_manager import CredentialManager; cm = CredentialManager(); cm.store_credential('EXNESS_API_SECRET', 'your_actual_api_secret_here')"
```

#### Option B: Using Python Script

Create `trading-bridge/scripts/store-credentials.py`:

```python
from security.credential_manager import CredentialManager

cm = CredentialManager()

# Store credentials
cm.store_credential('EXNESS_API_KEY', 'your_api_key')
cm.store_credential('EXNESS_API_SECRET', 'your_api_secret')
cm.store_credential('EXNESS_ACCOUNT_ID', 'your_account_id')
```

Then run:
```powershell
cd trading-bridge\python
python scripts\store-credentials.py
```

### Step 3: Update brokers.json to Use Credentials

After storing credentials, update `brokers.json`:

```json
{
  "brokers": [
    {
      "name": "EXNESS",
      "api_url": "https://api.exness.com",
      "account_id": "CREDENTIAL:EXNESS_ACCOUNT_ID",
      "api_key": "CREDENTIAL:EXNESS_API_KEY",
      "api_secret": "CREDENTIAL:EXNESS_API_SECRET",
      "enabled": true
    }
  ]
}
```

The system will automatically retrieve credentials from Windows Credential Manager when it sees `CREDENTIAL:` prefix.

### Step 4: Configure Trading Symbols

Edit `trading-bridge/config/symbols.json`:

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

### Step 5: Verify Configuration

Run the verification script:

```powershell
.\verify-trading-config.ps1
```

## Security Best Practices

1. ✅ **Never commit** `brokers.json` or `symbols.json` with real credentials
2. ✅ **Always use** Windows Credential Manager for API keys
3. ✅ **Use** `CREDENTIAL:` prefix in config files
4. ✅ **Test** with paper trading accounts first
5. ✅ **Monitor** logs for any credential exposure

## Testing Broker Connection

After configuration, test the connection:

```powershell
cd trading-bridge\python
python -c "from brokers.broker_factory import BrokerFactory; brokers = BrokerFactory.create_all_brokers(); print('Brokers loaded:', list(brokers.keys()))"
```

## Troubleshooting

### "Credential not found" Error
- Ensure credentials are stored in Windows Credential Manager
- Check credential names match exactly (case-sensitive)
- Verify `CREDENTIAL:` prefix is used in config

### "API connection failed" Error
- Verify API URL is correct
- Check API key permissions
- Ensure account ID matches your broker account
- Check rate limits aren't exceeded

### "Module not found" Error
- Run `.\install-trading-dependencies.ps1`
- Verify Python path is correct
- Check all `__init__.py` files exist

## Next Steps

1. ✅ Configure brokers.json
2. ✅ Store API keys securely
3. ✅ Configure symbols.json
4. ✅ Verify configuration
5. ✅ Start trading system: `.\START-TRADING-SYSTEM-COMPLETE.ps1`
6. ✅ Attach MQL5 EA to charts
7. ✅ Monitor logs: `trading-bridge\logs\`





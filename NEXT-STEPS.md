# Next Steps Guide

This guide covers both **Drive Management Setup** and **Trading System Configuration**.

---

## Part 1: Drive Management Tools (NUNA)

### Current Status

✅ Repository cloned and ready  
✅ Python packages installed  
✅ Setup scripts created  
⏳ OAuth credentials need to be configured

### Step 1: Complete OAuth Setup

#### Quick Setup (Recommended)

Run the automated helper:
```powershell
cd J:\NUNA
.\auto-setup-helper.ps1
```

This will:
- Open Google Cloud Console and Azure Portal in your browser
- Show step-by-step instructions
- Check what's already configured

#### Manual Setup

See `SETUP-OAUTH.md` for detailed instructions.

### Step 2: Verify Setup

After completing OAuth setup, verify everything works:

**Check Status:**
```powershell
.\check-oauth-setup.ps1
```

**Test Google Drive:**
```powershell
.\test-google-drive.ps1
```

**Test OneDrive:**
```powershell
.\test-onedrive.ps1
```

### Step 3: Start Using the Tools

#### Google Drive Cleanup

**Audit your Drive (find largest files):**
```bash
python gdrive_cleanup.py audit --top 25 --show-links
```

**Export full inventory:**
```bash
python gdrive_cleanup.py audit --csv gdrive-report.csv --json gdrive-report.json
```

**Find duplicate files:**
```bash
python gdrive_cleanup.py duplicates --show 20 --show-per-group 10
```

#### Dropbox to OneDrive Import

**Preview what will be imported (dry-run):**
```bash
python dropbox_to_onedrive.py --dropbox-url "YOUR_DROPBOX_SHARED_FOLDER_URL" --dry-run
```

**Import to OneDrive:**
```bash
python dropbox_to_onedrive.py --dropbox-url "YOUR_DROPBOX_SHARED_FOLDER_URL" --onedrive-folder "Dropbox Import"
```

---

## Part 2: Trading System - Next Steps

**Date**: 2025-12-15  
**Status**: ✅ **SYSTEM READY FOR CONFIGURATION**

### What's Been Completed

#### 1. Core System ✅
- ✅ Python-MQL5 Bridge (ZeroMQ on port 5555)
- ✅ Multi-Broker API Manager
- ✅ Multi-Symbol Trading System
- ✅ Background Service with auto-restart
- ✅ Master Orchestrator (monitoring & recovery)
- ✅ MQL5 Expert Advisor (EA)
- ✅ Security (Credential Manager)
- ✅ Auto-startup configuration

#### 2. Configuration Files ✅
- ✅ `brokers.json` - Created (needs your API keys)
- ✅ `symbols.json` - Created (ready to configure)
- ✅ Configuration templates and examples

#### 3. Documentation ✅
- ✅ `CONFIGURE-BROKERS.md` - Broker setup guide
- ✅ `verify-trading-config.ps1` - Configuration checker
- ✅ `store-credentials.py` - Secure credential storage script

### Next Steps to Start Trading

#### Step 1: Configure Broker API Keys (5 minutes)

**Option A: Interactive Script (Recommended)**
```powershell
cd trading-bridge\python
python scripts\store-credentials.py
```

**Option B: Manual PowerShell**
```powershell
python -c "from trading_bridge.python.security.credential_manager import CredentialManager; cm = CredentialManager(); cm.store_credential('EXNESS_API_KEY', 'your_key_here')"
python -c "from trading_bridge.python.security.credential_manager import CredentialManager; cm = CredentialManager(); cm.store_credential('EXNESS_API_SECRET', 'your_secret_here')"
```

#### Step 2: Update brokers.json

Edit `trading-bridge/config/brokers.json`:

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
  ],
  "default_broker": "EXNESS"
}
```

**Important**: Use `CREDENTIAL:` prefix to reference stored credentials.

#### Step 3: Configure Trading Symbols

Edit `trading-bridge/config/symbols.json` to add symbols you want to trade:

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

#### Step 4: Verify Configuration

```powershell
.\verify-trading-config.ps1
```

This will check:
- ✅ Configuration files exist
- ✅ JSON is valid
- ✅ Python modules import correctly
- ✅ Credentials are configured

#### Step 5: Start Trading System

```powershell
.\START-TRADING-SYSTEM-COMPLETE.ps1
```

Or use the simple launcher:
```powershell
.\START-EVERYTHING.bat
```

#### Step 6: Setup MQL5 EA

1. **Copy EA to MT5**:
   - Copy `trading-bridge/mql5/Experts/PythonBridgeEA.mq5` to:
     - `C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\`

2. **Compile in MetaEditor**:
   - Open MetaEditor
   - Open `PythonBridgeEA.mq5`
   - Press F7 to compile
   - Check for errors (should compile successfully)

3. **Attach to Chart**:
   - Open MT5 Terminal
   - Open a chart (e.g., EURUSD)
   - Drag `PythonBridgeEA` from Navigator to chart
   - Configure parameters:
     - BridgePort: `5555` (must match Python bridge)
     - BrokerName: `EXNESS`
     - AutoExecute: `true`
   - Click OK

4. **Verify Connection**:
   - Check EA logs in MT5 (View → Terminal → Experts tab)
   - Should see: "Bridge connection initialized on port 5555"
   - Check Python logs: `trading-bridge\logs\trading_service_*.log`

#### Step 7: Monitor System

**Check Status**:
```powershell
.\check-trading-status.ps1
```

**View Logs**:
```powershell
# Python service logs
Get-Content trading-bridge\logs\trading_service_*.log -Tail 50

# Orchestrator logs
Get-Content trading-bridge\logs\orchestrator_*.log -Tail 50
```

**Monitor Processes**:
```powershell
Get-Process python,terminal64 -ErrorAction SilentlyContinue | Format-Table ProcessName, Id, StartTime
```

---

## Quick Reference

### Drive Management Commands
```powershell
# Check setup status
.\check-oauth-setup.ps1

# Open OAuth setup pages
.\open-oauth-pages.ps1

# Test Google Drive
.\test-google-drive.ps1

# Test OneDrive
.\test-onedrive.ps1

# View help
python gdrive_cleanup.py --help
python dropbox_to_onedrive.py --help
```

### Trading System Configuration Files
- `trading-bridge/config/brokers.json` - Broker API configuration
- `trading-bridge/config/symbols.json` - Trading symbols configuration

### Trading System Scripts
- `START-TRADING-SYSTEM-COMPLETE.ps1` - Start everything
- `check-trading-status.ps1` - Check system status
- `verify-trading-config.ps1` - Verify configuration
- `install-trading-dependencies.ps1` - Install Python packages

### Ports
- **Python Bridge**: 5555 (ZeroMQ)
- **MQL5 EA**: 5555 (must match)

---

## Troubleshooting

### Google Drive Issues

**"credentials.json not found"**
- Run `.\auto-setup-helper.ps1` and complete Google OAuth setup
- Ensure `credentials.json` is in `J:\NUNA\`

**"403 Error" or "Permission denied"**
- Check that Google Drive API is enabled in Google Cloud Console
- Verify OAuth consent screen is configured
- Check that required scopes are added

### OneDrive Issues

**"ONEDRIVE_CLIENT_ID not set"**
- Set environment variable: `$env:ONEDRIVE_CLIENT_ID = "YOUR_CLIENT_ID"`
- Or run `.\setup-onedrive-oauth.ps1`

### Trading System Issues

**Python Service Not Starting**
```powershell
# Check logs
Get-Content trading-bridge\logs\trading_service_*.log -Tail 30

# Test import
cd trading-bridge\python
python -c "from services.background_service import BackgroundTradingService; print('OK')"
```

**MQL5 EA Not Connecting**
1. Verify Python bridge is running: `Get-Process python`
2. Check port matches (5555 in both EA and Python)
3. Check EA logs in MT5 Terminal
4. Verify firewall allows localhost:5555

---

## Documentation Files

### Drive Management
- `QUICK-START.md` - Quick reference guide
- `SETUP-OAUTH.md` - Detailed OAuth setup instructions
- `SETUP-COMPLETE.md` - Setup summary
- `README.md` - Original project documentation
- `guidebook/` - Detailed guides for each tool

### Trading System
- `trading-bridge/README.md` - Complete system documentation
- `trading-bridge/CONFIGURE-BROKERS.md` - Broker setup guide
- `TRADING-SYSTEM-COMPLETE-SUMMARY.md` - Implementation summary
- `VPS-SETUP-GUIDE.md` - VPS 24/7 trading system guide

---

## You're Ready!

Once OAuth is configured (for drive tools) and broker credentials are set (for trading), you can start using all the tools immediately. Start with dry-runs to see what the tools will do before making any changes!

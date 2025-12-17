# Trading System Quick Start Guide

## 🚀 Quick Start - Start Everything

### Option 1: Double-Click (Easiest)
**Double-click:** `START-EVERYTHING.bat`

### Option 2: PowerShell (Recommended)
```powershell
.\START-TRADING-SYSTEM-COMPLETE.ps1
```

### Option 3: Simple Start (No Admin)
```powershell
.\QUICK-START-SIMPLE.ps1
```

### Option 4: Full Setup with Admin
```powershell
.\QUICK-START-TRADING-SYSTEM.ps1
```
*(Requires admin - will auto-elevate)*

## ✅ What Gets Started

1. **Python Bridge Service** - MQL5 communication bridge
2. **MQL5 Terminal** - Exness MT5 Terminal
3. **Master Orchestrator** - Monitors and manages all services
4. **VPS Services** - Background services for 24/7 operation

## 📊 Check Status

```powershell
.\check-trading-status.ps1
```

## 📝 Logs

- **Python Bridge**: `trading-bridge\logs\mql5_bridge_*.log`
- **Trading Service**: `trading-bridge\logs\trading_service_*.log`
- **Orchestrator**: `trading-bridge\logs\orchestrator_*.log`

## 🔧 Configuration

### 1. Configure Brokers
- Copy `trading-bridge\config\brokers.json.example` to `trading-bridge\config\brokers.json`
- Edit with your broker API keys
- Store keys in Windows Credential Manager (secure)

### 2. Configure Symbols
- Copy `trading-bridge\config\symbols.json.example` to `trading-bridge\config\symbols.json`
- Add symbols you want to trade

### 3. Store Credentials
```powershell
# Using Python
python -c "from trading_bridge.python.security.credential_manager import CredentialManager; cm = CredentialManager(); cm.store_credential('EXNESS_API_KEY', 'your_key')"
```

## 🔄 Auto-Start on Boot

Run once to setup auto-start:
```powershell
.\setup-trading-auto-start.ps1
```

After this, the system will start automatically on every boot.

## 🛠️ Troubleshooting

### Python Service Not Starting
1. Check Python is installed: `python --version`
2. Install dependencies: `.\install-trading-dependencies.ps1`
3. Check logs: `trading-bridge\logs\`

### MQL5 Terminal Not Starting
1. Verify Exness Terminal is installed
2. Check path: `C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe`
3. Run manually: `.\launch-exness-trading.ps1`

### Services Not Detected
- Services run in hidden windows
- Check with: `.\check-trading-status.ps1`
- View processes: `Get-Process python,terminal64`

## 📋 Quick Commands

| Action | Command |
|--------|---------|
| Start Everything | `.\START-TRADING-SYSTEM-COMPLETE.ps1` |
| Check Status | `.\check-trading-status.ps1` |
| Install Dependencies | `.\install-trading-dependencies.ps1` |
| Setup Auto-Start | `.\setup-trading-auto-start.ps1` |
| Network Mapping | `.\setup-network-mapping.ps1` |
| Code Cleanup | `.\cleanup-code.ps1` |

## 🎯 Next Steps After Start

1. ✅ System is running
2. ⚙️ Configure `brokers.json` with your API keys
3. ⚙️ Configure `symbols.json` with trading symbols
4. ⚙️ Attach MQL5 EA to charts in MT5 Terminal
5. 📊 Monitor logs and status

## 🔒 Security

- All credentials stored in Windows Credential Manager
- Configuration files are gitignored
- Run security check: `.\security-check-trading.ps1`

---

**System Status**: Ready to trade after configuration
**Auto-Start**: Configured (runs on boot)
**Services**: Running in background


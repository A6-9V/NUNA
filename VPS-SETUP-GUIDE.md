# VPS 24/7 Trading System Setup Guide

Complete guide for deploying and running the 24/7 automated trading system on VPS.

## Overview

This system provides:
- ✅ **Exness MT5 Terminal** - Running 24/7 for automated trading
- ✅ **Web Research Automation** - Perplexity AI finance research (auto search and report)
- ✅ **GitHub Website** - ZOLO-A6-9VxNUNA running 24/7 in Firefox
- ✅ **CI/CD Automation** - Automated Python project execution
- ✅ **MQL5 Forge Integration** - https://forge.mql5.io/LengKundee/mql5
- ✅ **Scheduled Trading System** - Automated trading schedule setup

## Quick Start

### 1. Initial Deployment

Run the VPS deployment script (one-time setup):

```powershell
# Run as Administrator
.\vps-deployment.ps1
```

Or double-click: `START-VPS-SYSTEM.bat`

### 2. Start All Services

Start the complete system:

```powershell
# Run as Administrator
.\start-vps-system.ps1
```

Or double-click: `START-VPS-SYSTEM.bat`

### 3. Verify Everything is Running

Check all services:

```powershell
.\vps-verification.ps1
```

## System Components

### 1. Exness Trading Service
- **Location**: `vps-services\exness-service.ps1`
- **Function**: Keeps Exness MT5 Terminal running 24/7
- **Auto-restart**: Yes (checks every 5 minutes)
- **Logs**: `vps-logs\exness-service.log`

### 2. Web Research Service (Perplexity AI)
- **Location**: `vps-services\research-service.ps1`
- **Function**: Automated finance research on Perplexity AI
- **Schedule**: Every 6 hours
- **Queries**: 
  - Forex market analysis
  - Trading opportunities
  - Cryptocurrency trends
  - Stock market analysis
  - Economic calendar events
- **Logs**: `vps-logs\research-service.log`

### 3. GitHub Website Service
- **Location**: `vps-services\website-service.ps1`
- **Repository**: `git@github.com:Mouy-leng/ZOLO-A6-9VxNUNA-.git`
- **Function**: 
  - Clones/updates repository
  - Runs Python web server (port 8000)
  - Opens in Firefox
  - Auto-updates every hour
- **Logs**: `vps-logs\website-service.log`

### 4. CI/CD Automation Service
- **Location**: `vps-services\cicd-service.ps1`
- **Function**: 
  - Monitors GitHub repositories
  - Auto-runs Python projects
  - Installs dependencies (requirements.txt)
  - Runs every 30 minutes
- **Repositories**:
  - ZOLO-A6-9VxNUNA
  - my-drive-projects
- **Logs**: `vps-logs\cicd-service.log`

### 5. MQL5 Forge Integration
- **Location**: `vps-services\mql5-service.ps1`
- **URL**: https://forge.mql5.io/LengKundee/mql5
- **Function**: Opens MQL5 Forge in Firefox every 12 hours
- **Logs**: `vps-logs\mql5-service.log`

### 6. Master Controller
- **Location**: `vps-services\master-controller.ps1`
- **Function**: 
  - Starts all services
  - Monitors and restarts stopped services
  - Runs continuously
- **Logs**: `vps-logs\master-controller.log`

## Directory Structure

```
C:\Users\USER\OneDrive\
├── vps-services\              # Service scripts
│   ├── exness-service.ps1
│   ├── research-service.ps1
│   ├── website-service.ps1
│   ├── cicd-service.ps1
│   ├── mql5-service.ps1
│   └── master-controller.ps1
├── vps-logs\                  # Service logs
│   ├── exness-service.log
│   ├── research-service.log
│   ├── website-service.log
│   ├── cicd-service.log
│   ├── mql5-service.log
│   └── master-controller.log
├── ZOLO-A6-9VxNUNA\           # GitHub website repository
├── vps-deployment.ps1         # Deployment script
├── vps-verification.ps1       # Verification script
├── start-vps-system.ps1       # Startup script
└── START-VPS-SYSTEM.bat       # Batch launcher
```

## Manual Service Management

### Start Individual Service

```powershell
# Start Exness service
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
    "-ExecutionPolicy", "Bypass",
    "-File", "vps-services\exness-service.ps1"
)
```

### Stop Service

```powershell
# Stop all PowerShell services
Get-Process powershell | Where-Object { 
    $_.CommandLine -like "*vps-services*" 
} | Stop-Process
```

### View Logs

```powershell
# View Exness service log
Get-Content vps-logs\exness-service.log -Tail 50

# View all logs
Get-ChildItem vps-logs\*.log | ForEach-Object {
    Write-Host "`n=== $($_.Name) ===" -ForegroundColor Cyan
    Get-Content $_.FullName -Tail 20
}
```

## Scheduled Task (Auto-Start on Boot)

The deployment script creates a Windows Scheduled Task that automatically starts all services on system boot:

- **Task Name**: `VPS-Trading-System-24-7`
- **Trigger**: At startup
- **Action**: Runs `master-controller.ps1`
- **Restart**: Yes (up to 3 times)

### View Scheduled Task

```powershell
Get-ScheduledTask -TaskName "VPS-Trading-System-24-7"
```

### Remove Scheduled Task

```powershell
Unregister-ScheduledTask -TaskName "VPS-Trading-System-24-7" -Confirm:$false
```

## Troubleshooting

### Services Not Starting

1. Check if running as Administrator:
   ```powershell
   ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   ```

2. Check execution policy:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. Check logs for errors:
   ```powershell
   Get-Content vps-logs\master-controller.log -Tail 50
   ```

### Exness Terminal Not Running

1. Verify installation:
   ```powershell
   Test-Path "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
   ```

2. Manually start:
   ```powershell
   Start-Process "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
   ```

### Firefox Not Opening

1. Check Firefox installation:
   ```powershell
   Get-Command firefox -ErrorAction SilentlyContinue
   ```

2. Install Firefox if missing:
   - Download from: https://www.mozilla.org/firefox/

### GitHub Repository Issues

1. Check SSH keys:
   ```powershell
   ssh -T git@github.com
   ```

2. Use HTTPS instead:
   - Edit service scripts to use HTTPS URLs

### Python Projects Not Running

1. Check Python installation:
   ```powershell
   python --version
   ```

2. Install dependencies:
   ```powershell
   cd ZOLO-A6-9VxNUNA
   pip install -r requirements.txt
   ```

## Monitoring

### Real-time Service Status

```powershell
# Check all services
.\vps-verification.ps1

# Check specific process
Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
Get-Process -Name "firefox" -ErrorAction SilentlyContinue
Get-Process -Name "python" -ErrorAction SilentlyContinue
```

### Resource Usage

```powershell
# CPU and Memory usage
Get-Process | Where-Object { 
    $_.ProcessName -in @("terminal64", "firefox", "python", "powershell")
} | Select-Object ProcessName, CPU, WorkingSet | Format-Table
```

## Security Notes

- All services run with current user privileges
- Logs contain service activity (no sensitive data)
- GitHub credentials stored securely (not in scripts)
- Firewall rules may need adjustment for web services

## Maintenance

### Daily
- Check verification script output
- Review log files for errors

### Weekly
- Review service logs
- Update GitHub repositories
- Check disk space

### Monthly
- Review and optimize service schedules
- Update Python dependencies
- Backup configuration files

## Support

For issues or questions:
1. Check log files in `vps-logs\`
2. Run verification script: `.\vps-verification.ps1`
3. Review service scripts in `vps-services\`

---

**Created**: 2025-12-09  
**System**: NuNa (Windows 11 Home Single Language 25H2)  
**VPS**: 24/7 Trading System

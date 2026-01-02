# System Maintenance Guide

## Overview

This guide provides maintenance tasks and optimizations for keeping your system running smoothly.

## Regular Maintenance Tasks

### Daily
- ✅ System auto-starts on restart (configured)
- ✅ Services monitored by Master Controller
- ✅ Logs automatically maintained

### Weekly
- [ ] Review log files for errors
- [ ] Check disk space usage
- [ ] Verify all services are running
- [ ] Review browser data exports

### Monthly
- [ ] Clean up old log files (keep last 30 days)
- [ ] Review and organize Google Documents
- [ ] Check for system updates
- [ ] Verify network and firewall settings
- [ ] Review scheduled tasks

## System Optimization

### Disk Space Management

**Check Disk Space:**
```powershell
Get-PSDrive C | Select-Object Used, Free, @{Name='FreePercent';Expression={[math]::Round(($_.Free / ($_.Free + $_.Used)) * 100, 1)}}
```

**Clean Temporary Files:**
```powershell
# Clean Windows temp files
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
```

**Clean Old Log Files:**
```powershell
# Keep logs from last 30 days
$logDir = "C:\Users\USER\OneDrive\vps-logs"
$cutoffDate = (Get-Date).AddDays(-30)
Get-ChildItem $logDir -Filter "*.log" | Where-Object {$_.LastWriteTime -lt $cutoffDate} | Remove-Item
```

### Service Management

**Check Service Status:**
```powershell
.\vps-verification.ps1
```

**Restart Services:**
```powershell
.\auto-start-vps-admin.ps1
```

**View Service Logs:**
```powershell
Get-Content vps-logs\master-controller.log -Tail 20
```

### Network Optimization

**Test Network Connectivity:**
```powershell
Test-NetConnection -ComputerName google.com -Port 80
```

**Check Firewall Rules:**
```powershell
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Select-Object DisplayName, Enabled
```

### Browser Data Management

**Export Browser Data:**
```powershell
.\export-browser-data.ps1
```

**Location:** `Browser-Exports\`

### File Organization

**Organize Files for Google Docs:**
```powershell
.\convert-to-google-docs.ps1
```

**Location:** `Google-Documents\Organized\`

## Monitoring

### Key Metrics to Monitor

1. **Disk Space:** Keep at least 20% free
2. **Service Processes:** Should be stable (1-2 per service)
3. **Log File Sizes:** Monitor for excessive growth
4. **Network Connectivity:** Regular connectivity tests
5. **Service Uptime:** Check Master Controller logs

### Automated Monitoring

The Master Controller automatically:
- ✅ Monitors all services every 5 minutes
- ✅ Restarts stopped services
- ✅ Logs all activities
- ✅ Handles errors gracefully

## Troubleshooting

### Services Not Starting

1. Check Master Controller log:
   ```powershell
   Get-Content vps-logs\master-controller.log -Tail 20
   ```

2. Verify admin privileges:
   ```powershell
   ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   ```

3. Restart Master Controller:
   ```powershell
   .\auto-start-vps-admin.ps1
   ```

### Network Issues

1. Check network adapter:
   ```powershell
   Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}
   ```

2. Test connectivity:
   ```powershell
   Test-NetConnection -ComputerName 8.8.8.8 -Port 53
   ```

3. Check firewall:
   ```powershell
   Get-NetFirewallProfile | Select-Object Name, Enabled
   ```

### Disk Space Issues

1. Check disk usage:
   ```powershell
   Get-PSDrive C
   ```

2. Clean temp files:
   ```powershell
   CleanMgr.exe /d C:
   ```

3. Clean old logs:
   ```powershell
   # See log cleanup section above
   ```

## Best Practices

1. **Regular Backups:**
   - Browser data exported regularly
   - Important files in Google Documents
   - System configuration scripts saved

2. **Log Management:**
   - Review logs weekly
   - Clean old logs monthly
   - Monitor log file sizes

3. **Service Monitoring:**
   - Run verification script weekly
   - Check Master Controller logs
   - Verify all services running

4. **Network Security:**
   - Keep firewall enabled
   - Regular network checks
   - Update system regularly

5. **File Organization:**
   - Organize files regularly
   - Keep Google Documents updated
   - Export browser data monthly

## Quick Reference

### Status Check
```powershell
.\vps-verification.ps1
```

### Start System
```powershell
.\auto-start-vps-admin.ps1
```

### Check Network
```powershell
.\check-network-firewall.ps1
```

### Export Browser Data
```powershell
.\export-browser-data.ps1
```

### Organize Files
```powershell
.\convert-to-google-docs.ps1
```

## Maintenance Schedule

| Task | Frequency | Script |
|------|----------|--------|
| Service Verification | Weekly | `vps-verification.ps1` |
| Network Check | Monthly | `check-network-firewall.ps1` |
| Browser Data Export | Monthly | `export-browser-data.ps1` |
| Log Cleanup | Monthly | Manual cleanup |
| File Organization | As needed | `convert-to-google-docs.ps1` |

---

**Created:** 2025-12-17  
**System:** NuNa (Windows 11 Home Single Language 25H2)  
**Status:** Fully Operational ✅


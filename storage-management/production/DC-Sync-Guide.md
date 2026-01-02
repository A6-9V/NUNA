# Domain Controller Sync - Quick Reference Guide

## 🎯 Quick Start (Copy to Domain Controller)

### Step 1: Copy Script to Domain Controller
Transfer the `DC-Sync.ps1` script to your Domain Controller.

### Step 2: Run as Administrator
```powershell
# Right-click PowerShell -> "Run as Administrator"
```

### Step 3: Execute Commands

#### Safe Check Only (Recommended First)
```powershell
.\DC-Sync.ps1 -CheckOnly
```

#### Full Synchronization
```powershell
.\DC-Sync.ps1 -ForceSync
```

#### Complete Sync with Service Restart
```powershell
.\DC-Sync.ps1 -ForceSync -RestartServices
```

---

## 🔍 What Each Mode Does

### `-CheckOnly` (Safe Mode)
- ✅ Verifies machine is a Domain Controller
- ✅ Checks NTDS, DNS, W32Time, KDC, ADWS services
- ✅ Tests Windows Time synchronization
- ✅ Runs `repadmin /replsummary` for replication status
- ✅ Runs `dcdiag /v /c` for comprehensive health check
- ❌ **Makes NO changes**

### `-ForceSync` (Action Mode)
- ✅ Performs all checks above
- 🔄 Restarts Windows Time service if needed
- 🔄 Runs `w32tm /resync /rediscover`
- 🔄 Forces AD replication with `repadmin /syncall /AeD`
- 🔄 Re-checks replication status after sync

### `-RestartServices` (Full Reset)
- ✅ Performs all sync actions above
- 🔄 Restarts NTDS (Active Directory)
- 🔄 Restarts DNS service
- 🔄 Restarts Windows Time service

---

## 📋 Common Scenarios

### Scenario 1: Regular Health Check
```powershell
.\DC-Sync.ps1 -CheckOnly
```
**Use when:** Weekly maintenance, troubleshooting, or verifying DC health.

### Scenario 2: Replication Issues
```powershell
.\DC-Sync.ps1 -ForceSync
```
**Use when:** Users report login issues, AD changes not replicating, or time sync problems.

### Scenario 3: Major Issues
```powershell
.\DC-Sync.ps1 -ForceSync -RestartServices
```
**Use when:** Serious AD problems, after maintenance, or when other methods fail.
**⚠️ Warning:** Will briefly interrupt AD services.

---

## 📊 Understanding the Output

### ✅ Good Signs
- `✅ Confirmed: This is a Domain Controller`
- `NTDS Service: Running`
- `✅ Time service appears to be working`
- `✅ No obvious replication errors found`
- `✅ DC diagnostics completed successfully`

### ⚠️ Warning Signs
- `⚠️ Time service may have issues`
- `⚠️ Replication errors detected`
- `⚠️ DC diagnostic failures detected`

### ❌ Critical Issues
- `ERROR: This machine is not a Domain Controller`
- `NTDS Service: Stopped`
- `❌ Error checking replication`

---

## 🚨 Troubleshooting

### If Script Won't Run
```powershell
# Check execution policy
Get-ExecutionPolicy

# If restricted, temporarily allow
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Run script
.\DC-Sync.ps1 -CheckOnly
```

### If Not Domain Controller Error
```powershell
# Verify you're on the right machine
hostname
whoami
Get-WmiObject -Class Win32_ComputerSystem | Select Name, Domain, DomainRole
```

### If Services Won't Start
```powershell
# Check Windows Event Logs
Get-EventLog -LogName System -Newest 50 | Where-Object {$_.Source -like "*NTDS*" -or $_.Source -like "*DNS*"}
```

---

## 📝 Log Files

The script automatically creates detailed logs:
- **Default Location:** `C:\Temp\DC-Sync-YYYY-MM-DD_HH-mm-ss.log`
- **Custom Location:** Use `-LogPath` parameter

### View Recent Log
```powershell
# Find latest log
Get-ChildItem C:\Temp\DC-Sync-*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# View latest log
Get-Content (Get-ChildItem C:\Temp\DC-Sync-*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
```

---

## ⏰ Recommended Schedule

### Daily Health Check
```powershell
# Add to Task Scheduler
.\DC-Sync.ps1 -CheckOnly
```

### Weekly Sync
```powershell
# Scheduled maintenance
.\DC-Sync.ps1 -ForceSync
```

### Emergency Response
```powershell
# When problems occur
.\DC-Sync.ps1 -ForceSync -RestartServices
```

---

## 🔒 Security Notes

- ✅ Script requires Administrator privileges
- ✅ All actions are standard Microsoft AD tools
- ✅ Comprehensive logging for audit trails
- ✅ Safe mode available for read-only checks
- ⚠️ Service restarts may briefly interrupt authentication

---

## 📞 Support Commands

If you need to troubleshoot manually:

```powershell
# Check replication manually
repadmin /replsummary
repadmin /showrepl

# Check time sync manually
w32tm /query /status
w32tm /query /peers

# Check DC health manually
dcdiag /v
dcdiag /test:dns

# Check services manually
Get-Service NTDS, DNS, W32Time, Kdc, ADWS
```

---

**Created:** November 7, 2025
**Compatible:** Windows Server 2012+ Domain Controllers
**Requirements:** Administrator privileges, Domain Controller role
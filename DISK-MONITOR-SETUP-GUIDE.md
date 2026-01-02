# Disk Monitor & Daily Reboot Setup Guide

## Overview

This setup configures:
1. **Daily Reboot Schedule** - System reboots daily at 3:00 AM
2. **Startup Disk Health Monitor** - Automatically checks disk health when system starts
3. **Virus/Malware Awareness** - Monitors Disk 0 (Patriot P410 SSD) for suspicious activity

## Your Disk Configuration

### Disk 0 (Patriot P410 1TB SSD) - **CRITICAL MONITORING**
- **Capacity**: 932 GB
- **Drives**: C:, D:, G:
- **System Disk**: Yes
- **Page File**: Yes
- **Status**: ⚠️ **Low write speed detected (12.2 KB/s)** - This is being monitored

### Disk 1 (HIKSEMI SCSI Disk Device)
- **Capacity**: 477 GB
- **Drive**: H:
- **Type**: USB
- **Status**: Healthy

### Disk 2 (TOSHIBA MK5059GSXP)
- **Capacity**: 466 GB
- **Drives**: I:, J:, K:
- **Type**: USB
- **Status**: Healthy

## Setup Instructions

### Step 1: Run the Setup Script (As Administrator)

1. Right-click on `setup-startup-disk-monitor.ps1`
2. Select "Run with PowerShell" (or "Run as Administrator")
3. Click "Yes" when prompted for administrator privileges
4. The script will:
   - Create a startup task for disk monitoring
   - Create a daily reboot schedule (3:00 AM)
   - Configure all monitoring

### Step 2: Verify Setup

Open Task Scheduler and check:
- Task: `\SystemMaintenance\StartupDiskHealthMonitor`
- Task: `\SystemMaintenance\DailySystemReboot`

## Manual Operations

### Run Disk Health Check Manually

```powershell
# Basic check
.\disk-health-monitor.ps1

# Detailed check with virus scan
.\disk-health-monitor.ps1 -Detailed -ScanForViruses

# Export report
.\disk-health-monitor.ps1 -ExportReport
```

### Change Reboot Time

```powershell
# Set reboot to 2:00 AM
.\setup-daily-reboot.ps1 -RebootTime "02:00"
```

### Remove Scheduled Tasks

```powershell
# Remove all tasks
.\setup-startup-disk-monitor.ps1 -RemoveAll

# Or remove just reboot schedule
.\setup-daily-reboot.ps1 -RemoveSchedule
```

## What Gets Monitored

### Disk 0 (Patriot P410 SSD) - Critical Monitoring
- ✅ Health status
- ✅ Read/Write speeds (alerts if write speed < 100 KB/s)
- ✅ Disk space usage
- ✅ Suspicious executable file count
- ✅ Performance degradation detection

### All Disks
- ✅ Health status
- ✅ Operational status
- ✅ Free space monitoring
- ✅ Performance metrics

## Reports

Disk health reports are automatically generated at startup and saved to:
- Location: `OneDrive\disk-health-report-YYYYMMDD-HHMMSS.txt`

## Important Notes

### Disk 0 Write Speed Issue
Your Patriot P410 SSD shows very low write speed (12.2 KB/s). This could indicate:
- ⚠️ Hardware failure
- ⚠️ Malware/virus activity
- ⚠️ Disk corruption
- ⚠️ Driver issues

**Recommendation**: Run a full virus scan and check disk health:
```powershell
.\disk-health-monitor.ps1 -Detailed -ScanForViruses
```

### Daily Reboot
- System will show a 60-second warning before rebooting
- Reboot happens at 3:00 AM daily
- You can cancel the reboot during the 60-second window

## Troubleshooting

### Task Not Running
1. Check Task Scheduler: `taskschd.msc`
2. Verify task is enabled
3. Check task history for errors

### Disk Monitor Not Working
1. Run manually: `.\disk-health-monitor.ps1 -Detailed`
2. Check PowerShell execution policy
3. Verify script path is correct

### Reboot Not Happening
1. Check Task Scheduler for task status
2. Verify system time is correct
3. Check if system is in sleep/hibernate mode

## Files Created

1. `setup-daily-reboot.ps1` - Daily reboot scheduler
2. `disk-health-monitor.ps1` - Disk health monitoring script
3. `setup-startup-disk-monitor.ps1` - Complete setup script
4. `DISK-MONITOR-SETUP-GUIDE.md` - This guide

## Security Notes

- All scripts run with SYSTEM privileges (highest level)
- Disk monitoring includes virus/malware awareness
- Reports are saved to OneDrive for review
- No sensitive data is logged

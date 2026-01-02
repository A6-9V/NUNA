# Quick Setup Guide - Storage Management

## 🚨 CRITICAL: Your C: Drive is 93% Full!
**Immediate Action Required**: Your OS drive only has 7% free space (16GB). This can cause system instability.

### Immediate Actions (Do These Now!)

#### 1. Clean Up C: Drive Immediately
```powershell
# Run Disk Cleanup
cleanmgr /sageset:1

# Or use PowerShell to clear temp files
Get-ChildItem -Path $env:TEMP -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\Windows\Temp" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
```

#### 2. Run Your New Storage Monitor
```powershell
cd "H:\My Drive\storage-management"
.\monitor-storage.ps1
```

#### 3. Backup Your Dahua USB (While It Still Works)
```powershell
.\backup-dahua-usb.ps1 -Verify
```

## 📊 What We Found

| Drive               | Status     | Issue               | Action Needed        |
| ------------------- | ---------- | ------------------- | -------------------- |
| **C:** OS           | 🔴 CRITICAL | Only 7% free (16GB) | Clean up immediately |
| **D:** DATA         | ✅ Good     | 72% free            | Use for backups      |
| **G:** Google Drive | ⚠️ Warning  | FAT32, 15% free     | Consider cleanup     |
| **H:** Google Drive | ✅ OK       | FAT32, 51% free     | Convert to NTFS      |
| **I:** Dahua USB    | ⚠️ Slow     | FAT32, old USB      | Backup & optimize    |

## 🛠️ Your New Tools

### 1. Storage Monitor
```powershell
# Quick health check
.\monitor-storage.ps1

# Detailed analysis
.\monitor-storage.ps1 -ShowDetails

# Continuous monitoring
.\monitor-storage.ps1 -Continuous -IntervalSeconds 60
```

### 2. USB Backup Tool
```powershell
# Backup Dahua USB to safe location
.\backup-dahua-usb.ps1

# Backup with verification
.\backup-dahua-usb.ps1 -Verify
```

### 3. USB Optimizer
```powershell
# Preview what will happen (safe)
.\optimize-usb.ps1 -DriveLetter I -WhatIf

# Actually optimize (after backup!)
.\optimize-usb.ps1 -DriveLetter I -VolumeLabel "FAST_USB"
```

## 🎯 Recommended Workflow (Next 30 Minutes)

### Step 1: Emergency C: Drive Cleanup (5 minutes)
```powershell
# Quick temp file cleanup
Get-ChildItem -Path $env:TEMP -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
```

### Step 2: Backup Dahua USB (10 minutes)
```powershell
cd "H:\My Drive\storage-management"
.\backup-dahua-usb.ps1 -Verify
```

### Step 3: Verify Backup Worked (2 minutes)
```powershell
# Check backup was created
Get-ChildItem "H:\My Drive\USB-Backups\" | Sort-Object CreationTime -Descending | Select-Object -First 1
```

### Step 4: Optimize USB (5 minutes)
```powershell
# Format USB to NTFS for better performance
.\optimize-usb.ps1 -DriveLetter I -VolumeLabel "OPTIMIZED_USB"
```

### Step 5: Set Up Monitoring (3 minutes)
```powershell
# Create scheduled task for daily monitoring
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File 'H:\My Drive\storage-management\monitor-storage.ps1'"
$trigger = New-ScheduledTaskTrigger -Daily -At "9:00AM"
Register-ScheduledTask -TaskName "Daily Storage Check" -Action $action -Trigger $trigger
```

## 🔥 Performance Improvements Expected

After running these scripts:
- **USB Speed**: 3-5x faster (FAT32 → NTFS)
- **File Limits**: No more 4GB restriction
- **Reliability**: Better error handling and recovery
- **Monitoring**: Real-time health alerts
- **Safety**: Automatic backups before changes

## 🚀 Hardware Upgrade Path

Your current Dahua USB is working but outdated. Consider:

1. **Samsung T7 Portable SSD** (1TB) - $89
   - 20x faster than current USB
   - USB 3.2, 1050 MB/s speeds

2. **SanDisk Extreme Pro** (256GB) - $45  
   - 8x faster than current USB
   - Reliable, compact design

## 📞 Need Help?

### If backup fails:
```powershell
# Check what's using the drive
Get-Process | Where-Object { $_.Path -like "I:\*" }
```

### If format fails:
```powershell
# Force unmount and retry
Remove-PSDrive -Name I -Force -ErrorAction SilentlyContinue
.\optimize-usb.ps1 -DriveLetter I -Force
```

### Check script status:
```powershell
# View recent backups
Get-ChildItem "H:\My Drive\USB-Backups\" | Sort-Object CreationTime -Descending
```

---

**Created**: November 6, 2025  
**Priority**: 🔴 HIGH - C: drive critically low on space  
**Time to complete**: ~30 minutes  
**Risk level**: LOW (scripts have safety checks)
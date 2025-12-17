# I/O Redirection Setup Guide

## Overview

This system configures your drives for optimal I/O performance:

- **E: Drive**: Primary location for heavy I/O operations (read/write, startup, cache, logs)
- **USB Drives**: Secondary location when E: drive is full
- **C: Drive (OS)**: Protected from heavy I/O operations
- **D: Drive**: Protected from heavy I/O operations

## Quick Setup

### Step 1: Run the Setup Script (As Administrator)

```powershell
# Right-click and "Run as Administrator"
.\setup-startup-io-config.ps1
```

This will:
- ✅ Configure E: drive for I/O operations
- ✅ Detect and configure USB drives
- ✅ Create environment variables
- ✅ Set up startup tasks
- ✅ Create drive protection monitor

### Step 2: Restart Your Computer

After running the setup, restart to activate:
- Startup I/O configuration
- Drive protection monitoring
- Environment variables

## Directory Structure

After setup, E: drive will have:

```
E:\IO-Work\
├── Temp\          # Temporary files
├── Cache\          # Cache files
├── Logs\           # Application logs
├── Downloads\      # Download files
├── Backups\        # Backup files
├── Startup\        # Startup scripts and files
└── Projects\       # Project files
```

## Using I/O Redirection in Scripts

### Import the I/O Helper

```powershell
. .\io-redirection.ps1
```

### Get I/O Work Path

```powershell
# Get temp file path (automatically uses E: or USB)
$tempFile = Get-IOWorkPath -Type "Temp" -SubPath "myfile.txt"

# Get cache path
$cachePath = Get-IOWorkPath -Type "Cache" -SubPath "app-cache"

# Get logs path
$logPath = Get-IOWorkPath -Type "Logs" -SubPath "app.log"
```

### Check if Drive is Protected

```powershell
# Check if a path is on a protected drive
if (Test-ProtectedDrive -Path "C:\SomeFile.txt") {
    Write-Warning "This path is on a protected drive!"
    $newPath = Redirect-ToIODrive -OriginalPath "C:\SomeFile.txt" -Type "Temp"
}
```

### Redirect Protected Drive Operations

```powershell
# Automatically redirect if on protected drive
$safePath = Redirect-ToIODrive -OriginalPath "C:\HeavyOperation\file.dat" -Type "Temp"
# Will redirect to E:\IO-Work\Temp\file.dat
```

## Environment Variables

After setup, these environment variables are available:

- `IO_WORK_DIR` = `E:\IO-Work`
- `IO_TEMP_DIR` = `E:\IO-Work\Temp`
- `IO_CACHE_DIR` = `E:\IO-Work\Cache`
- `IO_LOGS_DIR` = `E:\IO-Work\Logs`
- `IO_DOWNLOADS_DIR` = `E:\IO-Work\Downloads`
- `IO_BACKUPS_DIR` = `E:\IO-Work\Backups`
- `IO_STARTUP_DIR` = `E:\IO-Work\Startup`
- `IO_PROJECTS_DIR` = `E:\IO-Work\Projects`
- `PROTECTED_DRIVES` = `C:,D:`
- `IO_DRIVES` = `E:`

### Using Environment Variables

```powershell
# Use environment variables
$tempDir = $env:IO_TEMP_DIR
$logDir = $env:IO_LOGS_DIR

# Or in batch files
echo %IO_TEMP_DIR%
```

## Drive Protection Monitoring

### Manual Monitoring

```powershell
# Run protection monitor
.\protect-cd-drives.ps1
```

This will:
- Monitor C: and D: drives for heavy I/O
- Alert when active time exceeds 70%
- Suggest using E: drive or USB drives
- Show real-time I/O statistics

### Automatic Monitoring

The setup creates a scheduled task that:
- Starts automatically at boot (2 minutes delay)
- Runs in background
- Monitors protected drives continuously
- Alerts when protection is needed

## Examples

### Example 1: Download File to I/O Drive

```powershell
. .\io-redirection.ps1

$downloadPath = Get-IOWorkPath -Type "Downloads" -SubPath "large-file.zip"
Invoke-WebRequest -Uri "https://example.com/file.zip" -OutFile $downloadPath
```

### Example 2: Create Temporary File

```powershell
. .\io-redirection.ps1

$tempFile = Get-IOWorkPath -Type "Temp" -SubPath "processing.dat"
# Use $tempFile for heavy I/O operations
```

### Example 3: Log File on I/O Drive

```powershell
. .\io-redirection.ps1

$logFile = Get-IOWorkPath -Type "Logs" -SubPath "app-$(Get-Date -Format 'yyyy-MM-dd').log"
Add-Content -Path $logFile -Value "Application started"
```

### Example 4: Protect Existing Script

```powershell
. .\io-redirection.ps1

# Original path (might be on C: or D:)
$originalPath = "C:\MyApp\cache\data.bin"

# Check and redirect if needed
$safePath = Redirect-ToIODrive -OriginalPath $originalPath -Type "Cache"

# Use safe path for I/O operations
Copy-Item -Path $source -Destination $safePath
```

## Troubleshooting

### E: Drive Not Found

If E: drive is not available:
- Scripts will automatically use USB drives
- If no USB drives available, will use system temp (with warning)

### USB Drive Not Detected

- Ensure USB drive is properly connected
- Check if drive has at least 1GB free space
- USB drives are automatically detected when available

### Protected Drive Still Getting Heavy I/O

1. Check if protection monitor is running:
   ```powershell
   Get-ScheduledTask -TaskName "SystemMaintenance\DriveProtectionMonitor"
   ```

2. Manually run protection monitor:
   ```powershell
   .\protect-cd-drives.ps1
   ```

3. Check which processes are using protected drives:
   ```powershell
   Get-Process | Where-Object { $_.Path -like "C:\*" -or $_.Path -like "D:\*" }
   ```

## Scheduled Tasks

After setup, these tasks are created:

1. **StartupIOConfiguration**
   - Runs at system startup
   - Configures I/O redirection
   - Sets up environment

2. **DriveProtectionMonitor**
   - Runs at startup (2 min delay)
   - Monitors C: and D: drives
   - Alerts on heavy I/O

### View Tasks

```powershell
Get-ScheduledTask -TaskName "SystemMaintenance\*"
```

### Remove Tasks

```powershell
Unregister-ScheduledTask -TaskName "SystemMaintenance\StartupIOConfiguration" -Confirm:$false
Unregister-ScheduledTask -TaskName "SystemMaintenance\DriveProtectionMonitor" -Confirm:$false
```

## Best Practices

1. **Always use I/O helper functions** for heavy operations
2. **Check drive protection** before writing large files
3. **Monitor protected drives** regularly
4. **Use environment variables** for paths
5. **Keep E: drive** with at least 10GB free space
6. **Use USB drives** as backup when E: is full

## Summary

✅ **E: Drive**: Primary I/O location  
✅ **USB Drives**: Secondary I/O location  
✅ **C: & D: Drives**: Protected from heavy I/O  
✅ **Automatic**: Setup runs at startup  
✅ **Monitoring**: Continuous protection monitoring  

Your system is now configured for optimal I/O performance while protecting your OS and data drives!


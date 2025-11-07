# Dahua USB Backup Script
# Safely backs up all data from Dahua USB to your main drive
# Created: November 6, 2025

param(
    [string]$SourceDrive = "I:\",
    [string]$BackupLocation = "H:\My Drive\USB-Backups\Dahua-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')",
    [switch]$Verify
)

Write-Host "=== Dahua USB Backup Script ===" -ForegroundColor Green
Write-Host "Source: $SourceDrive" -ForegroundColor Yellow
Write-Host "Destination: $BackupLocation" -ForegroundColor Yellow

# Create backup directory
if (!(Test-Path $BackupLocation)) {
    New-Item -ItemType Directory -Path $BackupLocation -Force
    Write-Host "Created backup directory: $BackupLocation" -ForegroundColor Green
}

# Get source drive info
try {
    $driveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $SourceDrive.TrimEnd('\') + ':' }
    $totalSize = [math]::Round($driveInfo.Size / 1GB, 2)
    $freeSpace = [math]::Round($driveInfo.FreeSpace / 1GB, 2)
    $usedSpace = $totalSize - $freeSpace
    
    Write-Host "Drive Info: $($driveInfo.VolumeName) - Total: ${totalSize}GB, Used: ${usedSpace}GB, Free: ${freeSpace}GB" -ForegroundColor Cyan
} catch {
    Write-Host "Warning: Could not get drive information" -ForegroundColor Yellow
}

# Start backup with progress
Write-Host "Starting backup..." -ForegroundColor Green
$startTime = Get-Date

try {
    # Use robocopy for reliable copying
    $robocopyArgs = @(
        $SourceDrive,
        $BackupLocation,
        "/E",           # Copy subdirectories including empty ones
        "/COPY:DAT",    # Copy Data, Attributes, Timestamps
        "/R:3",         # Retry 3 times on failed copies
        "/W:10",        # Wait 10 seconds between retries
        "/MT:8",        # Multi-threaded (8 threads)
        "/XD", "System Volume Information", # Exclude system folder
        "/XF", "*.tmp", "*.temp",           # Exclude temp files
        "/V",           # Verbose output
        "/ETA"          # Show estimated time
    )
    
    $result = & robocopy @robocopyArgs
    $exitCode = $LASTEXITCODE
    
    # Robocopy exit codes: 0-1 success, 2-7 warnings, 8+ errors
    if ($exitCode -le 1) {
        Write-Host "Backup completed successfully!" -ForegroundColor Green
    } elseif ($exitCode -le 7) {
        Write-Host "Backup completed with warnings (exit code: $exitCode)" -ForegroundColor Yellow
    } else {
        Write-Host "Backup completed with errors (exit code: $exitCode)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error during backup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Backup completed in: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green

# Verification if requested
if ($Verify) {
    Write-Host "Starting verification..." -ForegroundColor Yellow
    $sourceFiles = Get-ChildItem -Path $SourceDrive -Recurse -File -ErrorAction SilentlyContinue
    $backupFiles = Get-ChildItem -Path $BackupLocation -Recurse -File -ErrorAction SilentlyContinue
    
    Write-Host "Source files: $($sourceFiles.Count)" -ForegroundColor Cyan
    Write-Host "Backup files: $($backupFiles.Count)" -ForegroundColor Cyan
    
    if ($sourceFiles.Count -eq $backupFiles.Count) {
        Write-Host "File count verification: PASSED" -ForegroundColor Green
    } else {
        Write-Host "File count verification: FAILED" -ForegroundColor Red
    }
}

# Create backup log
$logContent = @"
Dahua USB Backup Log
===================
Date: $(Get-Date)
Source: $SourceDrive
Destination: $BackupLocation
Duration: $($duration.ToString('hh\:mm\:ss'))
Exit Code: $exitCode
Status: $(if ($exitCode -le 1) { "Success" } elseif ($exitCode -le 7) { "Warning" } else { "Error" })

Drive Information:
- Volume Name: $($driveInfo.VolumeName)
- Total Size: ${totalSize}GB
- Used Space: ${usedSpace}GB
- Free Space: ${freeSpace}GB
- File System: $($driveInfo.FileSystem)
"@

$logPath = Join-Path $BackupLocation "backup-log.txt"
$logContent | Out-File -FilePath $logPath -Encoding UTF8
Write-Host "Backup log saved to: $logPath" -ForegroundColor Green

Write-Host "=== Backup Complete ===" -ForegroundColor Green
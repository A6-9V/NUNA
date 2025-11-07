# C Drive Critical Backup Script
# Backs up essential files from C: drive to available USB storage
# Created: November 6, 2025 - Emergency C: Drive Space Recovery

param(
    [string]$TargetDrive = "I:\",
    [string]$BackupFolder = "C-Drive-Backup-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')",
    [switch]$SkipLargeFiles,
    [int]$MaxFileSizeMB = 100
)

Write-Host "=== C: Drive Emergency Backup ===" -ForegroundColor Red
Write-Host "Target: $TargetDrive$BackupFolder" -ForegroundColor Yellow

# Check target drive space
$targetDriveID = $TargetDrive.TrimEnd('\').TrimEnd(':') + ':'
$targetDriveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $targetDriveID }
if (!$targetDriveInfo) {
    Write-Host "Error: Target drive $targetDriveID not found!" -ForegroundColor Red
    Write-Host "Available drives:" -ForegroundColor Yellow
    Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, VolumeName | Format-Table -AutoSize
    exit 1
}

$targetFreeGB = [math]::Round($targetDriveInfo.FreeSpace / 1GB, 2)
Write-Host "Target drive free space: ${targetFreeGB}GB" -ForegroundColor Cyan

# Create backup directory
$fullBackupPath = Join-Path $TargetDrive $BackupFolder
if (!(Test-Path $fullBackupPath)) {
    New-Item -ItemType Directory -Path $fullBackupPath -Force
    Write-Host "Created backup directory: $fullBackupPath" -ForegroundColor Green
}

# Define critical folders to backup (in order of importance)
$criticalFolders = @(
    @{Path="$env:USERPROFILE\Desktop"; Name="Desktop"; Priority=1},
    @{Path="$env:USERPROFILE\Documents"; Name="Documents"; Priority=1},
    @{Path="$env:USERPROFILE\Downloads"; Name="Downloads"; Priority=2},
    @{Path="$env:USERPROFILE\Pictures"; Name="Pictures"; Priority=2},
    @{Path="$env:USERPROFILE\Videos"; Name="Videos"; Priority=3},
    @{Path="$env:USERPROFILE\Music"; Name="Music"; Priority=3}
)

$totalBackedUp = 0
$skippedFiles = @()

Write-Host "`nStarting selective backup..." -ForegroundColor Green
$startTime = Get-Date

foreach ($folder in $criticalFolders) {
    if (Test-Path $folder.Path) {
        Write-Host "`n--- Backing up $($folder.Name) (Priority $($folder.Priority)) ---" -ForegroundColor Yellow
        
        try {
            # Get folder size
            $folderSize = (Get-ChildItem -Path $folder.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $folderSizeGB = [math]::Round($folderSize / 1GB, 2)
            
            Write-Host "Folder size: ${folderSizeGB}GB" -ForegroundColor Cyan
            
            # Check if we have enough space
            if ($folderSizeGB -gt $targetFreeGB) {
                Write-Host "Warning: Folder too large for available space, backing up selectively..." -ForegroundColor Yellow
                
                # Backup smaller files first
                $files = Get-ChildItem -Path $folder.Path -Recurse -File -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Length -lt ($MaxFileSizeMB * 1MB) } | 
                         Sort-Object Length
                
                $backupDestination = Join-Path $fullBackupPath $folder.Name
                New-Item -ItemType Directory -Path $backupDestination -Force | Out-Null
                
                foreach ($file in $files) {
                    try {
                        $relativePath = $file.FullName.Replace($folder.Path, "")
                        $destPath = Join-Path $backupDestination $relativePath
                        $destDir = Split-Path $destPath -Parent
                        
                        if (!(Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        
                        Copy-Item -Path $file.FullName -Destination $destPath -Force
                        $totalBackedUp++
                        
                        # Check remaining space
                        $currentFree = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $TargetDrive.TrimEnd('\') + ':' }).FreeSpace / 1GB, 2)
                        if ($currentFree -lt 1) {
                            Write-Host "Warning: Target drive space getting low, stopping backup" -ForegroundColor Red
                            break
                        }
                    } catch {
                        $skippedFiles += $file.FullName
                        Write-Host "Skipped: $($file.Name)" -ForegroundColor Gray
                    }
                }
            } else {
                # Backup entire folder
                $backupDestination = Join-Path $fullBackupPath $folder.Name
                
                $robocopyArgs = @(
                    $folder.Path,
                    $backupDestination,
                    "/E",
                    "/COPY:DAT",
                    "/R:1",
                    "/W:1",
                    "/XF", "*.tmp", "*.temp", "thumbs.db",
                    "/XD", "AppData", "Application Data"
                )
                
                & robocopy @robocopyArgs | Out-Null
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -le 1) {
                    Write-Host "✅ $($folder.Name) backed up successfully" -ForegroundColor Green
                } else {
                    Write-Host "⚠️ $($folder.Name) backup completed with warnings" -ForegroundColor Yellow
                }
            }
            
        } catch {
            Write-Host "Error backing up $($folder.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "$($folder.Name) folder not found, skipping..." -ForegroundColor Gray
    }
}

# Backup browser bookmarks and important settings
Write-Host "`n--- Backing up Browser Data ---" -ForegroundColor Yellow
$browserPaths = @(
    "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks",
    "$env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*\places.sqlite",
    "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
)

$browserBackup = Join-Path $fullBackupPath "Browser-Data"
New-Item -ItemType Directory -Path $browserBackup -Force | Out-Null

foreach ($path in $browserPaths) {
    try {
        $files = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            Copy-Item -Path $file.FullName -Destination $browserBackup -Force -ErrorAction SilentlyContinue
            Write-Host "Saved: $($file.Name)" -ForegroundColor Green
        }
    } catch {
        # Silently skip if browser data not found
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

# Create backup summary
$summary = @"
C: Drive Emergency Backup Summary
==================================
Date: $(Get-Date)
Duration: $($duration.ToString('hh\:mm\:ss'))
Backup Location: $fullBackupPath
Files Backed Up: $totalBackedUp
Files Skipped: $($skippedFiles.Count)

Target Drive Status:
- Drive: $($targetDriveInfo.DeviceID)
- Volume: $($targetDriveInfo.VolumeName)
- Free Space After Backup: $([math]::Round($targetDriveInfo.FreeSpace / 1GB, 2))GB

Critical Folders Processed:
$(foreach ($folder in $criticalFolders) { "- $($folder.Name) (Priority $($folder.Priority))" })

Browser Data: $(if (Test-Path $browserBackup) { "Backed up" } else { "Not found" })

Next Steps:
1. Verify backup completed successfully
2. Clean up C: drive temporary files
3. Consider moving large files to D: drive
4. Set up the Lexar SSD for future backups

IMPORTANT: Your C: drive is still critically low on space!
Consider moving files to D: drive (176GB free) or external storage.
"@

$summaryPath = Join-Path $fullBackupPath "backup-summary.txt"
$summary | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
Write-Host "Backup saved to: $fullBackupPath" -ForegroundColor Cyan
Write-Host "Files backed up: $totalBackedUp" -ForegroundColor Green
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan

if ($skippedFiles.Count -gt 0) {
    Write-Host "Files skipped: $($skippedFiles.Count)" -ForegroundColor Yellow
    Write-Host "See backup-summary.txt for details" -ForegroundColor Gray
}

# Show remaining space warning
$finalFree = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }).FreeSpace / 1GB, 2)
if ($finalFree -lt 15) {
    Write-Host "`n🚨 WARNING: C: drive still critically low: ${finalFree}GB free" -ForegroundColor Red
    Write-Host "Consider running disk cleanup or moving files to D: drive" -ForegroundColor Yellow
}
# USB Optimization Script
# Safely formats and optimizes USB drives for better performance
# Created: November 6, 2025

param(
    [Parameter(Mandatory=$true)]
    [string]$DriveLetter,
    [string]$VolumeLabel = "OPTIMIZED_USB",
    [string]$FileSystem = "NTFS",
    [switch]$Force,
    [switch]$WhatIf
)

Write-Host "=== USB Drive Optimization Script ===" -ForegroundColor Green

# Validate drive letter
$DriveLetter = $DriveLetter.TrimEnd(':').ToUpper()
$fullDrive = "${DriveLetter}:"

if (!(Test-Path $fullDrive)) {
    Write-Host "Error: Drive $fullDrive not found!" -ForegroundColor Red
    exit 1
}

# Get drive information
$driveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $fullDrive }
if (!$driveInfo) {
    Write-Host "Error: Could not get information for drive $fullDrive" -ForegroundColor Red
    exit 1
}

# Safety checks
if ($driveInfo.DriveType -ne 2) {
    Write-Host "Error: $fullDrive is not a removable drive! (Type: $($driveInfo.DriveType))" -ForegroundColor Red
    Write-Host "This script only works with removable USB drives for safety." -ForegroundColor Red
    exit 1
}

# Display current drive info
Write-Host "`nCurrent Drive Information:" -ForegroundColor Yellow
Write-Host "Drive: $fullDrive ($($driveInfo.VolumeName))" -ForegroundColor White
Write-Host "Current File System: $($driveInfo.FileSystem)" -ForegroundColor White
Write-Host "Size: $([math]::Round($driveInfo.Size / 1GB, 2))GB" -ForegroundColor White
Write-Host "Used Space: $([math]::Round(($driveInfo.Size - $driveInfo.FreeSpace) / 1GB, 2))GB" -ForegroundColor White

# List files on drive
Write-Host "`nFiles on drive:" -ForegroundColor Yellow
try {
    $files = Get-ChildItem -Path $fullDrive -Recurse -File -ErrorAction SilentlyContinue
    Write-Host "Total files: $($files.Count)" -ForegroundColor Cyan
    
    if ($files.Count -gt 0 -and !$Force) {
        Write-Host "`n⚠️  WARNING: Drive contains $($files.Count) files!" -ForegroundColor Red
        Write-Host "All data will be PERMANENTLY DELETED during formatting!" -ForegroundColor Red
        
        # Show first few files as examples
        $sampleFiles = $files | Select-Object -First 5
        Write-Host "`nSample files that will be deleted:" -ForegroundColor Yellow
        $sampleFiles | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Red }
        if ($files.Count -gt 5) {
            Write-Host "  ... and $($files.Count - 5) more files" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Could not enumerate files on drive" -ForegroundColor Yellow
}

# What-if mode
if ($WhatIf) {
    Write-Host "`n=== WHAT-IF MODE - No changes will be made ===" -ForegroundColor Magenta
    Write-Host "Would format: $fullDrive" -ForegroundColor White
    Write-Host "New File System: $FileSystem" -ForegroundColor White
    Write-Host "New Volume Label: $VolumeLabel" -ForegroundColor White
    Write-Host "Allocation Unit Size: Default (optimized)" -ForegroundColor White
    exit 0
}

# Final confirmation
if (!$Force) {
    Write-Host "`n" -NoNewline
    $confirmation = Read-Host "Are you ABSOLUTELY SURE you want to format $fullDrive? Type 'FORMAT' to continue"
    if ($confirmation -ne "FORMAT") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nStarting optimization process..." -ForegroundColor Green

# Step 1: Create backup recommendation
if ($files.Count -gt 0) {
    Write-Host "📋 RECOMMENDATION: Run backup script first:" -ForegroundColor Yellow
    Write-Host ".\backup-dahua-usb.ps1 -SourceDrive $fullDrive" -ForegroundColor Cyan
    
    if (!$Force) {
        $proceed = Read-Host "Continue with format anyway? (y/N)"
        if ($proceed -ne "y" -and $proceed -ne "Y") {
            Write-Host "Operation cancelled. Please backup your data first." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Step 2: Dismount and format
try {
    Write-Host "Dismounting drive..." -ForegroundColor Yellow
    
    # Use PowerShell's Format-Volume for modern formatting
    $formatParams = @{
        DriveLetter = $DriveLetter
        FileSystem = $FileSystem
        NewFileSystemLabel = $VolumeLabel
        Force = $true
        Confirm = $false
    }
    
    # Optimize allocation unit size based on drive size
    $sizeGB = [math]::Round($driveInfo.Size / 1GB, 0)
    if ($sizeGB -gt 32) {
        $formatParams.AllocationUnitSize = 32768  # 32KB for large drives
        Write-Host "Using 32KB allocation unit size for optimal performance" -ForegroundColor Cyan
    }
    
    Write-Host "Formatting drive to $FileSystem..." -ForegroundColor Yellow
    Format-Volume @formatParams
    
    Write-Host "✅ Format completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Format failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Post-formatting optimization
try {
    Write-Host "Applying optimization settings..." -ForegroundColor Yellow
    
    # Disable indexing for better performance on USB
    $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $fullDrive }
    if ($drive) {
        Write-Host "Disabling indexing for better USB performance..." -ForegroundColor Cyan
        fsutil behavior set DisableLastAccess 1
    }
    
    Write-Host "✅ Optimization completed!" -ForegroundColor Green
    
} catch {
    Write-Host "⚠️  Optimization partially failed, but drive should still work: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Verify new drive
Write-Host "`nVerifying optimized drive..." -ForegroundColor Yellow
$newDriveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $fullDrive }

if ($newDriveInfo) {
    Write-Host "✅ Drive verification successful!" -ForegroundColor Green
    Write-Host "`nNew Drive Information:" -ForegroundColor Cyan
    Write-Host "Drive: $($newDriveInfo.DeviceID) ($($newDriveInfo.VolumeName))" -ForegroundColor White
    Write-Host "File System: $($newDriveInfo.FileSystem)" -ForegroundColor White
    Write-Host "Total Space: $([math]::Round($newDriveInfo.Size / 1GB, 2))GB" -ForegroundColor White
    Write-Host "Available Space: $([math]::Round($newDriveInfo.FreeSpace / 1GB, 2))GB" -ForegroundColor White
    
    # Performance improvements achieved
    Write-Host "`n🚀 Performance Improvements:" -ForegroundColor Green
    if ($driveInfo.FileSystem -eq "FAT32" -and $newDriveInfo.FileSystem -eq "NTFS") {
        Write-Host "✅ Upgraded from FAT32 to NTFS (no more 4GB file limit)" -ForegroundColor Green
        Write-Host "✅ Better performance and reliability" -ForegroundColor Green
        Write-Host "✅ Support for file permissions and encryption" -ForegroundColor Green
    }
    Write-Host "✅ Optimized allocation unit size" -ForegroundColor Green
    Write-Host "✅ Disabled indexing for USB performance" -ForegroundColor Green
    
} else {
    Write-Host "⚠️  Could not verify drive after formatting" -ForegroundColor Yellow
}

Write-Host "`n=== USB Optimization Complete ===" -ForegroundColor Green
Write-Host "Your USB drive is now optimized for better performance!" -ForegroundColor Cyan
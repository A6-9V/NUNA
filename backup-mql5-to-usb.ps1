#Requires -Version 5.1
<#
.SYNOPSIS
    Backup MQL5 Repository to USB Flash Drive
.DESCRIPTION
    This script backs up the MQL5 repository to a USB flash drive for portability and backup purposes.
    It automatically detects USB drives and syncs the MQL5 repository.
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MQL5 USB Backup Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$workspaceRoot = "C:\Users\USER\OneDrive"
$mql5RepoPath = Join-Path $workspaceRoot "mql5-repo"
$usbSupportScript = Join-Path $workspaceRoot "vps-services\usb-support.ps1"

# Load USB support functions
if (Test-Path $usbSupportScript) {
    . $usbSupportScript
} else {
    Write-Host "[ERROR] USB support script not found: $usbSupportScript" -ForegroundColor Red
    exit 1
}

# Check if MQL5 repository exists
if (-not (Test-Path $mql5RepoPath)) {
    Write-Host "[ERROR] MQL5 repository not found: $mql5RepoPath" -ForegroundColor Red
    Write-Host "[INFO] Please ensure the MQL5 repository has been cloned first." -ForegroundColor Yellow
    exit 1
}

# Detect USB drives
Write-Host "[1/4] Detecting USB drives..." -ForegroundColor Yellow
$usbDrives = Get-USBDrives

if ($usbDrives.Count -eq 0) {
    Write-Host "    [ERROR] No USB drives detected" -ForegroundColor Red
    Write-Host "    [INFO] Please insert a USB flash drive and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "    [OK] Found $($usbDrives.Count) USB drive(s):" -ForegroundColor Green
foreach ($drive in $usbDrives) {
    Write-Host "      - $($drive.DriveLetter) ($($drive.VolumeLabel)) - $($drive.FreeSpace)GB free" -ForegroundColor Cyan
}

# Get preferred USB drive
Write-Host ""
Write-Host "[2/4] Selecting USB drive..." -ForegroundColor Yellow
$usbDrive = Get-PreferredUSBDrive -MinFreeSpaceGB 1

if (-not $usbDrive) {
    Write-Host "    [ERROR] No suitable USB drive found (need at least 1GB free space)" -ForegroundColor Red
    exit 1
}

Write-Host "    [OK] Selected USB drive: $($usbDrive.DriveLetter) ($($usbDrive.VolumeLabel))" -ForegroundColor Green
Write-Host "      Free space: $($usbDrive.FreeSpace)GB" -ForegroundColor Cyan

# Initialize USB for MQL5
Write-Host ""
Write-Host "[3/4] Initializing USB drive for MQL5 support..." -ForegroundColor Yellow
$usbMQL5Path = Join-Path $usbDrive.Path "MQL5-Support\mql5-repo"

if (Initialize-USBForMQL5 -USBDrivePath $usbDrive.Path) {
    Write-Host "    [OK] USB drive initialized successfully" -ForegroundColor Green
} else {
    Write-Host "    [ERROR] Failed to initialize USB drive" -ForegroundColor Red
    exit 1
}

# Sync MQL5 repository to USB
Write-Host ""
Write-Host "[4/4] Syncing MQL5 repository to USB..." -ForegroundColor Yellow
Write-Host "    Source: $mql5RepoPath" -ForegroundColor Cyan
Write-Host "    Destination: $usbMQL5Path" -ForegroundColor Cyan
Write-Host ""

if (Sync-MQL5ToUSB -SourceRepoPath $mql5RepoPath -USBDestinationPath $usbMQL5Path -CreateBackup) {
    Write-Host "    [OK] MQL5 repository synced to USB successfully" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] Sync completed with warnings" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "USB Drive: $($usbDrive.DriveLetter) ($($usbDrive.VolumeLabel))" -ForegroundColor White
Write-Host "MQL5 Repository Location: $usbMQL5Path" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Safely eject the USB drive when ready" -ForegroundColor White
Write-Host "  2. The MQL5 repository is now available on USB for portability" -ForegroundColor White
Write-Host "  3. Services will automatically sync to USB when available" -ForegroundColor White
Write-Host ""

# Open USB folder
try {
    $usbSupportPath = Join-Path $usbDrive.Path "MQL5-Support"
    if (Test-Path $usbSupportPath) {
        Write-Host "Opening USB MQL5 Support folder..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList $usbSupportPath
    }
} catch {
    Write-Host "[WARNING] Could not open USB folder" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green


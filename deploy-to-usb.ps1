#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy All Important Scripts to USB Flash Drive
.DESCRIPTION
    Copies all critical trading system scripts to USB drive for portable deployment
    Creates quick start files and organizes everything for easy execution
#>

param(
    [string]$USBDrive = "",
    [switch]$TestOnly
)

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  USB Deployment Package Creator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Detect USB drives
function Get-USBDrives {
    $usbDrives = @()
    try {
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
        foreach ($drive in $drives) {
            $usbInfo = @{
                DriveLetter = $drive.DeviceID.TrimEnd(':')
                Path = $drive.DeviceID
                VolumeLabel = $drive.VolumeName
                FreeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
                TotalSize = [math]::Round($drive.Size / 1GB, 2)
            }
            $usbDrives += $usbInfo
        }
    } catch {
        Write-Host "[ERROR] Failed to detect USB drives: $_" -ForegroundColor Red
    }
    return $usbDrives
}

# List of important scripts to copy
$importantScripts = @(
    # Disk Performance Monitoring
    "monitor-disk-performance.ps1",
    "setup-disk-performance-monitor.ps1",
    "ensure-trading-priority.ps1",
    "QUICK-SETUP-DISK-MONITOR.bat",
    "DISK-PERFORMANCE-MONITOR-GUIDE.md",
    
    # Trading System Core
    "master-trading-orchestrator.ps1",
    "check-trading-status.ps1",
    "QUICK-START-TRADING-SYSTEM.ps1",
    "QUICK-START-TRADING-SYSTEM.bat",
    "QUICK-START-SIMPLE.ps1",
    "launch-exness-trading.ps1",
    "LAUNCH-EXNESS-TRADING.bat",
    
    # System Setup
    "setup-trading-system.ps1",
    "setup-trading-auto-start.ps1",
    "verify-trading-system.ps1",
    
    # Git & Repository Management
    "auto-git-push.ps1",
    "push-to-all-repos.ps1",
    "review-and-push-all-repos.ps1",
    
    # System Maintenance
    "disk-health-monitor.ps1",
    "setup-startup-disk-monitor.ps1",
    "system-status-report.ps1",
    
    # Documentation
    "README.md",
    "TRADING-SYSTEM-QUICK-START.md",
    "SYSTEM-INFO.md",
    "AUTOMATION-RULES.md"
)

# Detect USB drives
Write-Host "[1/6] Detecting USB drives..." -ForegroundColor Yellow
$usbDrives = Get-USBDrives

if ($usbDrives.Count -eq 0) {
    Write-Host "[ERROR] No USB drives detected!" -ForegroundColor Red
    Write-Host "[INFO] Please insert a USB flash drive and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Found $($usbDrives.Count) USB drive(s):" -ForegroundColor Green
foreach ($drive in $usbDrives) {
    Write-Host "  - $($drive.DriveLetter): ($($drive.VolumeLabel)) - $($drive.FreeSpace)GB free / $($drive.TotalSize)GB total" -ForegroundColor Cyan
}

# Select USB drive
$selectedUSB = $null
if ($USBDrive) {
    $selectedUSB = $usbDrives | Where-Object { $_.DriveLetter -eq $USBDrive.TrimEnd(':') }
    if (-not $selectedUSB) {
        Write-Host "[WARNING] Specified drive $USBDrive not found, selecting best available..." -ForegroundColor Yellow
    }
}

if (-not $selectedUSB) {
    # Select drive with most free space (minimum 2GB)
    $selectedUSB = $usbDrives | Where-Object { $_.FreeSpace -ge 2 } | Sort-Object FreeSpace -Descending | Select-Object -First 1
}

if (-not $selectedUSB) {
    Write-Host "[ERROR] No USB drive with sufficient free space (need at least 2GB)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/6] Selected USB drive: $($selectedUSB.DriveLetter): ($($selectedUSB.VolumeLabel))" -ForegroundColor Green
Write-Host "      Free space: $($selectedUSB.FreeSpace)GB" -ForegroundColor Cyan

# Create deployment directory on USB
$usbDeployPath = Join-Path $selectedUSB.Path "Trading-System-Deployment"
$usbScriptsPath = Join-Path $usbDeployPath "Scripts"
$usbDocsPath = Join-Path $usbDeployPath "Documentation"

if ($TestOnly) {
    Write-Host ""
    Write-Host "[TEST MODE] Would create:" -ForegroundColor Yellow
    Write-Host "  Deployment Path: $usbDeployPath" -ForegroundColor Cyan
    Write-Host "  Scripts Path: $usbScriptsPath" -ForegroundColor Cyan
    Write-Host "  Documentation Path: $usbDocsPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Would copy $($importantScripts.Count) files" -ForegroundColor Yellow
    exit 0
}

Write-Host "[3/6] Creating deployment structure on USB..." -ForegroundColor Yellow
try {
    if (-not (Test-Path $usbDeployPath)) {
        New-Item -ItemType Directory -Path $usbDeployPath -Force | Out-Null
    }
    if (-not (Test-Path $usbScriptsPath)) {
        New-Item -ItemType Directory -Path $usbScriptsPath -Force | Out-Null
    }
    if (-not (Test-Path $usbDocsPath)) {
        New-Item -ItemType Directory -Path $usbDocsPath -Force | Out-Null
    }
    Write-Host "[OK] Directory structure created" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create directories: $_" -ForegroundColor Red
    exit 1
}

# Copy scripts
Write-Host "[4/6] Copying scripts to USB..." -ForegroundColor Yellow
$copiedCount = 0
$failedCount = 0

foreach ($script in $importantScripts) {
    $sourcePath = Join-Path $workspaceRoot $script
    $destPath = $null
    
    # Determine destination based on file type
    if ($script -match '\.(md|txt)$') {
        $destPath = Join-Path $usbDocsPath $script
    } else {
        $destPath = Join-Path $usbScriptsPath $script
    }
    
    if (Test-Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
            $copiedCount++
            Write-Host "  [OK] $script" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Failed to copy $script : $_" -ForegroundColor Red
            $failedCount++
        }
    } else {
        Write-Host "  [WARNING] File not found: $script" -ForegroundColor Yellow
        $failedCount++
    }
}

Write-Host "[OK] Copied $copiedCount file(s), $failedCount failed" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Yellow" })

# Create quick start files
Write-Host "[5/6] Creating quick start files..." -ForegroundColor Yellow

# Quick Start Batch File
$quickStartBat = @"
@echo off
REM Trading System Quick Start - USB Deployment
REM Run this file to start the trading system from USB

echo ========================================
echo   Trading System Quick Start
echo   USB Deployment Package
echo ========================================
echo.

cd /d "%~dp0Scripts"

echo [1/3] Setting up disk performance monitor...
call "%~dp0Scripts\QUICK-SETUP-DISK-MONITOR.bat"

echo.
echo [2/3] Checking trading system status...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Scripts\check-trading-status.ps1"

echo.
echo [3/3] Starting trading system...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Scripts\QUICK-START-TRADING-SYSTEM.ps1"

echo.
echo ========================================
echo   Quick Start Complete
echo ========================================
echo.
pause
"@

$quickStartBatPath = Join-Path $usbDeployPath "QUICK-START.bat"
Set-Content -Path $quickStartBatPath -Value $quickStartBat -Encoding ASCII
Write-Host "  [OK] Created QUICK-START.bat" -ForegroundColor Green

# Quick Start Text Guide
$quickStartTxt = @"
========================================
  TRADING SYSTEM - USB QUICK START GUIDE
========================================

DEPLOYMENT DATE: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
USB DRIVE: $($selectedUSB.DriveLetter): ($($selectedUSB.VolumeLabel))

========================================
QUICK START INSTRUCTIONS
========================================

1. RUN QUICK-START.bat
   - Double-click QUICK-START.bat
   - This will set up and start everything automatically

2. OR RUN INDIVIDUAL SCRIPTS:
   
   A. Setup Disk Monitor (Run as Administrator):
      Scripts\QUICK-SETUP-DISK-MONITOR.bat
   
   B. Check Trading Status:
      Scripts\check-trading-status.ps1
   
   C. Start Trading System:
      Scripts\QUICK-START-TRADING-SYSTEM.ps1

========================================
IMPORTANT SCRIPTS INCLUDED
========================================

DISK PERFORMANCE MONITORING:
  - monitor-disk-performance.ps1
  - setup-disk-performance-monitor.ps1
  - ensure-trading-priority.ps1

TRADING SYSTEM CORE:
  - master-trading-orchestrator.ps1
  - check-trading-status.ps1
  - QUICK-START-TRADING-SYSTEM.ps1

SYSTEM SETUP:
  - setup-trading-system.ps1
  - setup-trading-auto-start.ps1
  - verify-trading-system.ps1

========================================
REQUIREMENTS
========================================

- Windows 11
- PowerShell 5.1 or later
- Administrator privileges (for some scripts)
- Internet connection (for trading)

========================================
TROUBLESHOOTING
========================================

If scripts fail to run:
1. Right-click script → Run with PowerShell
2. Check PowerShell execution policy:
   Get-ExecutionPolicy
3. If needed, set policy:
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

For disk performance issues:
- See Documentation\DISK-PERFORMANCE-MONITOR-GUIDE.md

For trading system issues:
- See Documentation\TRADING-SYSTEM-QUICK-START.md

========================================
SUPPORT
========================================

All documentation is in the Documentation\ folder.

Key files:
  - README.md - Main project overview
  - DISK-PERFORMANCE-MONITOR-GUIDE.md - Disk monitoring guide
  - TRADING-SYSTEM-QUICK-START.md - Trading setup guide
  - SYSTEM-INFO.md - System specifications

========================================
"@

$quickStartTxtPath = Join-Path $usbDeployPath "QUICK-START.txt"
Set-Content -Path $quickStartTxtPath -Value $quickStartTxt -Encoding UTF8
Write-Host "  [OK] Created QUICK-START.txt" -ForegroundColor Green

# Create deployment info file
$deployInfo = @"
Trading System USB Deployment Package
=====================================

Deployment Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source: $workspaceRoot
Destination: $usbDeployPath
USB Drive: $($selectedUSB.DriveLetter): ($($selectedUSB.VolumeLabel))

Files Deployed: $copiedCount
Failed: $failedCount

Scripts Location: Scripts\
Documentation Location: Documentation\

To start the system, run: QUICK-START.bat
"@

$deployInfoPath = Join-Path $usbDeployPath "DEPLOYMENT-INFO.txt"
Set-Content -Path $deployInfoPath -Value $deployInfo -Encoding UTF8
Write-Host "  [OK] Created DEPLOYMENT-INFO.txt" -ForegroundColor Green

Write-Host "[6/6] Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "USB Drive: $($selectedUSB.DriveLetter): ($($selectedUSB.VolumeLabel))" -ForegroundColor White
Write-Host "Deployment Path: $usbDeployPath" -ForegroundColor White
Write-Host "Files Copied: $copiedCount" -ForegroundColor Green
Write-Host ""
Write-Host "Quick Start Files:" -ForegroundColor Yellow
Write-Host "  - QUICK-START.bat (Run this first!)" -ForegroundColor Cyan
Write-Host "  - QUICK-START.txt (Read this for instructions)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to: $usbDeployPath" -ForegroundColor White
Write-Host "  2. Run: QUICK-START.bat" -ForegroundColor White
Write-Host ""
Write-Host "To open the deployment folder:" -ForegroundColor Yellow
$openFolder = Read-Host "  Open folder now? (Y/N)"
if ($openFolder -eq 'Y' -or $openFolder -eq 'y') {
    Start-Process explorer.exe -ArgumentList $usbDeployPath
}






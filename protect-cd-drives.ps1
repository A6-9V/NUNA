#Requires -Version 5.1
<#
.SYNOPSIS
    Protect C: and D: Drives from Heavy I/O
.DESCRIPTION
    Monitors and protects C: (OS) and D: drives from heavy read/write operations
    Redirects heavy I/O to E: drive and USB drives
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Drive Protection System" -ForegroundColor Cyan
Write-Host "  Protected: C: (OS), D:" -ForegroundColor Yellow
Write-Host "  I/O Target: E: + USB Drives" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Protected drives
$protectedDrives = @("C:", "D:")
$ioDrives = @("E:")

# Import USB support
$usbSupportScript = Join-Path $PSScriptRoot "vps-services\usb-support.ps1"
if (Test-Path $usbSupportScript) {
    . $usbSupportScript
    $usbDrives = Get-USBDrives
    foreach ($usb in $usbDrives) {
        $ioDrives += $usb.DriveLetter
    }
}

Write-Host "Protected Drives: $($protectedDrives -join ', ')" -ForegroundColor Yellow
Write-Host "I/O Drives: $($ioDrives -join ', ')" -ForegroundColor Green
Write-Host ""

# Function to check drive I/O
function Get-DriveIOStats {
    param([string]$DriveLetter)
    
    try {
        $drive = $DriveLetter.TrimEnd(':')
        $counter = Get-Counter "\PhysicalDisk($drive)\% Disk Time" -ErrorAction SilentlyContinue
        if ($counter) {
            $diskTime = [math]::Round($counter.CounterSamples[0].CookedValue, 1)
            
            $readCounter = Get-Counter "\PhysicalDisk($drive)\Disk Read Bytes/sec" -ErrorAction SilentlyContinue
            $writeCounter = Get-Counter "\PhysicalDisk($drive)\Disk Write Bytes/sec" -ErrorAction SilentlyContinue
            
            $readMB = if ($readCounter) { [math]::Round($readCounter.CounterSamples[0].CookedValue / 1MB, 2) } else { 0 }
            $writeMB = if ($writeCounter) { [math]::Round($writeCounter.CounterSamples[0].CookedValue / 1MB, 2) } else { 0 }
            
            return @{
                Drive = $DriveLetter
                ActiveTime = $diskTime
                ReadMB = $readMB
                WriteMB = $writeMB
            }
        }
    } catch {
        # Counter may not be available
    }
    
    return $null
}

# Function to alert on high I/O
function Test-ProtectedDriveIO {
    param([string]$DriveLetter)
    
    $stats = Get-DriveIOStats -DriveLetter $DriveLetter
    if ($stats) {
        if ($stats.ActiveTime -gt 70) {
            Write-Host "[WARNING] $DriveLetter drive active time: $($stats.ActiveTime)%" -ForegroundColor Yellow
            Write-Host "  Read: $($stats.ReadMB) MB/s, Write: $($stats.WriteMB) MB/s" -ForegroundColor Gray
            
            if ($stats.ActiveTime -gt 90) {
                Write-Host "[ALERT] $DriveLetter drive is under heavy load!" -ForegroundColor Red
                Write-Host "  Consider redirecting operations to E: drive or USB" -ForegroundColor Yellow
                return $true
            }
        }
    }
    
    return $false
}

# Function to get available I/O drive
function Get-AvailableIODrive {
    # Check E: first
    $eDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "E:" }
    if ($eDrive -and ($eDrive.FreeSpace / 1GB) -gt 1) {
        return "E:"
    }
    
    # Check USB drives
    if (Test-Path $usbSupportScript) {
        $usbDrives = Get-USBDrives
        if ($usbDrives.Count -gt 0) {
            $bestUSB = $usbDrives | Where-Object { $_.FreeSpace -gt 1 } | 
                       Sort-Object -Property FreeSpace -Descending | Select-Object -First 1
            if ($bestUSB) {
                return $bestUSB.DriveLetter
            }
        }
    }
    
    return $null
}

# Main monitoring loop
Write-Host "Starting drive protection monitoring..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$alertCount = 0
$checkInterval = 10  # Check every 10 seconds

while ($true) {
    $highIO = $false
    
    foreach ($drive in $protectedDrives) {
        if (Test-ProtectedDriveIO -DriveLetter $drive) {
            $highIO = $true
            $alertCount++
            
            # Suggest I/O drive
            $ioDrive = Get-AvailableIODrive
            if ($ioDrive) {
                Write-Host "[INFO] Available I/O drive: $ioDrive" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] No I/O drives available with sufficient space" -ForegroundColor Yellow
            }
        }
    }
    
    # Show status every 5 checks (50 seconds)
    if ($alertCount % 5 -eq 0 -and $alertCount -gt 0) {
        Write-Host ""
        Write-Host "[STATUS] Monitoring active - $alertCount alerts since start" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Start-Sleep -Seconds $checkInterval
}


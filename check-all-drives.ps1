#Requires -Version 5.1
<#
.SYNOPSIS
    Check Disk Space for All Drives
.DESCRIPTION
    Displays comprehensive disk space information for all drives on the system
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All Drives - Disk Space Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all logical disks
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.Size -gt 0 }

if (-not $drives) {
    Write-Host "[ERROR] No drives found" -ForegroundColor Red
    exit 1
}

$totalSystemSpace = 0
$totalSystemFree = 0

foreach ($drive in $drives) {
    $driveLetter = $drive.DeviceID
    $volumeName = if ($drive.VolumeName) { $drive.VolumeName } else { "(No Label)" }
    $fileSystem = $drive.FileSystem
    $driveType = switch ($drive.DriveType) {
        2 { "Removable" }
        3 { "Fixed" }
        4 { "Network" }
        5 { "CD-ROM" }
        default { "Unknown" }
    }
    
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
    $freePercent = if ($drive.Size -gt 0) { [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1) } else { 0 }
    
    # Determine status color
    $statusColor = if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 20) { "Yellow" } else { "Green" }
    
    Write-Host "$driveLetter - $volumeName" -ForegroundColor Cyan
    Write-Host "  Type:        $driveType" -ForegroundColor White
    Write-Host "  File System: $fileSystem" -ForegroundColor Gray
    Write-Host "  Total:        $totalGB GB" -ForegroundColor White
    Write-Host "  Used:         $usedGB GB" -ForegroundColor Yellow
    Write-Host "  Free:         $freeGB GB ($freePercent%)" -ForegroundColor $statusColor
    
    # Add warning if space is low
    if ($freePercent -lt 10) {
        Write-Host "  [WARNING] Critically low on space!" -ForegroundColor Red
    } elseif ($freePercent -lt 20) {
        Write-Host "  [WARNING] Running low on space" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Sum up fixed drives for system total
    if ($drive.DriveType -eq 3) {
        $totalSystemSpace += $drive.Size
        $totalSystemFree += $drive.FreeSpace
    }
}

# System Summary (Fixed Drives Only)
if ($totalSystemSpace -gt 0) {
    $totalSystemGB = [math]::Round($totalSystemSpace / 1GB, 2)
    $totalSystemFreeGB = [math]::Round($totalSystemFree / 1GB, 2)
    $totalSystemUsedGB = [math]::Round(($totalSystemSpace - $totalSystemFree) / 1GB, 2)
    $totalSystemPercent = [math]::Round(($totalSystemFree / $totalSystemSpace) * 100, 1)
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  System Summary (Fixed Drives)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Total Space:  $totalSystemGB GB" -ForegroundColor White
    Write-Host "  Used Space:   $totalSystemUsedGB GB" -ForegroundColor Yellow
    Write-Host "  Free Space:   $totalSystemFreeGB GB ($totalSystemPercent%)" -ForegroundColor $(if ($totalSystemPercent -lt 20) { "Yellow" } else { "Green" })
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


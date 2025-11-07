# Storage Monitor Script
# Monitors all drives and provides health/performance information
# Created: November 6, 2025

param(
    [switch]$Continuous,
    [int]$IntervalSeconds = 30,
    [switch]$ShowDetails
)

function Get-DriveHealth {
    Write-Host "=== Storage Health Monitor ===" -ForegroundColor Green
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Cyan
    
    # Get all logical drives
    $drives = Get-WmiObject -Class Win32_LogicalDisk
    
    foreach ($drive in $drives) {
        $driveType = switch ($drive.DriveType) {
            2 { "Removable Disk" }
            3 { "Local Disk" }
            4 { "Network Drive" }
            5 { "Compact Disc" }
            default { "Unknown" }
        }
        
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
        
        # Health status color coding
        $healthColor = if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 20) { "Yellow" } else { "Green" }
        
        Write-Host "`n[$($drive.DeviceID)] $($drive.VolumeName) - $driveType" -ForegroundColor White
        Write-Host "  File System: $($drive.FileSystem)" -ForegroundColor Gray
        Write-Host "  Total: ${totalGB}GB | Used: ${usedGB}GB | Free: ${freeGB}GB (${freePercent}%)" -ForegroundColor $healthColor
        
        # Warning for low space
        if ($freePercent -lt 15) {
            Write-Host "  ⚠️  WARNING: Low disk space!" -ForegroundColor Red
        }
        
        if ($drive.DeviceID -eq "I:") {
            Write-Host "  [USB] Dahua USB Device - Consider upgrading to faster storage" -ForegroundColor Magenta
        }
    }
    
    # Physical disk health
    if ($ShowDetails) {
        Write-Host "`n=== Physical Disk Details ===" -ForegroundColor Green
        try {
            $physicalDisks = Get-PhysicalDisk
            foreach ($disk in $physicalDisks) {
                $healthIcon = if ($disk.HealthStatus -eq "Healthy") { "[OK]" } else { "[WARN]" }
                Write-Host "$healthIcon $($disk.FriendlyName)" -ForegroundColor White
                Write-Host "  Size: $([math]::Round($disk.Size / 1GB, 2))GB | Type: $($disk.MediaType) | Bus: $($disk.BusType)" -ForegroundColor Gray
                Write-Host "  Health: $($disk.HealthStatus) | Status: $($disk.OperationalStatus)" -ForegroundColor $(if ($disk.HealthStatus -eq "Healthy") { "Green" } else { "Yellow" })
            }
        } catch {
            Write-Host "Could not retrieve physical disk information" -ForegroundColor Yellow
        }
    }
    
    # USB-specific checks
    Write-Host "`n=== USB Device Analysis ===" -ForegroundColor Green
    try {
        $usbDevices = Get-WmiObject -Class Win32_USBHub | Where-Object { $_.Status -eq "OK" }
        Write-Host "Active USB devices: $($usbDevices.Count)" -ForegroundColor Cyan
        
        $dahuaUSB = $drives | Where-Object { $_.DeviceID -eq "I:" }
        if ($dahuaUSB) {
            Write-Host "[USB] Dahua USB Status:" -ForegroundColor Yellow
            Write-Host "  - File System: $($dahuaUSB.FileSystem) (FAT32 has 4GB file limit)" -ForegroundColor $(if ($dahuaUSB.FileSystem -eq "FAT32") { "Yellow" } else { "Green" })
            Write-Host "  - Recommendation: Format to NTFS for better performance" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Could not analyze USB devices" -ForegroundColor Yellow
    }    # Performance recommendations
    Write-Host "`n=== Performance Recommendations ===" -ForegroundColor Green
    $criticalDrives = $drives | Where-Object { ($_.FreeSpace / $_.Size) * 100 -lt 15 }
    if ($criticalDrives) {
        Write-Host "Critical: Clean up these drives immediately:" -ForegroundColor Red
        $criticalDrives | ForEach-Object { Write-Host "  - $($_.DeviceID) $($_.VolumeName)" -ForegroundColor Red }
    }
    
    $fat32Drives = $drives | Where-Object { $_.FileSystem -eq "FAT32" }
    if ($fat32Drives) {
        Write-Host "Consider converting FAT32 drives to NTFS:" -ForegroundColor Yellow
        $fat32Drives | ForEach-Object { Write-Host "  - $($_.DeviceID) $($_.VolumeName)" -ForegroundColor Yellow }
    }
}

function Start-ContinuousMonitoring {
    Write-Host "Starting continuous monitoring (Ctrl+C to stop)..." -ForegroundColor Green
    Write-Host "Update interval: $IntervalSeconds seconds" -ForegroundColor Cyan
    
    do {
        Clear-Host
        Get-DriveHealth
        Write-Host "`nNext update in $IntervalSeconds seconds... (Ctrl+C to stop)" -ForegroundColor Gray
        Start-Sleep -Seconds $IntervalSeconds
    } while ($true)
}

# Main execution
if ($Continuous) {
    Start-ContinuousMonitoring
} else {
    Get-DriveHealth
}

Write-Host "`n=== Monitoring Complete ===" -ForegroundColor Green
# Disk Health Monitor
# Monitors all disks for health issues, performance problems, and potential malware
# Designed to run at system startup

param(
    [switch]$Detailed,
    [switch]$ExportReport,
    [switch]$ScanForViruses
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disk Health Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get all physical disks
$physicalDisks = Get-PhysicalDisk | Sort-Object DeviceID
$logicalDisks = Get-WmiObject -Class Win32_LogicalDisk

# Critical disk to monitor (Disk 0 - Patriot P410 1TB SSD)
$criticalDisk = $physicalDisks | Where-Object { $_.DeviceID -eq 0 }

Write-Host "=== Physical Disk Status ===" -ForegroundColor Yellow
Write-Host ""

$issuesFound = @()
$warningsFound = @()

foreach ($disk in $physicalDisks) {
    $diskNumber = $disk.DeviceID
    $diskModel = $disk.Model
    $diskSize = [math]::Round($disk.Size / 1GB, 2)
    $diskHealth = $disk.HealthStatus
    $diskStatus = $disk.OperationalStatus
    
    Write-Host "Disk $diskNumber : $diskModel" -ForegroundColor White
    Write-Host "  Size: ${diskSize} GB" -ForegroundColor Gray
    Write-Host "  Health: $diskHealth" -ForegroundColor $(if ($diskHealth -eq "Healthy") { "Green" } else { "Red" })
    Write-Host "  Status: $diskStatus" -ForegroundColor Gray
    
    # Check for health issues
    if ($diskHealth -ne "Healthy") {
        $issuesFound += "Disk $diskNumber ($diskModel): Health status is $diskHealth"
        Write-Host "  [WARNING] Health issue detected!" -ForegroundColor Red
    }
    
    # Get performance counters for this disk
    $diskLetters = $logicalDisks | Where-Object { 
        $_.DeviceID -match "^[A-Z]:" -and 
        (Get-Partition | Where-Object { $_.DiskNumber -eq $diskNumber -and $_.DriveLetter }) 
    }
    
    if ($diskLetters) {
        $driveLetters = ($diskLetters | ForEach-Object { $_.DeviceID.TrimEnd(':') }) -join ", "
        Write-Host "  Drive Letters: $driveLetters" -ForegroundColor Cyan
        
        # Check performance for each drive
        foreach ($logicalDisk in $diskLetters) {
            $driveLetter = $logicalDisk.DeviceID.TrimEnd(':')
            
            # Get performance data
            $perfCounter = Get-Counter "\PhysicalDisk($driveLetter)\Disk Read Bytes/sec", "\PhysicalDisk($driveLetter)\Disk Write Bytes/sec" -ErrorAction SilentlyContinue
            
            if ($perfCounter) {
                $readSpeed = [math]::Round(($perfCounter.CounterSamples[0].CookedValue) / 1MB, 2)
                $writeSpeed = [math]::Round(($perfCounter.CounterSamples[1].CookedValue) / 1KB, 2)
                
                Write-Host "    Drive $driveLetter`:" -ForegroundColor White
                Write-Host "      Read Speed: ${readSpeed} MB/s" -ForegroundColor $(if ($readSpeed -lt 1) { "Yellow" } else { "Green" })
                Write-Host "      Write Speed: ${writeSpeed} KB/s" -ForegroundColor $(if ($writeSpeed -lt 100) { "Red" } elseif ($writeSpeed -lt 1000) { "Yellow" } else { "Green" })
                
                # Critical check for Disk 0 (Patriot P410 SSD)
                if ($diskNumber -eq 0) {
                    if ($writeSpeed -lt 100) {
                        $criticalIssue = "CRITICAL: Disk 0 (Patriot P410 SSD) write speed is only ${writeSpeed} KB/s - Expected much higher for SSD!"
                        $issuesFound += $criticalIssue
                        Write-Host "      [CRITICAL] Very low write speed detected!" -ForegroundColor Red
                        Write-Host "      [INFO] This could indicate:" -ForegroundColor Yellow
                        Write-Host "        - Hardware failure" -ForegroundColor Yellow
                        Write-Host "        - Malware/virus activity" -ForegroundColor Yellow
                        Write-Host "        - Disk corruption" -ForegroundColor Yellow
                        Write-Host "        - Driver issues" -ForegroundColor Yellow
                    }
                    
                    if ($readSpeed -lt 10) {
                        $warningsFound += "Disk 0 (Patriot P410 SSD) read speed is low: ${readSpeed} MB/s"
                        Write-Host "      [WARNING] Low read speed for SSD" -ForegroundColor Yellow
                    }
                }
            }
            
            # Check disk space
            $freeSpace = [math]::Round($logicalDisk.FreeSpace / 1GB, 2)
            $totalSpace = [math]::Round($logicalDisk.Size / 1GB, 2)
            $usedPercent = [math]::Round((($totalSpace - $freeSpace) / $totalSpace) * 100, 1)
            
            Write-Host "      Free Space: ${freeSpace} GB / ${totalSpace} GB (${usedPercent}% used)" -ForegroundColor $(if ($usedPercent -gt 90) { "Red" } elseif ($usedPercent -gt 80) { "Yellow" } else { "Green" })
            
            if ($usedPercent -gt 90) {
                $warningsFound += "Drive $driveLetter is ${usedPercent}% full"
            }
        }
    }
    
    Write-Host ""
}

# Check for suspicious activity on Disk 0
if ($criticalDisk) {
    Write-Host "=== Disk 0 (Patriot P410) Security Check ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Check for suspicious files
    $suspiciousExtensions = @("*.exe", "*.bat", "*.cmd", "*.scr", "*.vbs", "*.js")
    $suspiciousCount = 0
    
    foreach ($drive in @("C:", "D:", "G:")) {
        if (Test-Path $drive) {
            Write-Host "Scanning $drive for suspicious executables..." -ForegroundColor Cyan
            foreach ($ext in $suspiciousExtensions) {
                $count = (Get-ChildItem -Path $drive -Filter $ext -Recurse -ErrorAction SilentlyContinue -Depth 2 | Measure-Object).Count
                if ($count -gt 0) {
                    $suspiciousCount += $count
                }
            }
        }
    }
    
    if ($suspiciousCount -gt 1000) {
        $warningsFound += "High number of executable files found on Disk 0 - may need virus scan"
        Write-Host "  [WARNING] Found $suspiciousCount executable files (may need scanning)" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Executable file count appears normal" -ForegroundColor Green
    }
    Write-Host ""
}

# Virus scan option
if ($ScanForViruses) {
    Write-Host "=== Virus Scan ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Check if Windows Defender is available
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defenderStatus) {
        Write-Host "[INFO] Starting Windows Defender Quick Scan..." -ForegroundColor Cyan
        Write-Host "  This may take several minutes..." -ForegroundColor Gray
        
        try {
            Start-MpScan -ScanType QuickScan
            Write-Host "  [OK] Quick scan initiated" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Could not start scan: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARNING] Windows Defender not available" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($issuesFound.Count -eq 0 -and $warningsFound.Count -eq 0) {
    Write-Host "[OK] No critical issues detected" -ForegroundColor Green
} else {
    if ($issuesFound.Count -gt 0) {
        Write-Host "[CRITICAL] Issues Found:" -ForegroundColor Red
        foreach ($issue in $issuesFound) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($warningsFound.Count -gt 0) {
        Write-Host "[WARNING] Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warningsFound) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

# Export report if requested
if ($ExportReport) {
    $reportPath = Join-Path $env:USERPROFILE "OneDrive\disk-health-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $report = @"
Disk Health Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Physical Disks:
$($physicalDisks | Format-List | Out-String)

Issues Found: $($issuesFound.Count)
$($issuesFound | Out-String)

Warnings: $($warningsFound.Count)
$($warningsFound | Out-String)
"@
    
    Set-Content -Path $reportPath -Value $report
    Write-Host "[OK] Report exported to: $reportPath" -ForegroundColor Green
}

Write-Host ""

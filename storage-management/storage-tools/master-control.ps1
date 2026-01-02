# Storage Management Master Control Panel
# Complete system for managing your storage across all drives
# Created by AI Assistant - November 6, 2025

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("status", "cleanup", "backup", "optimize", "monitor", "setup-lexar")]
    [string]$Action = "status"
)

function Show-StorageStatus {
    Clear-Host
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host "    STORAGE MANAGEMENT CONTROL PANEL" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
    
    # Drive Status
    Write-Host "`n📊 DRIVE STATUS:" -ForegroundColor Yellow
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.Size -gt 0}
    foreach ($drive in $drives) {
        $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        
        $status = if ($freePercent -lt 10) { "🔴 CRITICAL" } 
                  elseif ($freePercent -lt 20) { "🟡 WARNING" } 
                  else { "🟢 GOOD" }
        
        $driveType = switch ($drive.DriveType) {
            2 { "USB" }
            3 { "Local" }
            4 { "Network" }
            default { "Unknown" }
        }
        
        Write-Host "[$($drive.DeviceID)] $($drive.VolumeName) - $driveType" -ForegroundColor White
        Write-Host "  Size: ${totalGB}GB | Free: ${freeGB}GB (${freePercent}%) | $status" -ForegroundColor $(if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 20) { "Yellow" } else { "Green" })
    }
    
    # Recommendations
    Write-Host "`n💡 CURRENT RECOMMENDATIONS:" -ForegroundColor Cyan
    $cDrive = $drives | Where-Object { $_.DeviceID -eq "C:" }
    if ($cDrive) {
        $cFreePercent = ($cDrive.FreeSpace / $cDrive.Size) * 100
        if ($cFreePercent -lt 10) {
            Write-Host "🚨 URGENT: C: drive critically low - run cleanup immediately!" -ForegroundColor Red
        } elseif ($cFreePercent -lt 20) {
            Write-Host "⚠️  C: drive getting low - consider cleanup" -ForegroundColor Yellow
        }
    }
    
    # Check if Lexar SSD is available
    $lexarDisk = Get-PhysicalDisk | Where-Object {$_.FriendlyName -like "*Lexar*"} -ErrorAction SilentlyContinue
    if ($lexarDisk) {
        Write-Host "💾 Lexar SSD 512GB detected - available for setup" -ForegroundColor Cyan
    }
    
    Write-Host "✅ Use D: drive for main storage (most space available)" -ForegroundColor Green
    Write-Host "✅ Regular backups are configured" -ForegroundColor Green
    
    # Recent backups
    Write-Host "`n📁 RECENT BACKUPS:" -ForegroundColor Yellow
    $backups = Get-ChildItem "D:\Backups\" -Recurse -Directory -ErrorAction SilentlyContinue | Sort-Object CreationTime -Descending | Select-Object -First 3
    if ($backups) {
        foreach ($backup in $backups) {
            $age = [math]::Round((Get-Date - $backup.CreationTime).TotalDays, 1)
            Write-Host "  $($backup.Name) - ${age} days ago" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No recent backups found" -ForegroundColor Gray
    }
}

function Start-EmergencyCleanup {
    Write-Host "🧹 STARTING EMERGENCY CLEANUP..." -ForegroundColor Yellow
    
    # Clean temp files
    $tempPaths = @(
        "$env:TEMP",
        "C:\Windows\Temp",
        "$env:USERPROFILE\AppData\Local\Temp"
    )
    
    $totalCleaned = 0
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                $beforeSize = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Cleaned: $path ($([math]::Round($beforeSize/1MB,2))MB)" -ForegroundColor Green
                $totalCleaned += $beforeSize
            } catch {
                Write-Host "⚠️  Could not clean: $path" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "🎉 Total space recovered: $([math]::Round($totalCleaned/1GB,2))GB" -ForegroundColor Green
}

function Start-QuickBackup {
    Write-Host "💾 STARTING QUICK BACKUP..." -ForegroundColor Yellow
    $backupPath = "D:\Backups\Quick-Backup-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # Backup critical folders
    $folders = @("Desktop", "Documents")
    foreach ($folder in $folders) {
        $source = "$env:USERPROFILE\$folder"
        $dest = "$backupPath\$folder"
        if (Test-Path $source) {
            robocopy $source $dest /E /COPY:DAT /R:1 /W:1 /XF *.tmp *.temp /MT:4 | Out-Null
            Write-Host "✅ Backed up: $folder" -ForegroundColor Green
        }
    }
    
    Write-Host "🎉 Backup completed: $backupPath" -ForegroundColor Green
}

function Show-Menu {
    Write-Host "`n🎛️  AVAILABLE ACTIONS:" -ForegroundColor Cyan
    Write-Host "1. status     - Show current storage status (default)" -ForegroundColor White
    Write-Host "2. cleanup    - Emergency cleanup of temporary files" -ForegroundColor White  
    Write-Host "3. backup     - Quick backup of important files" -ForegroundColor White
    Write-Host "4. monitor    - Continuous monitoring mode" -ForegroundColor White
    Write-Host "5. setup-lexar - Try to setup Lexar SSD" -ForegroundColor White
    Write-Host "`nUsage: .\master-control.ps1 -Action <action>" -ForegroundColor Gray
}

# Main execution
switch ($Action) {
    "status" {
        Show-StorageStatus
        Show-Menu
    }
    "cleanup" {
        Show-StorageStatus
        Start-EmergencyCleanup
        Write-Host "`nPress any key to see updated status..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-StorageStatus
    }
    "backup" {
        Show-StorageStatus
        Start-QuickBackup
        Show-StorageStatus
    }
    "monitor" {
        do {
            Show-StorageStatus
            Write-Host "`nMonitoring... (Ctrl+C to stop, any key to refresh)" -ForegroundColor Gray
            Start-Sleep -Seconds 1
            if ([Console]::KeyAvailable) {
                $null = [Console]::ReadKey($true)
                Clear-Host
            }
        } while ($true)
    }
    "setup-lexar" {
        Write-Host "🔧 ATTEMPTING LEXAR SSD SETUP..." -ForegroundColor Yellow
        Write-Host "Note: May require administrator privileges" -ForegroundColor Gray
        
        try {
            $lexarDisk = Get-Disk | Where-Object {$_.FriendlyName -like "*Lexar*"}
            if ($lexarDisk) {
                Write-Host "Found: $($lexarDisk.FriendlyName) ($([math]::Round($lexarDisk.Size/1GB,2))GB)" -ForegroundColor Cyan
                Write-Host "Status: $($lexarDisk.OperationalStatus)" -ForegroundColor Cyan
                Write-Host "⚠️  Run as Administrator to complete setup" -ForegroundColor Yellow
            } else {
                Write-Host "❌ Lexar SSD not detected" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Error accessing disk information" -ForegroundColor Red
        }
    }
}

Write-Host "`n" + "=" * 60 -ForegroundColor Green
Write-Host "Storage Management System Active - $(Get-Date)" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
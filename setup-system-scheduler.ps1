#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System-Wide Trading Automation Scheduler
.DESCRIPTION
    Sets up complete automation including:
    - Daily system review and cleanup
    - Trading system auto-start on boot
    - Scheduled monitoring and reports
    - Security checks and updates
    - Communication system health checks
#>

$ErrorActionPreference = "Stop"

$workspaceRoot = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " System-Wide Scheduler Setup" -ForegroundColor Cyan
Write-Host " Trading Automation & Monitoring" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to create scheduled task
function New-TradingTask {
    param(
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$TriggerType,
        [string]$Time = "",
        [string]$Description = ""
    )
    
    try {
        # Remove existing task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Create action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`""
        
        # Create trigger based on type
        switch ($TriggerType) {
            "Startup" {
                $trigger = New-ScheduledTaskTrigger -AtStartup
            }
            "Daily" {
                $trigger = New-ScheduledTaskTrigger -Daily -At $Time
            }
            "Hourly" {
                $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
            }
            "Every5Minutes" {
                $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
            }
            default {
                $trigger = New-ScheduledTaskTrigger -AtStartup
            }
        }
        
        # Create principal (run as SYSTEM with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Create settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable `
            -DontStopOnIdleEnd
        
        # Register task
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description $Description | Out-Null
        
        Write-Host "  [OK] Created task: $TaskName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERROR] Failed to create task $TaskName : $_" -ForegroundColor Red
        return $false
    }
}

# Task 1: Auto-start trading system on boot
Write-Host "[1] Setting up trading system auto-start..." -ForegroundColor Cyan
$tradingScript = Join-Path $workspaceRoot "start-trading-system-admin.ps1"
if (Test-Path $tradingScript) {
    New-TradingTask `
        -TaskName "TradingSystem-AutoStart" `
        -ScriptPath $tradingScript `
        -TriggerType "Startup" `
        -Description "Automatically start trading system on system boot"
} else {
    Write-Host "  [WARNING] Trading script not found: $tradingScript" -ForegroundColor Yellow
}

# Task 2: Daily system review (runs at 6:00 AM)
Write-Host ""
Write-Host "[2] Setting up daily system review..." -ForegroundColor Cyan
$reviewScript = Join-Path $workspaceRoot "system-status-report.ps1"
if (Test-Path $reviewScript) {
    New-TradingTask `
        -TaskName "TradingSystem-DailyReview" `
        -ScriptPath $reviewScript `
        -TriggerType "Daily" `
        -Time "06:00" `
        -Description "Daily system review and status report"
} else {
    Write-Host "  [WARNING] Review script not found: $reviewScript" -ForegroundColor Yellow
}

# Task 3: Hourly trading status check
Write-Host ""
Write-Host "[3] Setting up hourly trading status check..." -ForegroundColor Cyan
$statusScript = Join-Path $workspaceRoot "check-trading-status.ps1"
if (Test-Path $statusScript) {
    New-TradingTask `
        -TaskName "TradingSystem-HourlyCheck" `
        -ScriptPath $statusScript `
        -TriggerType "Hourly" `
        -Description "Hourly trading system health check"
} else {
    Write-Host "  [WARNING] Status script not found: $statusScript" -ForegroundColor Yellow
}

# Task 4: Security check (daily at 2:00 AM)
Write-Host ""
Write-Host "[4] Setting up daily security check..." -ForegroundColor Cyan
$securityScript = Join-Path $workspaceRoot "security-check-trading.ps1"
if (Test-Path $securityScript) {
    New-TradingTask `
        -TaskName "TradingSystem-SecurityCheck" `
        -ScriptPath $securityScript `
        -TriggerType "Daily" `
        -Time "02:00" `
        -Description "Daily security audit and verification"
} else {
    Write-Host "  [WARNING] Security script not found: $securityScript" -ForegroundColor Yellow
}

# Task 5: Disk health monitoring (every 6 hours)
Write-Host ""
Write-Host "[5] Setting up disk health monitoring..." -ForegroundColor Cyan
$diskScript = Join-Path $workspaceRoot "disk-health-monitor.ps1"
if (Test-Path $diskScript) {
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)
    
    try {
        Unregister-ScheduledTask -TaskName "TradingSystem-DiskMonitor" -Confirm:$false -ErrorAction SilentlyContinue
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$diskScript`""
        
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask `
            -TaskName "TradingSystem-DiskMonitor" `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Monitor disk health every 6 hours" | Out-Null
        
        Write-Host "  [OK] Created task: TradingSystem-DiskMonitor" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to create disk monitor task: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [WARNING] Disk monitor script not found: $diskScript" -ForegroundColor Yellow
}

# Task 6: Weekly cleanup (Sunday at 3:00 AM)
Write-Host ""
Write-Host "[6] Setting up weekly cleanup..." -ForegroundColor Cyan
$cleanupScript = Join-Path $workspaceRoot "maintain-and-cleanup.ps1"
if (Test-Path $cleanupScript) {
    try {
        Unregister-ScheduledTask -TaskName "TradingSystem-WeeklyCleanup" -Confirm:$false -ErrorAction SilentlyContinue
        
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$cleanupScript`""
        
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask `
            -TaskName "TradingSystem-WeeklyCleanup" `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Weekly system cleanup and maintenance" | Out-Null
        
        Write-Host "  [OK] Created task: TradingSystem-WeeklyCleanup" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to create weekly cleanup task: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [WARNING] Cleanup script not found: $cleanupScript" -ForegroundColor Yellow
}

# Task 7: GitHub auto-merge (daily at 1:00 AM)
Write-Host ""
Write-Host "[7] Setting up GitHub auto-merge..." -ForegroundColor Cyan
$mergeScript = Join-Path $workspaceRoot "review-and-merge-prs.ps1"
if (Test-Path $mergeScript) {
    New-TradingTask `
        -TaskName "TradingSystem-AutoMerge" `
        -ScriptPath $mergeScript `
        -TriggerType "Daily" `
        -Time "01:00" `
        -Description "Automated GitHub PR review and merge"
} else {
    Write-Host "  [WARNING] Merge script not found: $mergeScript" -ForegroundColor Yellow
}

# Task 8: Backup trading configuration (daily at 4:00 AM)
Write-Host ""
Write-Host "[8] Setting up configuration backup..." -ForegroundColor Cyan
$backupScript = Join-Path $workspaceRoot "backup-to-usb.ps1"
if (Test-Path $backupScript) {
    New-TradingTask `
        -TaskName "TradingSystem-ConfigBackup" `
        -ScriptPath $backupScript `
        -TriggerType "Daily" `
        -Time "04:00" `
        -Description "Daily backup of trading configuration"
} else {
    Write-Host "  [WARNING] Backup script not found: $backupScript" -ForegroundColor Yellow
}

# Create monitoring log directory
Write-Host ""
Write-Host "[9] Creating monitoring directories..." -ForegroundColor Cyan
$logsDir = Join-Path $workspaceRoot "logs"
$monitoringDir = Join-Path $logsDir "monitoring"

foreach ($dir in @($logsDir, $monitoringDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    }
}

# Create system health monitoring script
Write-Host ""
Write-Host "[10] Creating system health monitor..." -ForegroundColor Cyan

$healthMonitorScript = Join-Path $workspaceRoot "monitor-system-health.ps1"
$healthMonitorContent = @'
#Requires -Version 5.1
# System Health Monitor for Trading System

$workspaceRoot = $PSScriptRoot
$logsPath = Join-Path $workspaceRoot "logs\monitoring"
$logFile = Join-Path $logsPath "health_$(Get-Date -Format 'yyyyMMdd').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $Message"
}

Write-Log "=== System Health Check Started ==="

# Check Python process
$pythonProcess = Get-Process -Name "python" -ErrorAction SilentlyContinue
if ($pythonProcess) {
    Write-Log "[OK] Python trading service is running (PID: $($pythonProcess.Id))"
} else {
    Write-Log "[WARNING] Python trading service not running"
}

# Check MT5 terminal
$mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
if ($mt5Process) {
    Write-Log "[OK] MT5 terminal is running (PID: $($mt5Process.Id))"
} else {
    Write-Log "[WARNING] MT5 terminal not running"
}

# Check disk space
$systemDrive = Get-PSDrive -Name C
$freeSpacePercent = ($systemDrive.Free / $systemDrive.Used) * 100
if ($freeSpacePercent -gt 10) {
    Write-Log "[OK] Disk space: $([math]::Round($freeSpacePercent, 2))% free"
} else {
    Write-Log "[WARNING] Low disk space: $([math]::Round($freeSpacePercent, 2))% free"
}

# Check network connectivity
try {
    $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
    if ($ping) {
        Write-Log "[OK] Network connectivity verified"
    } else {
        Write-Log "[WARNING] Network connectivity issues"
    }
} catch {
    Write-Log "[ERROR] Failed to check network: $_"
}

Write-Log "=== System Health Check Completed ==="
'@

Set-Content -Path $healthMonitorScript -Value $healthMonitorContent
Write-Host "  [OK] Created health monitor script" -ForegroundColor Green

# Create health monitoring task (every 5 minutes)
New-TradingTask `
    -TaskName "TradingSystem-HealthMonitor" `
    -ScriptPath $healthMonitorScript `
    -TriggerType "Every5Minutes" `
    -Description "Monitor system health every 5 minutes"

# Display scheduled tasks summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Scheduled Tasks Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "TradingSystem-*" }

foreach ($task in $tasks) {
    $status = if ($task.State -eq "Ready") { "✓" } else { "✗" }
    $color = if ($task.State -eq "Ready") { "Green" } else { "Red" }
    
    Write-Host "  $status $($task.TaskName)" -ForegroundColor $color
    Write-Host "    Status: $($task.State)" -ForegroundColor Gray
    
    $trigger = $task.Triggers[0]
    if ($trigger.StartBoundary) {
        $triggerTime = [DateTime]::Parse($trigger.StartBoundary).ToString("HH:mm")
        Write-Host "    Schedule: $triggerTime" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configured Tasks:" -ForegroundColor White
Write-Host "  • Auto-start trading on boot" -ForegroundColor Gray
Write-Host "  • Daily system review (6:00 AM)" -ForegroundColor Gray
Write-Host "  • Hourly health checks" -ForegroundColor Gray
Write-Host "  • Daily security audit (2:00 AM)" -ForegroundColor Gray
Write-Host "  • Disk monitoring (every 6 hours)" -ForegroundColor Gray
Write-Host "  • Weekly cleanup (Sunday 3:00 AM)" -ForegroundColor Gray
Write-Host "  • GitHub auto-merge (1:00 AM)" -ForegroundColor Gray
Write-Host "  • Config backup (4:00 AM)" -ForegroundColor Gray
Write-Host "  • System health monitor (every 5 min)" -ForegroundColor Gray
Write-Host ""
Write-Host "Monitoring Logs:" -ForegroundColor Yellow
Write-Host "  Location: $monitoringDir" -ForegroundColor Gray
Write-Host ""
Write-Host "View tasks: Get-ScheduledTask | Where-Object { `$_.TaskName -like 'TradingSystem-*' }" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

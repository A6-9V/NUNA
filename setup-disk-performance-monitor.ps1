#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Setup Real-Time Disk Performance Monitor as Scheduled Task
.DESCRIPTION
    Creates a scheduled task to run the disk performance monitor continuously
    in the background, ensuring trading system stability.
#>

param(
    [switch]$RemoveTask
)

$ErrorActionPreference = "Continue"

$taskName = "TradingSystem\DiskPerformanceMonitor"
$scriptPath = Join-Path $PSScriptRoot "monitor-disk-performance.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disk Performance Monitor Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($RemoveTask) {
    Write-Host "[INFO] Removing scheduled task..." -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Host "[OK] Task removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[INFO] Task does not exist or already removed" -ForegroundColor Cyan
    }
    exit 0
}

# Verify script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "[ERROR] Script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] Checking existing task..." -ForegroundColor Yellow
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "[INFO] Task already exists. Updating..." -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Host "[OK] Old task removed" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not remove old task: $_" -ForegroundColor Yellow
    }
}

Write-Host "[2/4] Creating scheduled task..." -ForegroundColor Yellow

# Create task action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-ExecutionPolicy", "Bypass",
    "-WindowStyle", "Hidden",
    "-File", "`"$scriptPath`"",
    "-Interval", "5",
    "-CriticalActiveTime", "90",
    "-CriticalResponseTime", "50",
    "-EnableOptimization"
)

# Create task trigger (at startup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Create task settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

# Create task principal (run as SYSTEM for highest priority)
$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# Register the task
try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Real-time disk performance monitor for trading system stability. Monitors Disk 0 (Patriot P410 SSD) and optimizes I/O when critical thresholds are exceeded." `
        -ErrorAction Stop
    
    Write-Host "[OK] Scheduled task created successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create task: $_" -ForegroundColor Red
    exit 1
}

Write-Host "[3/4] Starting task..." -ForegroundColor Yellow
try {
    Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    if ($taskInfo.State -eq "Running") {
        Write-Host "[OK] Task is running" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Task registered but not running. State: $($taskInfo.State)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARNING] Could not start task immediately: $_" -ForegroundColor Yellow
    Write-Host "[INFO] Task will start automatically at next system startup" -ForegroundColor Cyan
}

Write-Host "[4/4] Verifying setup..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "[OK] Task verified in Task Scheduler" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $taskName" -ForegroundColor White
    Write-Host "  Status: $($task.State)" -ForegroundColor White
    Write-Host "  Runs: At system startup" -ForegroundColor White
    Write-Host "  User: SYSTEM (highest priority)" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "[ERROR] Task verification failed" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The disk performance monitor is now running in the background." -ForegroundColor White
Write-Host ""
Write-Host "Monitor Features:" -ForegroundColor Yellow
Write-Host "  ✓ Real-time disk performance monitoring (every 5 seconds)" -ForegroundColor Green
Write-Host "  ✓ Automatic alerts when disk active time > 90%" -ForegroundColor Green
Write-Host "  ✓ Automatic alerts when response time > 50ms" -ForegroundColor Green
Write-Host "  ✓ Automatic disk I/O optimization when critical" -ForegroundColor Green
Write-Host "  ✓ Trading system health checks" -ForegroundColor Green
Write-Host "  ✓ Process priority optimization for trading" -ForegroundColor Green
Write-Host ""
Write-Host "Log File:" -ForegroundColor Yellow
Write-Host "  $env:USERPROFILE\OneDrive\disk-performance-monitor.log" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view the log in real-time:" -ForegroundColor Yellow
Write-Host "  Get-Content `"$env:USERPROFILE\OneDrive\disk-performance-monitor.log`" -Wait -Tail 20" -ForegroundColor White
Write-Host ""
Write-Host "To remove the monitor:" -ForegroundColor Yellow
Write-Host "  .\setup-disk-performance-monitor.ps1 -RemoveTask" -ForegroundColor White
Write-Host ""






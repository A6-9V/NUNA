# Setup Startup Disk Monitor
# Creates a scheduled task to run disk health monitoring at system startup
# Also sets up daily reboot schedule

param(
    [string]$RebootTime = "03:00",
    [switch]$RemoveAll
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires administrator privileges." -ForegroundColor Red
    Write-Host "[INFO] Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Startup Disk Monitor Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $env:USERPROFILE "OneDrive\disk-health-monitor.ps1"
$taskName = "StartupDiskHealthMonitor"
$taskPath = "\SystemMaintenance\"

if ($RemoveAll) {
    Write-Host "[INFO] Removing all scheduled tasks..." -ForegroundColor Yellow
    
    # Remove disk monitor task
    try {
        Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "[OK] Removed disk monitor task" -ForegroundColor Green
    } catch {
        Write-Host "[INFO] Disk monitor task not found" -ForegroundColor Gray
    }
    
    # Remove reboot task
    try {
        Unregister-ScheduledTask -TaskName "DailySystemReboot" -TaskPath $taskPath -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "[OK] Removed daily reboot task" -ForegroundColor Green
    } catch {
        Write-Host "[INFO] Reboot task not found" -ForegroundColor Gray
    }
    
    Write-Host "[OK] All tasks removed" -ForegroundColor Green
    exit 0
}

# Verify script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "[ERROR] Disk health monitor script not found: $scriptPath" -ForegroundColor Red
    Write-Host "[INFO] Please ensure disk-health-monitor.ps1 exists" -ForegroundColor Yellow
    exit 1
}

# Remove existing task if it exists
try {
    $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "[INFO] Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
    }
} catch {
    # Task doesn't exist, continue
}

# Create task action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -ExportReport"

# Create trigger (at startup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false

# Create task principal (run as SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task
try {
    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Disk health monitoring at system startup - Monitors Disk 0 (Patriot P410 SSD) and all other disks" | Out-Null
    Write-Host "[OK] Startup disk monitor task created successfully" -ForegroundColor Green
    Write-Host "  Task Name: $taskPath$taskName" -ForegroundColor White
    Write-Host "  Script: $scriptPath" -ForegroundColor White
    Write-Host "  Trigger: At system startup" -ForegroundColor White
} catch {
    Write-Host "[ERROR] Failed to create scheduled task: $_" -ForegroundColor Red
    exit 1
}

# Setup daily reboot schedule
Write-Host ""
Write-Host "Setting up daily reboot schedule..." -ForegroundColor Yellow

$rebootTaskName = "DailySystemReboot"
$rebootAction = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 60 /c `"Scheduled daily reboot - System will restart in 60 seconds`""
$rebootTrigger = New-ScheduledTaskTrigger -Daily -At $RebootTime
$rebootSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
$rebootPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try {
    # Remove existing reboot task if it exists
    try {
        Unregister-ScheduledTask -TaskName $rebootTaskName -TaskPath $taskPath -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}
    
    Register-ScheduledTask -TaskName $rebootTaskName -TaskPath $taskPath -Action $rebootAction -Trigger $rebootTrigger -Settings $rebootSettings -Principal $rebootPrincipal -Description "Daily system reboot for maintenance" | Out-Null
    Write-Host "[OK] Daily reboot schedule created" -ForegroundColor Green
    Write-Host "  Reboot Time: $RebootTime (Daily)" -ForegroundColor White
} catch {
    Write-Host "[WARNING] Failed to create reboot schedule: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configured Tasks:" -ForegroundColor Yellow
Write-Host "  1. Disk Health Monitor - Runs at startup" -ForegroundColor White
Write-Host "  2. Daily Reboot - Runs daily at $RebootTime" -ForegroundColor White
Write-Host ""
Write-Host "To remove all tasks, run:" -ForegroundColor Cyan
Write-Host "  .\setup-startup-disk-monitor.ps1 -RemoveAll" -ForegroundColor White
Write-Host ""
Write-Host "To manually run disk health check:" -ForegroundColor Cyan
Write-Host "  .\disk-health-monitor.ps1 -Detailed -ScanForViruses" -ForegroundColor White
Write-Host ""

# Setup Daily Reboot Schedule
# Creates a scheduled task to reboot the system daily at a specified time
# Also sets up disk health monitoring at startup

param(
    [string]$RebootTime = "03:00",
    [switch]$RemoveSchedule
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires administrator privileges." -ForegroundColor Red
    Write-Host "[INFO] Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Daily Reboot Schedule Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$taskName = "DailySystemReboot"
$taskPath = "\SystemMaintenance\"

if ($RemoveSchedule) {
    Write-Host "[INFO] Removing daily reboot schedule..." -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false -ErrorAction Stop
        Write-Host "[OK] Daily reboot schedule removed" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Task not found or already removed" -ForegroundColor Yellow
    }
    exit 0
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

# Create task action (reboot command)
$action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 60 /c `"Scheduled daily reboot - System will restart in 60 seconds`""

# Create trigger (daily at specified time)
$trigger = New-ScheduledTaskTrigger -Daily -At $RebootTime

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false

# Create task principal (run as SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task
try {
    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Daily system reboot for maintenance" | Out-Null
    Write-Host "[OK] Daily reboot schedule created successfully" -ForegroundColor Green
    Write-Host "  Task Name: $taskPath$taskName" -ForegroundColor White
    Write-Host "  Reboot Time: $RebootTime (Daily)" -ForegroundColor White
    Write-Host "  Warning: System will show 60-second warning before reboot" -ForegroundColor Yellow
} catch {
    Write-Host "[ERROR] Failed to create scheduled task: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To remove this schedule, run:" -ForegroundColor Cyan
Write-Host "  .\setup-daily-reboot.ps1 -RemoveSchedule" -ForegroundColor White
Write-Host ""

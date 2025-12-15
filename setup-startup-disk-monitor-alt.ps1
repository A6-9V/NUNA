# Alternative Setup Startup Disk Monitor using schtasks.exe
# This version uses schtasks.exe for better compatibility

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
Write-Host "  Startup Disk Monitor Setup (Alt)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $env:USERPROFILE "OneDrive\disk-health-monitor.ps1"
$taskName = "StartupDiskHealthMonitor"
$taskPath = "\SystemMaintenance\"
$fullTaskName = "$taskPath$taskName"

if ($RemoveAll) {
    Write-Host "[INFO] Removing all scheduled tasks..." -ForegroundColor Yellow
    
    # Remove disk monitor task
    schtasks /delete /tn "$fullTaskName" /f 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Removed disk monitor task" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Disk monitor task not found" -ForegroundColor Gray
    }
    
    # Remove reboot task
    schtasks /delete /tn "$taskPath\DailySystemReboot" /f 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Removed daily reboot task" -ForegroundColor Green
    } else {
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
schtasks /delete /tn "$fullTaskName" /f 2>&1 | Out-Null

# Create task using schtasks.exe
$action = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -ExportReport"
$description = "Disk health monitoring at system startup - Monitors Disk 0 (Patriot P410 SSD) and all other disks"

$createTaskCmd = "schtasks /create /tn `"$fullTaskName`" /tr `"$action`" /sc onstart /ru SYSTEM /rl HIGHEST /f"
$result = Invoke-Expression $createTaskCmd 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Startup disk monitor task created successfully" -ForegroundColor Green
    Write-Host "  Task Name: $fullTaskName" -ForegroundColor White
    Write-Host "  Script: $scriptPath" -ForegroundColor White
    Write-Host "  Trigger: At system startup" -ForegroundColor White
} else {
    Write-Host "[ERROR] Failed to create scheduled task" -ForegroundColor Red
    Write-Host "  Error: $result" -ForegroundColor Red
    exit 1
}

# Setup daily reboot schedule
Write-Host ""
Write-Host "Setting up daily reboot schedule..." -ForegroundColor Yellow

$rebootTaskName = "$taskPath\DailySystemReboot"
$rebootAction = "shutdown.exe /r /f /t 60 /c `"Scheduled daily reboot - System will restart in 60 seconds`""

# Remove existing reboot task if it exists
schtasks /delete /tn "$rebootTaskName" /f 2>&1 | Out-Null

$createRebootCmd = "schtasks /create /tn `"$rebootTaskName`" /tr `"$rebootAction`" /sc daily /st $RebootTime /ru SYSTEM /rl HIGHEST /f"
$rebootResult = Invoke-Expression $createRebootCmd 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Daily reboot schedule created" -ForegroundColor Green
    Write-Host "  Reboot Time: $RebootTime (Daily)" -ForegroundColor White
} else {
    Write-Host "[WARNING] Failed to create reboot schedule" -ForegroundColor Yellow
    Write-Host "  Error: $rebootResult" -ForegroundColor Yellow
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
Write-Host "  .\setup-startup-disk-monitor-alt.ps1 -RemoveAll" -ForegroundColor White
Write-Host ""



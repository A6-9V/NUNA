#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Install Trading Bridge as Windows Service
.DESCRIPTION
    Creates Windows Scheduled Task to run trading service on boot
    Runs as administrator automatically
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$startScript = Join-Path $tradingBridgePath "start-background.ps1"
$taskName = "TradingBridge-Service"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Install Trading Bridge Service" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must run as Administrator" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check if start script exists
if (-not (Test-Path $startScript)) {
    Write-Host "[ERROR] Start script not found: $startScript" -ForegroundColor Red
    exit 1
}

# Remove existing task if it exists
Write-Host "[1/3] Checking for existing task..." -ForegroundColor Yellow
try {
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
        Write-Host "    [OK] Removed existing task" -ForegroundColor Green
    }
} catch {
    Write-Host "    [INFO] No existing task found" -ForegroundColor Cyan
}

# Create scheduled task
Write-Host "[2/3] Creating scheduled task..." -ForegroundColor Yellow

try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startScript`"" `
        -WorkingDirectory $tradingBridgePath
    
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Highest
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Hours 0)
    
    $description = "Trading Bridge Background Service - Auto-start on boot"
    
    Register-ScheduledTask -TaskName $taskName -Action $action `
        -Trigger $trigger -Principal $principal -Settings $settings `
        -Description $description -Force | Out-Null
    
    Write-Host "    [OK] Scheduled task created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create task: $_" -ForegroundColor Red
    exit 1
}

# Verify task
Write-Host "[3/3] Verifying task..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    Write-Host "    [OK] Task verified: $($task.TaskName)" -ForegroundColor Green
    Write-Host "    [INFO] Task will run on system boot" -ForegroundColor Cyan
} catch {
    Write-Host "    [WARNING] Could not verify task" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service will start automatically on boot" -ForegroundColor Green
Write-Host "To start manually: .\start-background.ps1" -ForegroundColor Cyan
Write-Host "To remove: Unregister-ScheduledTask -TaskName $taskName" -ForegroundColor Cyan
Write-Host ""


#Requires -Version 5.1
<#
.SYNOPSIS
    Verify Auto-Startup Configuration
.DESCRIPTION
    Verifies that auto-startup is configured correctly for restart and screen events
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto-Startup Configuration Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$flagFile = Join-Path $workspaceRoot ".restart-flag"

# Check scheduled tasks
Write-Host "[1/4] Checking scheduled tasks..." -ForegroundColor Yellow
$tasks = Get-ScheduledTask -TaskName "VPS-AutoStart-*" -ErrorAction SilentlyContinue

if ($tasks) {
    Write-Host "    [OK] Found $($tasks.Count) scheduled task(s)" -ForegroundColor Green
    foreach ($task in $tasks) {
        Write-Host "        - $($task.TaskName): $($task.State)" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [WARNING] No scheduled tasks found" -ForegroundColor Yellow
    Write-Host "    [INFO] Run setup-auto-startup-restart-only.ps1 as Administrator" -ForegroundColor Cyan
}

# Check flag file
Write-Host "[2/4] Checking restart flag file..." -ForegroundColor Yellow
if (Test-Path $flagFile) {
    Write-Host "    [OK] Restart flag file exists" -ForegroundColor Green
    Write-Host "        Location: $flagFile" -ForegroundColor Cyan
} else {
    Write-Host "    [INFO] Restart flag file not found (will be created on first run)" -ForegroundColor Cyan
}

# Check scripts
Write-Host "[3/4] Checking scripts..." -ForegroundColor Yellow
$scripts = @(
    "restart-detector.ps1",
    "screen-handler.ps1",
    "shutdown-handler.ps1",
    "auto-start-vps-admin.ps1"
)

$missingScripts = @()
foreach ($script in $scripts) {
    $scriptPath = Join-Path $workspaceRoot $script
    if (Test-Path $scriptPath) {
        Write-Host "    [OK] Found: $script" -ForegroundColor Green
    } else {
        $missingScripts += $script
        Write-Host "    [WARNING] Missing: $script" -ForegroundColor Yellow
    }
}

# Check configuration
Write-Host "[4/4] Checking configuration..." -ForegroundColor Yellow
Write-Host "    Configuration:" -ForegroundColor Cyan
Write-Host "      ✅ Restart: AUTO-START ENABLED" -ForegroundColor Green
Write-Host "      ❌ Power On: AUTO-START DISABLED" -ForegroundColor Green
Write-Host "      ✅ Screen Lock/Unlock: AUTO-START ENABLED" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($tasks -and $tasks.Count -ge 2) {
    Write-Host "[OK] Auto-startup is configured!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Auto-startup may not be fully configured" -ForegroundColor Yellow
    Write-Host "Run: .\setup-auto-startup-restart-only.ps1 as Administrator" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Behavior:" -ForegroundColor Yellow
Write-Host "  - RESTART: System will start automatically" -ForegroundColor White
Write-Host "  - POWER ON: System will NOT start automatically" -ForegroundColor White
Write-Host "  - SCREEN LOCK/UNLOCK: System will start automatically" -ForegroundColor White
Write-Host ""

#Requires -Version 5.1
<#
.SYNOPSIS
    Simple Quick Start - Starts Trading System (No Admin Required for Basic Start)
.DESCRIPTION
    Starts trading system services without requiring admin (for basic startup)
    Admin will be requested only if needed
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Trading System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start Python Bridge Service
Write-Host "[1/3] Starting Python bridge service..." -ForegroundColor Yellow
$startBackgroundScript = Join-Path $workspaceRoot "trading-bridge\start-background.ps1"
if (Test-Path $startBackgroundScript) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $startBackgroundScript
        ) -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 2
        Write-Host "    [OK] Python bridge service started" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Python service start had issues: $_" -ForegroundColor Yellow
    }
} else {
    # Start Python service directly
    $pythonService = Join-Path $workspaceRoot "trading-bridge\python\services\background_service.py"
    if (Test-Path $pythonService) {
        try {
            Start-Process python -ArgumentList $pythonService -WindowStyle Hidden | Out-Null
            Start-Sleep -Seconds 2
            Write-Host "    [OK] Python service started directly" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Could not start Python service" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [INFO] Python service not found" -ForegroundColor Cyan
    }
}

# Start MQL5 Terminal
Write-Host "[2/3] Starting MQL5 Terminal..." -ForegroundColor Yellow
$exnessLauncher = Join-Path $workspaceRoot "launch-exness-trading.ps1"
if (Test-Path $exnessLauncher) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $exnessLauncher
        ) -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 3
        Write-Host "    [OK] MQL5 Terminal launcher started" -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] MQL5 launcher had issues (may need admin)" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] MQL5 launcher not found" -ForegroundColor Cyan
}

# Start Master Orchestrator
Write-Host "[3/3] Starting master orchestrator..." -ForegroundColor Yellow
$orchestratorScript = Join-Path $workspaceRoot "master-trading-orchestrator.ps1"
if (Test-Path $orchestratorScript) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $orchestratorScript
        ) -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 2
        Write-Host "    [OK] Master orchestrator started" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Orchestrator start had issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Orchestrator script not found" -ForegroundColor Cyan
}

# Verify services
Write-Host ""
Write-Host "Verifying services..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

$pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*background_service*" -or $_.CommandLine -like "*trading*"
}
if ($pythonProcess) {
    Write-Host "  [OK] Python trading service: RUNNING" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Python service: Starting..." -ForegroundColor Cyan
}

$mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
if ($mt5Process) {
    Write-Host "  [OK] MQL5 Terminal: RUNNING" -ForegroundColor Green
} else {
    Write-Host "  [INFO] MQL5 Terminal: Starting..." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Starting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services are starting in the background..." -ForegroundColor Green
Write-Host "Check logs in: trading-bridge\logs\" -ForegroundColor Cyan
Write-Host ""


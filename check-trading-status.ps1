#Requires -Version 5.1
<#
.SYNOPSIS
    Check Trading System Status
.DESCRIPTION
    Quick status check of all trading system components
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Python Bridge Service
Write-Host "[1/5] Python Bridge Service..." -ForegroundColor Yellow
$pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*background_service*" -or 
    $_.CommandLine -like "*trading*" -or
    $_.CommandLine -like "*bridge*"
}
if ($pythonProcess) {
    Write-Host "    [OK] RUNNING (PID: $($pythonProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] NOT RUNNING" -ForegroundColor Yellow
    Write-Host "    Start with: .\QUICK-START-SIMPLE.ps1" -ForegroundColor Cyan
}

# Check MQL5 Terminal
Write-Host "[2/5] MQL5 Terminal..." -ForegroundColor Yellow
$mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
if ($mt5Process) {
    Write-Host "    [OK] RUNNING (PID: $($mt5Process.Id))" -ForegroundColor Green
} else {
    Write-Host "    [INFO] NOT RUNNING" -ForegroundColor Cyan
    Write-Host "    Start with: .\launch-exness-trading.ps1" -ForegroundColor Cyan
}

# Check Master Orchestrator
Write-Host "[3/5] Master Orchestrator..." -ForegroundColor Yellow
$orchestratorProcess = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*master-trading-orchestrator*"
}
if ($orchestratorProcess) {
    Write-Host "    [OK] RUNNING (PID: $($orchestratorProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [INFO] NOT DETECTED (may be running)" -ForegroundColor Cyan
}

# Check VPS Services
Write-Host "[4/5] VPS Services..." -ForegroundColor Yellow
$vpsProcesses = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*vps-services*" -or
    $_.CommandLine -like "*exness-service*"
}
if ($vpsProcesses) {
    Write-Host "    [OK] RUNNING ($($vpsProcesses.Count) service(s))" -ForegroundColor Green
} else {
    Write-Host "    [INFO] VPS services not detected" -ForegroundColor Cyan
}

# Check Logs
Write-Host "[5/5] Log Files..." -ForegroundColor Yellow
$logsPath = Join-Path $workspaceRoot "trading-bridge\logs"
if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" -ErrorAction SilentlyContinue
    if ($logFiles) {
        $latestLog = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host "    [OK] Logs found: $($logFiles.Count) file(s)" -ForegroundColor Green
        Write-Host "    Latest: $($latestLog.Name) ($(($latestLog.LastWriteTime).ToString('yyyy-MM-dd HH:mm:ss')))" -ForegroundColor Cyan
    } else {
        Write-Host "    [INFO] No log files yet" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] Logs directory not created" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Status Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start everything:" -ForegroundColor Yellow
Write-Host "  .\QUICK-START-SIMPLE.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To start with full setup:" -ForegroundColor Yellow
Write-Host "  .\QUICK-START-TRADING-SYSTEM.ps1 (requires admin)" -ForegroundColor White
Write-Host ""


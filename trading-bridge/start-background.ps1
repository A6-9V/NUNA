#Requires -Version 5.1
<#
.SYNOPSIS
    Start Trading Bridge Background Service
.DESCRIPTION
    Starts Python trading service in background (hidden window)
    Monitors and restarts if needed
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$pythonServicePath = Join-Path $tradingBridgePath "python\services\background_service.py"
$logsPath = Join-Path $tradingBridgePath "logs"

Write-Host "Starting Trading Bridge Background Service..." -ForegroundColor Cyan

# Check if Python is installed
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "[ERROR] Python not found!" -ForegroundColor Red
    Write-Host "Please install Python and add it to PATH" -ForegroundColor Yellow
    exit 1
}

# Check if service script exists
if (-not (Test-Path $pythonServicePath)) {
    Write-Host "[ERROR] Service script not found: $pythonServicePath" -ForegroundColor Red
    exit 1
}

# Check if service is already running
$existingProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*background_service.py*"
}

if ($existingProcess) {
    Write-Host "[INFO] Service is already running (PID: $($existingProcess.Id))" -ForegroundColor Yellow
    exit 0
}

# Start Python service in background
Write-Host "[INFO] Starting Python service..." -ForegroundColor Yellow

try {
    $process = Start-Process python -ArgumentList $pythonServicePath `
        -WindowStyle Hidden `
        -PassThru `
        -ErrorAction Stop
    
    Start-Sleep -Seconds 2
    
    if ($process -and -not $process.HasExited) {
        Write-Host "[OK] Service started (PID: $($process.Id))" -ForegroundColor Green
        Write-Host "Logs: $logsPath" -ForegroundColor Cyan
    } else {
        Write-Host "[ERROR] Service failed to start" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Failed to start service: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Service is running in background" -ForegroundColor Green
Write-Host "To stop: Stop-Process -Id $($process.Id)" -ForegroundColor Cyan


# Start MQL.io Service
# Launches the MQL.io service for MQL5 operations management

param(
    [switch]$Background = $false
)

Write-Host "[INFO] Starting MQL.io Service..." -ForegroundColor Cyan

# Set location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$tradingBridgePath = Join-Path $scriptPath "trading-bridge"
$pythonPath = Join-Path $tradingBridgePath "python"

if (-not (Test-Path $pythonPath)) {
    Write-Host "[ERROR] Python directory not found: $pythonPath" -ForegroundColor Red
    exit 1
}

Set-Location $pythonPath

# Check Python installation
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found. Please install Python 3.8+" -ForegroundColor Red
    exit 1
}

# Check dependencies
Write-Host "[INFO] Checking dependencies..." -ForegroundColor Cyan
$requirementsPath = Join-Path $tradingBridgePath "requirements.txt"

if (Test-Path $requirementsPath) {
    try {
        pip show pyzmq | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARNING] Installing dependencies..." -ForegroundColor Yellow
            pip install -r $requirementsPath
        } else {
            Write-Host "[OK] Dependencies installed" -ForegroundColor Green
        }
    } catch {
        Write-Host "[WARNING] Could not verify dependencies" -ForegroundColor Yellow
    }
}

# Check configuration
$configPath = Join-Path $tradingBridgePath "config\mql_io.json"
$configExamplePath = Join-Path $tradingBridgePath "config\mql_io.json.example"

if (-not (Test-Path $configPath)) {
    if (Test-Path $configExamplePath) {
        Write-Host "[INFO] Creating default configuration..." -ForegroundColor Cyan
        Copy-Item $configExamplePath $configPath
        Write-Host "[OK] Configuration created. Please review: $configPath" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] No configuration file found. Using defaults." -ForegroundColor Yellow
    }
}

# Start service
Write-Host "`n[INFO] Launching MQL.io Service..." -ForegroundColor Cyan
Write-Host "[INFO] Service will manage MQL5 operations" -ForegroundColor Cyan
Write-Host "[INFO] Press Ctrl+C to stop the service" -ForegroundColor Yellow
Write-Host ""

try {
    if ($Background) {
        # Start in background
        $process = Start-Process -FilePath "python" -ArgumentList "-m", "mql_io.mql_io_service" -NoNewWindow -PassThru
        Write-Host "[OK] MQL.io Service started in background (PID: $($process.Id))" -ForegroundColor Green
        Write-Host "[INFO] Check logs: trading-bridge/logs/mql_io_service_*.log" -ForegroundColor Cyan
    } else {
        # Start in foreground
        python -m mql_io.mql_io_service
    }
} catch {
    Write-Host "[ERROR] Failed to start MQL.io service: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n[INFO] MQL.io Service stopped" -ForegroundColor Cyan

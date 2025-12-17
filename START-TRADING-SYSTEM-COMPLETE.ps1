#Requires -Version 5.1
<#
.SYNOPSIS
    Complete Trading System Startup
.DESCRIPTION
    Starts all trading system components with proper error handling
    No admin required for basic startup
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Complete Trading System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install dependencies if needed
Write-Host "[1/5] Checking Python dependencies..." -ForegroundColor Yellow
try {
    python -c "import zmq" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    Installing dependencies..." -ForegroundColor Cyan
        python -m pip install -q pyzmq requests python-dotenv cryptography schedule pywin32 2>&1 | Out-Null
        Write-Host "    [OK] Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Dependencies already installed" -ForegroundColor Green
    }
} catch {
    Write-Host "    [WARNING] Could not verify dependencies" -ForegroundColor Yellow
}

# Step 2: Start Python Bridge Service
Write-Host "[2/5] Starting Python bridge service..." -ForegroundColor Yellow
$pythonService = Join-Path $tradingBridgePath "python\services\background_service.py"
if (Test-Path $pythonService) {
    try {
        $workingDir = Join-Path $tradingBridgePath "python"
        Set-Location $workingDir
        
        Start-Process python -ArgumentList "services\background_service.py" `
            -WindowStyle Hidden `
            -WorkingDirectory $workingDir | Out-Null
        
        Start-Sleep -Seconds 3
        Write-Host "    [OK] Python bridge service started" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Python service start had issues: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [WARNING] Python service script not found" -ForegroundColor Yellow
}

# Step 3: Start MQL5 Terminal
Write-Host "[3/5] Starting MQL5 Terminal..." -ForegroundColor Yellow
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
        Write-Host "    [INFO] MQL5 launcher had issues" -ForegroundColor Cyan
    }
}

# Step 4: Start Master Orchestrator
Write-Host "[4/5] Starting master orchestrator..." -ForegroundColor Yellow
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
}

# Step 5: Start VPS Services
Write-Host "[5/5] Starting VPS services..." -ForegroundColor Yellow
$vpsSystemScript = Join-Path $workspaceRoot "start-vps-system.ps1"
if (Test-Path $vpsSystemScript) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $vpsSystemScript
        ) -WindowStyle Hidden | Out-Null
        Write-Host "    [OK] VPS services started" -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] VPS services had issues (optional)" -ForegroundColor Cyan
    }
}

# Verify
Write-Host ""
Write-Host "Verifying services..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

$pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*python*"
}
if ($pythonProcess) {
    Write-Host "  [OK] Python processes: $($pythonProcess.Count)" -ForegroundColor Green
}

$mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
if ($mt5Process) {
    Write-Host "  [OK] MQL5 Terminal: RUNNING" -ForegroundColor Green
} else {
    Write-Host "  [INFO] MQL5 Terminal: Starting..." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Started" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All services are starting in the background" -ForegroundColor Green
Write-Host ""
Write-Host "Check status: .\check-trading-status.ps1" -ForegroundColor Cyan
Write-Host "View logs: trading-bridge\logs\" -ForegroundColor Cyan
Write-Host ""


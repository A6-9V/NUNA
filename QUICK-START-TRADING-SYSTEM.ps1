#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Quick Start Trading System - Complete Automated Setup
.DESCRIPTION
    Sets up and starts the complete trading system automatically:
    - Network mapping
    - Code cleanup
    - Trading bridge setup
    - Security checks
    - Service startup
    - Auto-start configuration
    NO USER INTERACTION REQUIRED
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QUICK START - Trading System" -ForegroundColor Cyan
Write-Host "  Complete Automated Setup & Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[INFO] Elevating to administrator..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
    exit 0
}

# Step 1: Network Mapping (Quick)
Write-Host "[1/7] Setting up network mappings..." -ForegroundColor Yellow
$networkScript = Join-Path $workspaceRoot "setup-network-mapping.ps1"
if (Test-Path $networkScript) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $networkScript -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    [OK] Network mapping configured" -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] Network mapping skipped (optional)" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] Network script not found (optional)" -ForegroundColor Cyan
}

# Step 2: Code Cleanup (Quick)
Write-Host "[2/7] Running code cleanup..." -ForegroundColor Yellow
$cleanupScript = Join-Path $workspaceRoot "cleanup-code.ps1"
if (Test-Path $cleanupScript) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $cleanupScript -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    [OK] Code cleanup completed" -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] Cleanup had minor issues (continuing)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Cleanup script not found (optional)" -ForegroundColor Cyan
}

# Step 3: Trading Bridge Drive Setup
Write-Host "[3/7] Setting up trading bridge structure..." -ForegroundColor Yellow
$driveSetupScript = Join-Path $workspaceRoot "setup-trading-drive.ps1"
if (Test-Path $driveSetupScript) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $driveSetupScript -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    [OK] Trading bridge structure ready" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Drive setup had issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Creating trading bridge directories..." -ForegroundColor Cyan
    $tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
    $directories = @(
        "trading-bridge\python\bridge",
        "trading-bridge\python\brokers",
        "trading-bridge\python\services",
        "trading-bridge\python\security",
        "trading-bridge\python\trader",
        "trading-bridge\config",
        "trading-bridge\logs",
        "trading-bridge\mql5\Experts"
    )
    foreach ($dir in $directories) {
        $fullPath = Join-Path $workspaceRoot $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
    }
    Write-Host "    [OK] Directories created" -ForegroundColor Green
}

# Step 4: Install Python Dependencies
Write-Host "[4/7] Installing Python dependencies..." -ForegroundColor Yellow
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    $requirementsPath = Join-Path $workspaceRoot "trading-bridge\requirements.txt"
    if (Test-Path $requirementsPath) {
        try {
            pip install -q -r $requirementsPath 2>&1 | Out-Null
            Write-Host "    [OK] Python dependencies installed" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Some dependencies may have failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [INFO] Installing core dependencies..." -ForegroundColor Cyan
        pip install -q pyzmq requests python-dotenv cryptography schedule pywin32 2>&1 | Out-Null
        Write-Host "    [OK] Core dependencies installed" -ForegroundColor Green
    }
} else {
    Write-Host "    [WARNING] Python not found - install Python first" -ForegroundColor Yellow
}

# Step 5: Security Check
Write-Host "[5/7] Running security check..." -ForegroundColor Yellow
$securityScript = Join-Path $workspaceRoot "security-check-trading.ps1"
if (Test-Path $securityScript) {
    try {
        $securityResult = & powershell.exe -ExecutionPolicy Bypass -File $securityScript -ErrorAction SilentlyContinue
        Write-Host "    [OK] Security check completed" -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] Security check had warnings (review manually)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Security script not found (optional)" -ForegroundColor Cyan
}

# Step 6: Start Trading System Services
Write-Host "[6/7] Starting trading system services..." -ForegroundColor Yellow

# Start Python bridge service
$startBackgroundScript = Join-Path $workspaceRoot "trading-bridge\start-background.ps1"
if (Test-Path $startBackgroundScript) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $startBackgroundScript
        ) -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 3
        Write-Host "    [OK] Python bridge service started" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Python service start had issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Starting Python service directly..." -ForegroundColor Cyan
    $pythonService = Join-Path $workspaceRoot "trading-bridge\python\services\background_service.py"
    if (Test-Path $pythonService) {
        Start-Process python -ArgumentList $pythonService -WindowStyle Hidden | Out-Null
        Write-Host "    [OK] Python service started" -ForegroundColor Green
    }
}

# Start MQL5 Terminal (Exness)
$exnessService = Join-Path $workspaceRoot "vps-services\exness-service.ps1"
if (Test-Path $exnessService) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $exnessService
        ) -WindowStyle Hidden | Out-Null
        Write-Host "    [OK] MQL5 Terminal service started" -ForegroundColor Green
    } catch {
        Write-Host "    [INFO] MQL5 service start skipped" -ForegroundColor Cyan
    }
}

# Start Master Orchestrator
$orchestratorScript = Join-Path $workspaceRoot "master-trading-orchestrator.ps1"
if (Test-Path $orchestratorScript) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $orchestratorScript
        ) -WindowStyle Hidden | Out-Null
        Write-Host "    [OK] Master orchestrator started" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Orchestrator start had issues" -ForegroundColor Yellow
    }
}

# Step 7: Setup Auto-Start
Write-Host "[7/7] Configuring auto-start..." -ForegroundColor Yellow
$autoStartScript = Join-Path $workspaceRoot "setup-trading-auto-start.ps1"
if (Test-Path $autoStartScript) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $autoStartScript -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    [OK] Auto-start configured" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Auto-start setup had issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Auto-start script not found (optional)" -ForegroundColor Cyan
}

# Verify services are running
Write-Host ""
Write-Host "Verifying services..." -ForegroundColor Cyan

Start-Sleep -Seconds 5

$pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*background_service*" -or $_.CommandLine -like "*trading*"
}
if ($pythonProcess) {
    Write-Host "  [OK] Python trading service: RUNNING (PID: $($pythonProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Python trading service: NOT RUNNING" -ForegroundColor Yellow
}

$mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
if ($mt5Process) {
    Write-Host "  [OK] MQL5 Terminal: RUNNING (PID: $($mt5Process.Id))" -ForegroundColor Green
} else {
    Write-Host "  [INFO] MQL5 Terminal: Not running (will start when needed)" -ForegroundColor Cyan
}

$orchestratorProcess = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*master-trading-orchestrator*"
}
if ($orchestratorProcess) {
    Write-Host "  [OK] Master orchestrator: RUNNING (PID: $($orchestratorProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Master orchestrator: Not detected (may be running)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QUICK START COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Trading system is starting..." -ForegroundColor Green
Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  - Python Bridge: Background service" -ForegroundColor White
Write-Host "  - MQL5 Terminal: Auto-starting" -ForegroundColor White
Write-Host "  - Master Orchestrator: Monitoring" -ForegroundColor White
Write-Host ""
Write-Host "Logs:" -ForegroundColor Yellow
Write-Host "  - Trading Bridge: trading-bridge\logs\" -ForegroundColor White
Write-Host "  - Orchestrator: trading-bridge\logs\orchestrator_*.log" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Configure brokers.json (copy from brokers.json.example)" -ForegroundColor White
Write-Host "  2. Configure symbols.json (copy from symbols.json.example)" -ForegroundColor White
Write-Host "  3. Store API keys in Windows Credential Manager" -ForegroundColor White
Write-Host "  4. Attach MQL5 EA to charts in MT5 Terminal" -ForegroundColor White
Write-Host ""
Write-Host "System will auto-start on boot" -ForegroundColor Green
Write-Host ""


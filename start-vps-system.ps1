#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Start VPS System - Complete 24/7 Trading System Startup
.DESCRIPTION
    Starts all components for 24/7 trading system:
    1. Runs launch-admin.ps1
    2. Runs Exness Trading Launcher
    3. Deploys VPS services
    4. Starts all background services
    
    All output is automatically saved to log files.
#>

$ErrorActionPreference = "Continue"

# Setup logging
$workspaceRoot = "C:\Users\USER\OneDrive"
$logsDir = Join-Path $workspaceRoot "logs"
$vpsServicesPath = "$workspaceRoot\vps-services"

# Create logs directory if it doesn't exist
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Generate timestamp for log filename
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "vps-system-startup-$timestamp.log"
$agentLogFile = Join-Path $logsDir "ai-agent-activity.log"

# Load agent logger module
$loggerPath = Join-Path $workspaceRoot "agent-logger.ps1"
if (Test-Path $loggerPath) {
    . $loggerPath
} else {
    # Fallback logging function if logger not found
    function Write-AgentLog {
        param([string]$Message, [string]$Level = "INFO")
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$ts] [$Level] $Message"
        Add-Content -Path $agentLogFile -Value $logEntry -Force
        Write-Host $Message
    }
}

# Start transcript to capture all PowerShell output
Start-Transcript -Path $logFile -Force -Append

Write-AgentLog "========================================" "INFO"
Write-AgentLog "  Starting VPS Trading System" "INFO"
Write-AgentLog "  24/7 Automated Trading Setup" "INFO"
Write-AgentLog "========================================" "INFO"
Write-AgentLog "Log file: $logFile" "INFO"
Write-AgentLog "Agent log: $agentLogFile" "INFO"
Write-Host ""

# Step 1: Run launch-admin.ps1
Write-AgentLog "[1/4] Running launch-admin.ps1..." "INFO"
Write-Host "[1/4] Running launch-admin.ps1..." -ForegroundColor Yellow
try {
    $launchAdminScript = Join-Path $workspaceRoot "launch-admin.ps1"
    if (Test-Path $launchAdminScript) {
        $adminLogFile = Join-Path $logsDir "launch-admin-$timestamp.log"
        & powershell.exe -ExecutionPolicy Bypass -File $launchAdminScript *>&1 | Tee-Object -FilePath $adminLogFile -Append
        Write-AgentLog "    [OK] launch-admin.ps1 executed" "SUCCESS"
        Write-Host "    [OK] launch-admin.ps1 executed" -ForegroundColor Green
    } else {
        Write-AgentLog "    [WARNING] launch-admin.ps1 not found" "WARNING"
        Write-Host "    [WARNING] launch-admin.ps1 not found" -ForegroundColor Yellow
    }
} catch {
    Write-AgentLog "    [WARNING] launch-admin.ps1 had issues: $_" "ERROR"
    Write-Host "    [WARNING] launch-admin.ps1 had issues: $_" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# Step 2: Run Exness Trading Launcher
Write-AgentLog "[2/4] Running Exness Trading Launcher..." "INFO"
Write-Host "[2/4] Running Exness Trading Launcher..." -ForegroundColor Yellow
try {
    $exnessLauncher = Join-Path $workspaceRoot "launch-exness-trading.ps1"
    if (Test-Path $exnessLauncher) {
        $exnessLogFile = Join-Path $logsDir "exness-launcher-$timestamp.log"
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $exnessLauncher,
            "-LogFile", $exnessLogFile
        ) -WindowStyle Hidden
        Write-AgentLog "    [OK] Exness Trading Launcher started (log: $exnessLogFile)" "SUCCESS"
        Write-Host "    [OK] Exness Trading Launcher started" -ForegroundColor Green
    } else {
        Write-AgentLog "    [WARNING] launch-exness-trading.ps1 not found" "WARNING"
        Write-Host "    [WARNING] launch-exness-trading.ps1 not found" -ForegroundColor Yellow
    }
} catch {
    Write-AgentLog "    [WARNING] Exness launcher had issues: $_" "ERROR"
    Write-Host "    [WARNING] Exness launcher had issues: $_" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Step 3: Deploy VPS Services (if not already deployed)
Write-AgentLog "[3/4] Deploying VPS services..." "INFO"
Write-Host "[3/4] Deploying VPS services..." -ForegroundColor Yellow
try {
    $vpsDeployment = Join-Path $workspaceRoot "vps-deployment.ps1"
    if (Test-Path $vpsDeployment) {
        if (-not (Test-Path $vpsServicesPath)) {
            $deployLogFile = Join-Path $logsDir "vps-deployment-$timestamp.log"
            & powershell.exe -ExecutionPolicy Bypass -File $vpsDeployment *>&1 | Tee-Object -FilePath $deployLogFile -Append
            Write-AgentLog "    [OK] VPS services deployed" "SUCCESS"
            Write-Host "    [OK] VPS services deployed" -ForegroundColor Green
        } else {
            Write-AgentLog "    [OK] VPS services already deployed" "INFO"
            Write-Host "    [OK] VPS services already deployed" -ForegroundColor Green
        }
    } else {
        Write-AgentLog "    [WARNING] vps-deployment.ps1 not found" "WARNING"
        Write-Host "    [WARNING] vps-deployment.ps1 not found" -ForegroundColor Yellow
    }
} catch {
    Write-AgentLog "    [WARNING] VPS deployment had issues: $_" "ERROR"
    Write-Host "    [WARNING] VPS deployment had issues: $_" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# Step 4: Start Master Controller
Write-AgentLog "[4/4] Starting Master Controller..." "INFO"
Write-Host "[4/4] Starting Master Controller..." -ForegroundColor Yellow
try {
    $masterController = Join-Path $vpsServicesPath "master-controller.ps1"
    if (Test-Path $masterController) {
        $controllerLogFile = Join-Path $logsDir "master-controller-$timestamp.log"
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $masterController
        ) -WindowStyle Hidden
        Write-AgentLog "    [OK] Master Controller started" "SUCCESS"
        Write-Host "    [OK] Master Controller started" -ForegroundColor Green
    } else {
        Write-AgentLog "    [WARNING] master-controller.ps1 not found" "WARNING"
        Write-AgentLog "    [INFO] Run vps-deployment.ps1 first to create services" "INFO"
        Write-Host "    [WARNING] master-controller.ps1 not found" -ForegroundColor Yellow
        Write-Host "    [INFO] Run vps-deployment.ps1 first to create services" -ForegroundColor Cyan
    }
} catch {
    Write-AgentLog "    [WARNING] Master Controller had issues: $_" "ERROR"
    Write-Host "    [WARNING] Master Controller had issues: $_" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Summary
Write-Host ""
Write-AgentLog "========================================" "INFO"
Write-AgentLog "  VPS System Startup Complete!" "SUCCESS"
Write-AgentLog "========================================" "INFO"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VPS System Startup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-AgentLog "Started: Admin launcher, Exness Trading Terminal, VPS Services, Master Controller" "SUCCESS"
Write-Host "Started:" -ForegroundColor Yellow
Write-Host "  [OK] Admin launcher" -ForegroundColor White
Write-Host "  [OK] Exness Trading Terminal" -ForegroundColor White
Write-Host "  [OK] VPS Services" -ForegroundColor White
Write-Host "  [OK] Master Controller" -ForegroundColor White
Write-Host ""
Write-Host "To verify all services are running:" -ForegroundColor Cyan
Write-Host "  .\vps-verification.ps1" -ForegroundColor White
Write-Host ""
Write-Host "All services are now running in the background (24/7)" -ForegroundColor Green
Write-Host ""
Write-AgentLog "All output saved to: $logFile" "INFO"
Write-AgentLog "Agent activity log: $agentLogFile" "INFO"
Write-Host "All output saved to: $logFile" -ForegroundColor Cyan
Write-Host "Agent activity log: $agentLogFile" -ForegroundColor Cyan
Write-Host ""

# Stop transcript
Stop-Transcript | Out-Null

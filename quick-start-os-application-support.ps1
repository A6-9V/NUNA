# Quick Start Script
# One-command setup and deployment

param(
    [switch]$SetupOnly,
    [switch]$DeployOnly,
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OS Application Support - Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[INFO] Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Wait
    exit
}

Write-Host "[OK] Running with administrator privileges" -ForegroundColor Green
Write-Host ""

# Step 1: Setup
if (-not $DeployOnly) {
    Write-Host "[STEP 1] Running complete setup..." -ForegroundColor Yellow
    Write-Host ""
    
    $orchestrator = Join-Path $PSScriptRoot "master-orchestrator.ps1"
    if (Test-Path $orchestrator) {
        & $orchestrator -Action setup
        Write-Host ""
    } else {
        Write-Host "[ERROR] Master orchestrator not found" -ForegroundColor Red
        exit 1
    }
    
    if ($SetupOnly) {
        Write-Host "[OK] Setup complete! Run without -SetupOnly to deploy." -ForegroundColor Green
        exit
    }
}

# Step 2: Deploy
if (-not $SkipDeploy) {
    Write-Host "[STEP 2] Deploying to GitHub..." -ForegroundColor Yellow
    Write-Host ""
    
    $deployScript = Join-Path $PSScriptRoot "deploy-os-application-support.ps1"
    if (Test-Path $deployScript) {
        & $deployScript -FullDeploy -RunAsAdmin
        Write-Host ""
    } else {
        Write-Host "[ERROR] Deploy script not found" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Start system
Write-Host "[STEP 3] Starting system..." -ForegroundColor Yellow
Write-Host ""

$orchestrator = Join-Path $PSScriptRoot "master-orchestrator.ps1"
if (Test-Path $orchestrator) {
    & $orchestrator -Action start
    Write-Host ""
}

# Step 4: Show status
Write-Host "[STEP 4] System Status..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path $orchestrator) {
    & $orchestrator -Action status
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[OK] Quick Start Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "System is now running and will start automatically on boot." -ForegroundColor Cyan
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  Status:  .\master-orchestrator.ps1 -Action status" -ForegroundColor White
Write-Host "  Stop:    .\master-orchestrator.ps1 -Action stop" -ForegroundColor White
Write-Host "  Restart: .\master-orchestrator.ps1 -Action restart" -ForegroundColor White
Write-Host "  Deploy:  .\deploy-os-application-support.ps1 -FullDeploy -RunAsAdmin" -ForegroundColor White
Write-Host ""

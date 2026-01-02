# Master Orchestrator
# Manages and orchestrates the entire OS Application Support system

param(
    [ValidateSet("setup", "start", "stop", "restart", "status", "deploy", "update")]
    [string]$Action = "status",
    [switch]$RunAsAdmin
)

$ErrorActionPreference = "Continue"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OS Application Support - Master Orchestrator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and $RunAsAdmin) {
    Write-Host "[INFO] Restarting with administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action $Action" -Wait
    exit
}

function Setup-System {
    Write-Host "[SETUP] Initializing system setup..." -ForegroundColor Yellow
    Write-Host ""
    
    # Run all setup scripts
    $setupScripts = @(
        "setup-os-application-support.ps1",
        "setup-remote-device.ps1",
        "setup-trading-system.ps1",
        "setup-security.ps1",
        "setup-monitoring.ps1"
    )
    
    foreach ($script in $setupScripts) {
        $scriptPath = Join-Path $PSScriptRoot $script
        if (Test-Path $scriptPath) {
            Write-Host "[INFO] Running: $script" -ForegroundColor Cyan
            & $scriptPath
            Write-Host ""
        }
    }
    
    # Setup auto-startup
    Write-Host "[INFO] Setting up auto-startup..." -ForegroundColor Cyan
    $startupScript = Join-Path $PSScriptRoot "setup-auto-startup-admin.ps1"
    if (Test-Path $startupScript) {
        & $startupScript
    }
    
    Write-Host "[OK] System setup complete!" -ForegroundColor Green
}

function Start-System {
    Write-Host "[START] Starting all services..." -ForegroundColor Yellow
    
    $startupScript = Join-Path $script:RepoPath "startup-all.ps1"
    if (Test-Path $startupScript) {
        & $startupScript
    } else {
        Write-Host "[WARNING] Startup script not found. Run setup first." -ForegroundColor Yellow
    }
    
    Write-Host "[OK] System started" -ForegroundColor Green
}

function Stop-System {
    Write-Host "[STOP] Stopping all services..." -ForegroundColor Yellow
    
    # Stop monitoring processes
    Get-Process powershell | Where-Object { 
        $_.CommandLine -like "*monitor*" -or 
        $_.CommandLine -like "*trading*" -or 
        $_.CommandLine -like "*security*" 
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Host "[OK] System stopped" -ForegroundColor Green
}

function Get-SystemStatus {
    Write-Host "[STATUS] System Status" -ForegroundColor Yellow
    Write-Host ""
    
    # Check repository
    if (Test-Path $script:RepoPath) {
        Write-Host "    Repository: [OK]" -ForegroundColor Green
    } else {
        Write-Host "    Repository: [MISSING]" -ForegroundColor Red
    }
    
    # Check processes
    $monitorProcesses = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*monitor*" 
    }
    Write-Host "    Monitoring Processes: $($monitorProcesses.Count)" -ForegroundColor Yellow
    
    # Check scheduled task
    $task = Get-ScheduledTask -TaskName "OS-Application-Support-Startup" -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "    Auto-Startup: [OK] ($($task.State))" -ForegroundColor Green
    } else {
        Write-Host "    Auto-Startup: [NOT CONFIGURED]" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[OK] Status check complete" -ForegroundColor Green
}

function Deploy-System {
    Write-Host "[DEPLOY] Deploying to GitHub..." -ForegroundColor Yellow
    
    $deployScript = Join-Path $PSScriptRoot "deploy-os-application-support.ps1"
    if (Test-Path $deployScript) {
        & $deployScript -FullDeploy -RunAsAdmin
    } else {
        Write-Host "[ERROR] Deploy script not found" -ForegroundColor Red
    }
}

function Update-System {
    Write-Host "[UPDATE] Updating system..." -ForegroundColor Yellow
    
    # Pull latest from GitHub
    $deployScript = Join-Path $PSScriptRoot "deploy-os-application-support.ps1"
    if (Test-Path $deployScript) {
        & $deployScript -PullFromGitHub -RunAsAdmin
    }
    
    # Restart services
    Stop-System
    Start-Sleep -Seconds 2
    Start-System
    
    Write-Host "[OK] System updated" -ForegroundColor Green
}

# Execute action
switch ($Action) {
    "setup" { Setup-System }
    "start" { Start-System }
    "stop" { Stop-System }
    "restart" { 
        Stop-System
        Start-Sleep -Seconds 2
        Start-System
    }
    "status" { Get-SystemStatus }
    "deploy" { Deploy-System }
    "update" { Update-System }
}

Write-Host ""

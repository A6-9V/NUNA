#Requires -Version 5.1
<#
.SYNOPSIS
    Start Trading System (Auto-Admin)
.DESCRIPTION
    Auto-elevates to administrator and starts complete trading system
    No user interaction required
#>

$ErrorActionPreference = "Continue"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Re-launch as administrator
    Write-Host "Elevating to administrator..." -ForegroundColor Yellow
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -WindowStyle Hidden
    exit 0
}

# Running as administrator - proceed
$workspaceRoot = "C:\Users\USER\OneDrive"
$orchestratorPath = Join-Path $workspaceRoot "master-trading-orchestrator.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Trading System" -ForegroundColor Cyan
Write-Host "  Running as Administrator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run master orchestrator
if (Test-Path $orchestratorPath) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $orchestratorPath
    } catch {
        Write-Host "[ERROR] Failed to start orchestrator: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[ERROR] Master orchestrator not found: $orchestratorPath" -ForegroundColor Red
    Write-Host "Please run setup-trading-drive.ps1 first" -ForegroundColor Yellow
    exit 1
}


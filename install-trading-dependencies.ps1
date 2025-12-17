#Requires -Version 5.1
<#
.SYNOPSIS
    Install Trading System Dependencies
.DESCRIPTION
    Installs all required Python packages for trading system
#>

$ErrorActionPreference = "Continue"

Write-Host "Installing trading system dependencies..." -ForegroundColor Cyan

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "[ERROR] Python not found!" -ForegroundColor Red
    exit 1
}

$requirementsPath = Join-Path $PSScriptRoot "trading-bridge\requirements.txt"

if (Test-Path $requirementsPath) {
    Write-Host "Installing from requirements.txt..." -ForegroundColor Yellow
    python -m pip install -q -r $requirementsPath
} else {
    Write-Host "Installing core packages..." -ForegroundColor Yellow
    python -m pip install -q pyzmq requests python-dotenv cryptography schedule pywin32
}

Write-Host ""
Write-Host "[OK] Dependencies installed" -ForegroundColor Green


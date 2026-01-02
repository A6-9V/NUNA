# PowerShell launcher for complete Windows setup
# This script will request administrator privileges and run the setup

$scriptPath = Join-Path $PSScriptRoot "complete-windows-setup.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Could not find complete-windows-setup.ps1" -ForegroundColor Red
    Write-Host "Expected location: $scriptPath" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Requesting administrator privileges..." -ForegroundColor Cyan
Write-Host "You will see a UAC prompt. Please click 'Yes' to continue." -ForegroundColor Yellow
Write-Host ""

Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$scriptPath`""



# Run Security Check Script
# Master script that runs comprehensive security and plugin protection checks

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Running Security Checks" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run security check
Write-Host "[1/2] Running Security Check..." -ForegroundColor Yellow
Write-Host ""
& "$PSScriptRoot\security-check.ps1"

Write-Host ""
Start-Sleep -Seconds 2

# Run plugin protection check
Write-Host "[2/2] Running Plugin Protection Check..." -ForegroundColor Yellow
Write-Host ""
& "$PSScriptRoot\plugin-protection.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All Security Checks Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "For detailed results, review the output above." -ForegroundColor White
Write-Host ""




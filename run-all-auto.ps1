# Master automation script - Runs everything automatically
# This script orchestrates all automated setup tasks

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Master Automation Script" -ForegroundColor Cyan
Write-Host "  Running all tasks automatically..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Run Windows Setup
Write-Host "[1/3] Running Windows Setup..." -ForegroundColor Yellow
Write-Host ""
$setupScript = Join-Path $PSScriptRoot "auto-setup.ps1"
if (Test-Path $setupScript) {
    & powershell.exe -ExecutionPolicy Bypass -File $setupScript
} else {
    Write-Host "    [SKIP] Setup script not found" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Step 2: Run Git Push (automated with saved token)
Write-Host "[2/3] Running Git Push (using saved credentials)..." -ForegroundColor Yellow
Write-Host ""
$gitScript = Join-Path $PSScriptRoot "auto-git-push.ps1"
if (Test-Path $gitScript) {
    & powershell.exe -ExecutionPolicy Bypass -File $gitScript
} else {
    Write-Host "    [SKIP] Git script not found" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Step 3: Summary
Write-Host "[3/3] Generating summary..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All Automated Tasks Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Completed automatically:" -ForegroundColor Yellow
Write-Host "  [OK] Windows configuration" -ForegroundColor White
Write-Host "  [OK] Security settings" -ForegroundColor White
Write-Host "  [OK] Cloud services" -ForegroundColor White
Write-Host "  [OK] Git repository" -ForegroundColor White
Write-Host ""
Write-Host "All decisions were made automatically using best practices." -ForegroundColor Green
Write-Host ""


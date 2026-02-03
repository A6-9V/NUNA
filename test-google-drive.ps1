# Test Google Drive Setup
# This script tests if Google Drive OAuth is properly configured

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Google Drive Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "credentials.json")) {
    Write-Host "[ERROR] credentials.json not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please complete Google Drive OAuth setup:" -ForegroundColor Yellow
    Write-Host "  1. Run: .\auto-setup-helper.ps1" -ForegroundColor White
    Write-Host "  2. Follow the instructions to create credentials.json" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "[OK] credentials.json found" -ForegroundColor Green
Write-Host ""

Write-Host "Testing Google Drive API connection..." -ForegroundColor Yellow
Write-Host "Running: python gdrive_cleanup.py audit --top 5" -ForegroundColor Gray
Write-Host ""

try {
    python gdrive_cleanup.py audit --top 5
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "[SUCCESS] Google Drive is working!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "[ERROR] Test failed. Check the error messages above." -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Failed to run test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

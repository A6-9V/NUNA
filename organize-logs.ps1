# organize-logs.ps1
# This script organizes MetaTrader 5 logs using the trading_data_manager.py tool.
# It is designed to be run from PowerShell on Windows.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MT5 Logs Organizer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Python is required but not found in PATH." -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/"
    return
}

# Run the trading data manager
Write-Host "Organizing logs and reports..." -ForegroundColor Yellow
python trading_data_manager.py run --apply

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Logs organized successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✗ Failed to organize logs." -ForegroundColor Red
}

Write-Host "========================================" -ForegroundColor Cyan

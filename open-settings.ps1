# Quick launcher to open all necessary settings windows
# This script opens the settings pages you need for manual configuration

Write-Host "Opening Windows Settings..." -ForegroundColor Cyan
Write-Host ""

# Open Account Settings
Write-Host "[1] Opening Account Settings..." -ForegroundColor Yellow
Start-Process "ms-settings:yourinfo"
Start-Sleep -Seconds 2

# Open Sync Settings
Write-Host "[2] Opening Sync Settings..." -ForegroundColor Yellow
Start-Process "ms-settings:sync"
Start-Sleep -Seconds 2

# Open Default Apps
Write-Host "[3] Opening Default Apps Settings..." -ForegroundColor Yellow
Start-Process "ms-settings:defaultapps"
Start-Sleep -Seconds 2

# Open Windows Security
Write-Host "[4] Opening Windows Security..." -ForegroundColor Yellow
Start-Process "windowsdefender:"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "All settings windows have been opened!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Sign in to Microsoft account (Lengkundee01@outlook.com) in Account Settings" -ForegroundColor White
Write-Host "  2. Enable sync in Sync Settings" -ForegroundColor White
Write-Host "  3. Configure default apps in Default Apps Settings" -ForegroundColor White
Write-Host "  4. Check Windows Security for any alerts" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



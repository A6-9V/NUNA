# Test OneDrive Setup
# This script tests if OneDrive OAuth is properly configured

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing OneDrive Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $env:ONEDRIVE_CLIENT_ID) {
    Write-Host "[ERROR] ONEDRIVE_CLIENT_ID environment variable not set!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please complete OneDrive OAuth setup:" -ForegroundColor Yellow
    Write-Host "  1. Run: .\auto-setup-helper.ps1" -ForegroundColor White
    Write-Host "  2. Follow the instructions to create Azure App Registration" -ForegroundColor White
    Write-Host "  3. Set the Client ID:" -ForegroundColor White
    Write-Host '     $env:ONEDRIVE_CLIENT_ID = "YOUR_CLIENT_ID"' -ForegroundColor Green
    Write-Host ""
    exit 1
}

Write-Host "[OK] ONEDRIVE_CLIENT_ID is set: $env:ONEDRIVE_CLIENT_ID" -ForegroundColor Green
Write-Host ""

Write-Host "Testing OneDrive API connection..." -ForegroundColor Yellow
Write-Host "Note: This requires a Dropbox URL to test" -ForegroundColor Gray
Write-Host ""
Write-Host "Example test command (dry-run):" -ForegroundColor Cyan
Write-Host '  python dropbox_to_onedrive.py --dropbox-url "YOUR_DROPBOX_URL" --dry-run' -ForegroundColor White
Write-Host ""
Write-Host "To test, provide a Dropbox shared folder URL:" -ForegroundColor Yellow
$dropboxUrl = Read-Host "Dropbox URL (or press Enter to skip)"

if ($dropboxUrl) {
    Write-Host ""
    Write-Host "Running dry-run test..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        python dropbox_to_onedrive.py --dropbox-url $dropboxUrl --dry-run
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "[SUCCESS] OneDrive is working!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[ERROR] Test failed. Check the error messages above." -ForegroundColor Red
        }
    } catch {
        Write-Host ""
        Write-Host "[ERROR] Failed to run test: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "[INFO] Skipped test. OneDrive Client ID is configured." -ForegroundColor Yellow
    Write-Host "To test later, run:" -ForegroundColor Cyan
    Write-Host '  python dropbox_to_onedrive.py --dropbox-url "YOUR_URL" --dry-run' -ForegroundColor White
}

Write-Host ""

# Automated OAuth Setup Helper
# This script attempts to automate what it can and provides clear instructions for what can't be automated

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Automated OAuth Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check current status
Write-Host "Checking current setup status..." -ForegroundColor Yellow
Write-Host ""

$needsGoogle = $false
$needsOneDrive = $false

# Check Google Drive
if (-not (Test-Path "credentials.json")) {
    $needsGoogle = $true
    Write-Host "[MISSING] Google Drive: credentials.json not found" -ForegroundColor Red
} else {
    Write-Host "[OK] Google Drive: credentials.json found" -ForegroundColor Green
}

# Check OneDrive
if (-not $env:ONEDRIVE_CLIENT_ID) {
    $needsOneDrive = $true
    Write-Host "[MISSING] OneDrive: ONEDRIVE_CLIENT_ID not set" -ForegroundColor Red
} else {
    Write-Host "[OK] OneDrive: ONEDRIVE_CLIENT_ID is set" -ForegroundColor Green
}

Write-Host ""

if (-not $needsGoogle -and -not $needsOneDrive) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "[OK] All OAuth credentials are configured!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# Open browser pages for manual setup
Write-Host "Opening setup pages in your browser..." -ForegroundColor Yellow
Write-Host ""

if ($needsGoogle) {
    Write-Host "Opening Google Cloud Console..." -ForegroundColor Cyan
    Start-Process "https://console.cloud.google.com/apis/credentials"
    Start-Sleep -Seconds 2
}

if ($needsOneDrive) {
    Write-Host "Opening Azure Portal..." -ForegroundColor Cyan
    Start-Process "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade"
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Manual Steps Required" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "OAuth setup requires manual steps because it needs:" -ForegroundColor White
Write-Host "  - Your Google/Microsoft account login" -ForegroundColor Gray
Write-Host "  - Creating resources in cloud platforms" -ForegroundColor Gray
Write-Host "  - Your decisions on project names and settings" -ForegroundColor Gray
Write-Host ""

if ($needsGoogle) {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "GOOGLE DRIVE SETUP:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. In Google Cloud Console (just opened):" -ForegroundColor White
    Write-Host "   - Create/Select a project" -ForegroundColor Gray
    Write-Host "   - Enable 'Google Drive API' (APIs and Services -> Library)" -ForegroundColor Gray
    Write-Host "   - Create OAuth Client ID (Desktop app)" -ForegroundColor Gray
    Write-Host "   - Download the JSON file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Save the downloaded file as:" -ForegroundColor White
    Write-Host "   H:\Pictures\.Gallery2\recycle\bins\credentials.json" -ForegroundColor Green
    Write-Host ""
    Write-Host "3. Then run this script again to verify:" -ForegroundColor White
    Write-Host "   .\check-oauth-setup.ps1" -ForegroundColor Yellow
    Write-Host ""
}

if ($needsOneDrive) {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "ONEDRIVE SETUP:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. In Azure Portal (just opened):" -ForegroundColor White
    Write-Host "   - Click '+ New registration'" -ForegroundColor Gray
    Write-Host "   - Name: NUNA OneDrive Import" -ForegroundColor Gray
    Write-Host "   - Supported accounts: Personal Microsoft accounts" -ForegroundColor Gray
    Write-Host "   - Authentication -> Allow public client flows: Yes" -ForegroundColor Gray
    Write-Host "   - API permissions -> Add: Files.ReadWrite.All, User.Read" -ForegroundColor Gray
    Write-Host "   - Copy the Application (client) ID" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Set the Client ID (run this command):" -ForegroundColor White
    Write-Host '   $env:ONEDRIVE_CLIENT_ID = "YOUR_CLIENT_ID_HERE"' -ForegroundColor Green
    Write-Host ""
    Write-Host "   Or set permanently:" -ForegroundColor White
    Write-Host '   [System.Environment]::SetEnvironmentVariable("ONEDRIVE_CLIENT_ID", "YOUR_CLIENT_ID", "User")' -ForegroundColor Green
    Write-Host ""
    Write-Host "3. Then run this script again to verify:" -ForegroundColor White
    Write-Host "   .\check-oauth-setup.ps1" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Reference:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Detailed guide: SETUP-OAUTH.md" -ForegroundColor White
Write-Host "  Check status: .\check-oauth-setup.ps1" -ForegroundColor White
Write-Host "  Open pages: .\open-oauth-pages.ps1" -ForegroundColor White
Write-Host ""

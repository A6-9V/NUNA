# Open OAuth Setup Pages
# This script opens the necessary web pages for OAuth setup

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Opening OAuth Setup Pages" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Google Cloud Console
Write-Host "Opening Google Cloud Console..." -ForegroundColor Yellow
Start-Process "https://console.cloud.google.com/"

Write-Host ""
Write-Host "Google Drive Setup Steps:" -ForegroundColor Cyan
Write-Host "  1. Create/Select a project" -ForegroundColor White
Write-Host "  2. Go to: APIs & Services → Library" -ForegroundColor White
Write-Host "  3. Search and enable: Google Drive API" -ForegroundColor White
Write-Host "  4. Go to: APIs & Services → Credentials" -ForegroundColor White
Write-Host "  5. Click: + CREATE CREDENTIALS → OAuth client ID" -ForegroundColor White
Write-Host "  6. Application type: Desktop app" -ForegroundColor White
Write-Host "  7. Download the JSON file as 'credentials.json'" -ForegroundColor White
Write-Host "  8. Save it to: H:\Pictures\.Gallery2\recycle\bins\credentials.json" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 3

# Azure Portal
Write-Host "Opening Azure Portal..." -ForegroundColor Yellow
Start-Process "https://portal.azure.com/"

Write-Host ""
Write-Host "OneDrive Setup Steps:" -ForegroundColor Cyan
Write-Host "  1. Search for: Azure Active Directory or Microsoft Entra ID" -ForegroundColor White
Write-Host "  2. Go to: App registrations" -ForegroundColor White
Write-Host "  3. Click: + New registration" -ForegroundColor White
Write-Host "  4. Name: NUNA OneDrive Import" -ForegroundColor White
Write-Host "  5. Supported accounts: Personal Microsoft accounts" -ForegroundColor White
Write-Host "  6. Go to: Authentication → Allow public client flows: Yes" -ForegroundColor White
Write-Host "  7. Go to: API permissions → + Add permission" -ForegroundColor White
Write-Host "  8. Add: Files.ReadWrite.All, User.Read" -ForegroundColor White
Write-Host "  9. Copy the Application (client) ID" -ForegroundColor White
Write-Host "  10. Run: .\setup-onedrive-oauth.ps1 to set it" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pages opened! Follow the steps above." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "After completing setup, run:" -ForegroundColor Yellow
Write-Host "  .\check-oauth-setup.ps1" -ForegroundColor White
Write-Host ""

# OneDrive OAuth Setup Helper
# This script helps you set up OneDrive OAuth via Microsoft Graph

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OneDrive OAuth Setup (Microsoft Graph)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will help you set up OneDrive OAuth credentials." -ForegroundColor Yellow
Write-Host ""

Write-Host "Steps you need to complete:" -ForegroundColor White
Write-Host "1. Go to Azure Portal: https://portal.azure.com/" -ForegroundColor Cyan
Write-Host "2. Create App Registration" -ForegroundColor Cyan
Write-Host "3. Enable 'Allow public client flows'" -ForegroundColor Cyan
Write-Host "4. Add API permissions (Files.ReadWrite.All, User.Read)" -ForegroundColor Cyan
Write-Host "5. Copy the Application (client) ID" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "Have you completed these steps? (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host ""
    Write-Host "Please complete the steps above, then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Detailed instructions:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://portal.azure.com/" -ForegroundColor White
    Write-Host "2. Search 'Azure Active Directory' or 'Microsoft Entra ID'" -ForegroundColor White
    Write-Host "3. App registrations → + New registration" -ForegroundColor White
    Write-Host "4. Name: NUNA OneDrive Import" -ForegroundColor White
    Write-Host "5. Supported accounts: Personal Microsoft accounts" -ForegroundColor White
    Write-Host "6. Authentication → Allow public client flows: Yes" -ForegroundColor White
    Write-Host "7. API permissions → + Add permission → Microsoft Graph → Delegated" -ForegroundColor White
    Write-Host "8. Add: Files.ReadWrite.All, User.Read" -ForegroundColor White
    Write-Host "9. Copy the Application (client) ID" -ForegroundColor White
    Write-Host ""
    exit
}

Write-Host ""
Write-Host "Please enter your Application (client) ID:" -ForegroundColor Yellow
Write-Host "(Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)" -ForegroundColor Gray
$clientId = Read-Host "Client ID"

if ([string]::IsNullOrWhiteSpace($clientId)) {
    Write-Host ""
    Write-Host "ERROR: Client ID cannot be empty" -ForegroundColor Red
    exit 1
}

# Validate format (basic check)
if ($clientId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
    Write-Host ""
    Write-Host "WARNING: Client ID format looks incorrect" -ForegroundColor Yellow
    Write-Host "Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ForegroundColor Gray
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit
    }
}

Write-Host ""
Write-Host "Setting environment variable..." -ForegroundColor Yellow

# Set for current session
$env:ONEDRIVE_CLIENT_ID = $clientId
Write-Host "✓ Set for current session: ONEDRIVE_CLIENT_ID=$clientId" -ForegroundColor Green

# Ask if user wants to set permanently
Write-Host ""
$permanent = Read-Host "Set permanently for your user account? (y/n)"
if ($permanent -eq "y" -or $permanent -eq "Y") {
    [System.Environment]::SetEnvironmentVariable('ONEDRIVE_CLIENT_ID', $clientId, 'User')
    Write-Host "✓ Set permanently (requires restarting terminal)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Note: Environment variable is only set for this session." -ForegroundColor Yellow
    Write-Host "To set permanently, run:" -ForegroundColor Cyan
    Write-Host "  [System.Environment]::SetEnvironmentVariable('ONEDRIVE_CLIENT_ID', '$clientId', 'User')" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Test the setup by running (dry-run):" -ForegroundColor Cyan
Write-Host "  python dropbox_to_onedrive.py --dropbox-url `"YOUR_DROPBOX_URL`" --dry-run" -ForegroundColor White
Write-Host ""
Write-Host "Current Client ID: $env:ONEDRIVE_CLIENT_ID" -ForegroundColor Gray
Write-Host ""

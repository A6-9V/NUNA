# Non-Interactive OAuth Setup Checker
# This script checks what's already configured and provides next steps

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OAuth Setup Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Check Google Drive OAuth
Write-Host "Google Drive OAuth:" -ForegroundColor Yellow
if (Test-Path "credentials.json") {
    try {
        $googleCreds = Get-Content "credentials.json" | ConvertFrom-Json
        if ($googleCreds.installed) {
            Write-Host "  [OK] credentials.json found" -ForegroundColor Green
            Write-Host "    Client ID: $($googleCreds.installed.client_id)" -ForegroundColor Gray
        } elseif ($googleCreds.web) {
            Write-Host "  [WARN] credentials.json found but is Web app type (should be Desktop app)" -ForegroundColor Yellow
        } else {
            Write-Host "  [WARN] credentials.json found but format unexpected" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [ERROR] credentials.json exists but is invalid JSON" -ForegroundColor Red
        $allGood = $false
    }
} else {
    Write-Host "  [MISSING] credentials.json not found" -ForegroundColor Red
    Write-Host "    Action needed: Create OAuth credentials in Google Cloud Console" -ForegroundColor Yellow
    $allGood = $false
}

if (Test-Path "token.json") {
    Write-Host "  [OK] token.json found (already authenticated)" -ForegroundColor Green
} else {
    Write-Host "  [INFO] token.json not found (will be created on first run)" -ForegroundColor Yellow
}

Write-Host ""

# Check OneDrive OAuth
Write-Host "OneDrive OAuth:" -ForegroundColor Yellow
$onedriveClientId = $env:ONEDRIVE_CLIENT_ID
if ($onedriveClientId) {
    Write-Host "  [OK] ONEDRIVE_CLIENT_ID environment variable set" -ForegroundColor Green
    Write-Host "    Value: $onedriveClientId" -ForegroundColor Gray
    
    # Check if it's a valid GUID format
    if ($onedriveClientId -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
        Write-Host "    Format: Valid GUID" -ForegroundColor Green
    } else {
        Write-Host "    Format: May be invalid (expected GUID format)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [MISSING] ONEDRIVE_CLIENT_ID environment variable not set" -ForegroundColor Red
    Write-Host "    Action needed: Create Azure App Registration and set Client ID" -ForegroundColor Yellow
    $allGood = $false
}

Write-Host ""

# Check Python packages
Write-Host "Python Packages:" -ForegroundColor Yellow
try {
    $null = python -c "import google.auth; import msal; import requests; print('OK')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] All required packages installed" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Some packages missing" -ForegroundColor Red
        Write-Host "    Run: python -m pip install -r requirements.txt" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "  [ERROR] Error checking packages" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "Status: [OK] Ready to use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test commands:" -ForegroundColor Cyan
    Write-Host "  Google Drive: python gdrive_cleanup.py audit --top 5" -ForegroundColor White
    Write-Host "  OneDrive: python dropbox_to_onedrive.py --dropbox-url 'URL' --dry-run" -ForegroundColor White
} else {
    Write-Host "Status: [INCOMPLETE] Setup incomplete" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    if (-not (Test-Path "credentials.json")) {
        Write-Host "  1. Set up Google Drive OAuth (see SETUP-OAUTH.md)" -ForegroundColor White
        Write-Host "     Or run: .\open-oauth-pages.ps1" -ForegroundColor Gray
    }
    if (-not $onedriveClientId) {
        Write-Host "  2. Set up OneDrive OAuth (see SETUP-OAUTH.md)" -ForegroundColor White
        Write-Host "     Or run: .\open-oauth-pages.ps1" -ForegroundColor Gray
    }
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

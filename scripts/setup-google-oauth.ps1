# Google Drive OAuth Setup Helper
# This script guides you through setting up Google OAuth credentials

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Google Drive OAuth Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will help you set up Google Drive OAuth credentials." -ForegroundColor Yellow
Write-Host ""

Write-Host "Steps you need to complete:" -ForegroundColor White
Write-Host "1. Go to Google Cloud Console: https://console.cloud.google.com/" -ForegroundColor Cyan
Write-Host "2. Create a new project (or select existing)" -ForegroundColor Cyan
Write-Host "3. Enable Google Drive API" -ForegroundColor Cyan
Write-Host "4. Create OAuth 2.0 Client ID (Desktop app)" -ForegroundColor Cyan
Write-Host "5. Download credentials.json" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "Have you completed these steps? (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host ""
    Write-Host "Please complete the steps above, then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Detailed instructions:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://console.cloud.google.com/" -ForegroundColor White
    Write-Host "2. Create/Select Project → APIs & Services → Library" -ForegroundColor White
    Write-Host "3. Search 'Google Drive API' → Enable" -ForegroundColor White
    Write-Host "4. APIs & Services → Credentials → + CREATE CREDENTIALS → OAuth client ID" -ForegroundColor White
    Write-Host "5. Application type: Desktop app" -ForegroundColor White
    Write-Host "6. Download the JSON file" -ForegroundColor White
    Write-Host ""
    exit
}

Write-Host ""
Write-Host "Please provide the path to your downloaded credentials.json file:" -ForegroundColor Yellow
Write-Host "(Or press Enter to use default: credentials.json in current directory)" -ForegroundColor Gray
$credPath = Read-Host "Path to credentials.json"

if ([string]::IsNullOrWhiteSpace($credPath)) {
    $credPath = "credentials.json"
}

if (-not (Test-Path $credPath)) {
    Write-Host ""
    Write-Host "ERROR: File not found: $credPath" -ForegroundColor Red
    Write-Host "Please download the credentials.json file from Google Cloud Console." -ForegroundColor Yellow
    exit 1
}

# Copy to current directory if it's not already there
$targetPath = Join-Path $PSScriptRoot "credentials.json"
if ($credPath -ne $targetPath) {
    Copy-Item $credPath $targetPath -Force
    Write-Host ""
    Write-Host "Copied credentials.json to: $targetPath" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Using credentials.json from current directory" -ForegroundColor Green
}

# Verify it's valid JSON
try {
    $json = Get-Content $targetPath | ConvertFrom-Json
    if ($json.installed -or $json.web) {
        Write-Host ""
        Write-Host "✓ Valid credentials.json file detected!" -ForegroundColor Green
        
        if ($json.installed) {
            Write-Host "  Type: Desktop app (installed)" -ForegroundColor Gray
            Write-Host "  Client ID: $($json.installed.client_id)" -ForegroundColor Gray
        } elseif ($json.web) {
            Write-Host "  Type: Web application" -ForegroundColor Yellow
            Write-Host "  Note: This should be a Desktop app type. You may need to recreate it." -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Setup Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Test the setup by running:" -ForegroundColor Cyan
        Write-Host "  python gdrive_cleanup.py audit --top 5" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "WARNING: Unexpected credentials.json format" -ForegroundColor Yellow
        Write-Host "Make sure you downloaded the OAuth 2.0 Client ID (Desktop app)" -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: Invalid JSON file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

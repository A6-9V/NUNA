# Make Repository Private on GitHub
# This script helps make the repository private using GitHub API

param(
    [string]$Repository = "A6-9V/my-drive-projects",
    [string]$GitHubToken = "",
    [switch]$UseCLI
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Make Repository Private" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Method 1: Using GitHub CLI (if available)
if ($UseCLI) {
    Write-Host "[INFO] Attempting to use GitHub CLI..." -ForegroundColor Yellow
    
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        Write-Host "[OK] GitHub CLI found" -ForegroundColor Green
        
        # Check if authenticated
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] GitHub CLI authenticated" -ForegroundColor Green
            Write-Host "[INFO] Making repository private: $Repository" -ForegroundColor Yellow
            
            gh repo edit $Repository --visibility private
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Repository is now private!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Verify at: https://github.com/$Repository" -ForegroundColor Cyan
                exit 0
            } else {
                Write-Host "[ERROR] Failed to make repository private via CLI" -ForegroundColor Red
            }
        } else {
            Write-Host "[WARNING] GitHub CLI not authenticated. Run: gh auth login" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] GitHub CLI not found. Install from: https://cli.github.com/" -ForegroundColor Yellow
    }
}

# Method 2: Using GitHub API
if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host "[INFO] GitHub API Method" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To make the repository private via API, you need:" -ForegroundColor White
    Write-Host "  1. A GitHub Personal Access Token (PAT)" -ForegroundColor White
    Write-Host "  2. Token with 'repo' scope" -ForegroundColor White
    Write-Host ""
    Write-Host "Get a token from: https://github.com/settings/tokens" -ForegroundColor Cyan
    Write-Host ""
    
    $token = Read-Host "Enter your GitHub Personal Access Token (or press Enter to skip)"
    
    if ([string]::IsNullOrEmpty($token)) {
        Write-Host ""
        Write-Host "[INFO] Skipping API method. Use one of these methods:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Method 1: GitHub Web Interface (Recommended)" -ForegroundColor Cyan
        Write-Host "  1. Go to: https://github.com/$Repository" -ForegroundColor White
        Write-Host "  2. Click Settings (top right)" -ForegroundColor White
        Write-Host "  3. Scroll to Danger Zone" -ForegroundColor White
        Write-Host "  4. Click 'Change visibility'" -ForegroundColor White
        Write-Host "  5. Select 'Make private'" -ForegroundColor White
        Write-Host "  6. Confirm by typing: $Repository" -ForegroundColor White
        Write-Host ""
        Write-Host "Method 2: GitHub CLI" -ForegroundColor Cyan
        Write-Host "  gh repo edit $Repository --visibility private" -ForegroundColor White
        Write-Host ""
        Write-Host "Method 3: Run this script with token" -ForegroundColor Cyan
        Write-Host "  .\make-repo-private.ps1 -GitHubToken YOUR_TOKEN" -ForegroundColor White
        Write-Host ""
        exit 0
    }
    
    $GitHubToken = $token
}

# Make repository private via API
Write-Host "[INFO] Making repository private via GitHub API..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "PowerShell-Script"
}

$body = @{
    private = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository" `
        -Method PATCH -Headers $headers -Body $body -ErrorAction Stop
    
    Write-Host "[OK] Repository is now private!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($response.name)" -ForegroundColor White
    Write-Host "  Full Name: $($response.full_name)" -ForegroundColor White
    Write-Host "  Private: $($response.private)" -ForegroundColor White
    Write-Host "  URL: $($response.html_url)" -ForegroundColor White
    Write-Host ""
    Write-Host "Verify at: $($response.html_url)" -ForegroundColor Cyan
    
} catch {
    Write-Host "[ERROR] Failed to make repository private" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host ""
        Write-Host "[INFO] Authentication failed. Check your token:" -ForegroundColor Yellow
        Write-Host "  - Token must have 'repo' scope" -ForegroundColor White
        Write-Host "  - Token must be valid and not expired" -ForegroundColor White
    } elseif ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host ""
        Write-Host "[INFO] Permission denied. Check:" -ForegroundColor Yellow
        Write-Host "  - You have admin access to the repository" -ForegroundColor White
        Write-Host "  - Token has sufficient permissions" -ForegroundColor White
    } elseif ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host ""
        Write-Host "[INFO] Repository not found. Check:" -ForegroundColor Yellow
        Write-Host "  - Repository name is correct: $Repository" -ForegroundColor White
        Write-Host "  - You have access to the repository" -ForegroundColor White
    }
    
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Success!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan





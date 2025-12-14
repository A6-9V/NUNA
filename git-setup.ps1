# Git setup and push script - Uses saved tokens automatically
# This script initializes git, adds remotes, and pushes to GitHub

$repoPath = "C:\Users\USER\OneDrive"
Set-Location $repoPath

Write-Host "Setting up Git repository..." -ForegroundColor Cyan
Write-Host "Using saved credentials..." -ForegroundColor Yellow
Write-Host ""

# Load credentials
$credFile = Join-Path $PSScriptRoot "git-credentials.txt"
$githubToken = $null
$githubUser = $null

if (Test-Path $credFile) {
    $credentials = Get-Content $credFile | Where-Object { $_ -match "^GITHUB_TOKEN=" }
    if ($credentials) {
        $githubToken = ($credentials[0] -split "=")[1].Trim()
    }
    
    $userLine = Get-Content $credFile | Where-Object { $_ -match "^GITHUB_USER=" }
    if ($userLine) {
        $githubUser = ($userLine[0] -split "=")[1].Trim()
    }
}

if (-not $githubToken) {
    Write-Host "[ERROR] GitHub token not found" -ForegroundColor Red
    exit 1
}

if (-not $githubUser) {
    $githubUser = "Mouy-leng"
}

# Initialize git if not already initialized
if (-not (Test-Path ".git")) {
    Write-Host "[1] Initializing git repository..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "[1] Git repository already initialized" -ForegroundColor Green
}

# Check current remotes
Write-Host "[2] Checking remotes..." -ForegroundColor Yellow
$remotes = git remote -v

if ($remotes -match "origin") {
    Write-Host "    Remote 'origin' already exists" -ForegroundColor Yellow
    Write-Host "    Updating remote URL..." -ForegroundColor Yellow
    git remote set-url origin "https://github.com/Mouy-leng/Window-setup.git"
} else {
    # Add HTTPS remote
    Write-Host "[3] Adding HTTPS remote..." -ForegroundColor Yellow
    git remote add origin "https://github.com/Mouy-leng/Window-setup.git"
}

# Verify remotes
Write-Host "[4] Verifying remotes..." -ForegroundColor Yellow
git remote -v
Write-Host ""

# Add all files
Write-Host "[5] Adding files to git..." -ForegroundColor Yellow
git add .

# Check if there are changes to commit
$status = git status --porcelain
if ($status) {
    Write-Host "[6] Committing changes..." -ForegroundColor Yellow
    git commit -m "Initial commit: Windows setup scripts for cloud sync and configuration"
} else {
    Write-Host "[6] No changes to commit" -ForegroundColor Yellow
}

# Set branch to main
Write-Host "[7] Setting branch to main..." -ForegroundColor Yellow
git branch -M main

# Configure credentials for push
Write-Host "[8] Configuring credentials..." -ForegroundColor Yellow
$remoteUrl = "https://${githubUser}:${githubToken}@github.com/Mouy-leng/Window-setup.git"
git remote set-url origin $remoteUrl

# Push to repository
Write-Host "[9] Pushing to GitHub..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository: https://github.com/Mouy-leng/Window-setup.git" -ForegroundColor Cyan
    
    # Reset remote URL and store in credential manager
    git remote set-url origin "https://github.com/Mouy-leng/Window-setup.git"
    cmdkey /generic:git:https://github.com /user:$githubUser /pass:$githubToken 2>&1 | Out-Null
    Write-Host "[OK] Credentials saved securely in Windows Credential Manager" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[ERROR] Failed to push to GitHub" -ForegroundColor Red
    Write-Host "Check your token permissions and repository access" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

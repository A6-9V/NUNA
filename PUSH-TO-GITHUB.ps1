# Push to GitHub Script
# Pushes OS Application Support to GitHub repository

$ErrorActionPreference = "Continue"

$repoPath = "C:\Users\USER\OneDrive\OS-application-support"
$repoUrl = "https://github.com/A6-9V/OS-application-support-.git"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push OS Application Support to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $repoPath)) {
    Write-Host "[ERROR] Repository path not found: $repoPath" -ForegroundColor Red
    exit 1
}

Set-Location $repoPath

# Check if repository exists on GitHub
Write-Host "[INFO] Checking repository status..." -ForegroundColor Yellow
$remoteCheck = git ls-remote origin 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Repository may not exist on GitHub yet." -ForegroundColor Yellow
    Write-Host "[INFO] Please create the repository first:" -ForegroundColor Cyan
    Write-Host "    https://github.com/A6-9V/OS-application-support-" -ForegroundColor White
    Write-Host ""
    Write-Host "[INFO] After creating the repository, run this script again." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit
    }
}

# Push to GitHub
Write-Host "[INFO] Pushing to GitHub..." -ForegroundColor Yellow
Write-Host ""

# Prefer OAuth via GitHub CLI if available (recommended)
try {
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghInstalled) {
        gh auth status -h github.com 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            gh auth setup-git -h github.com 2>$null | Out-Null
            Write-Host "[INFO] Using GitHub CLI OAuth credentials (gh auth setup-git)" -ForegroundColor Cyan
        } else {
            Write-Host "[WARNING] GitHub CLI is installed but not authenticated." -ForegroundColor Yellow
            Write-Host "          Run: gh auth login -h github.com -p https --web" -ForegroundColor White
        }
    }
} catch {
    # Best-effort only; continue to git push (user may already have credentials configured)
}

# Try to push
git push -u origin main 2>&1 | ForEach-Object {
    if ($_ -match "error|fatal") {
        Write-Host $_ -ForegroundColor Red
    } else {
        Write-Host $_ -ForegroundColor Green
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "[ERROR] Push failed. Common issues:" -ForegroundColor Red
    Write-Host "1. Repository doesn't exist on GitHub - create it first" -ForegroundColor Yellow
    Write-Host "2. Authentication failed - check Git credentials" -ForegroundColor Yellow
    Write-Host "3. Network connectivity issues" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Repository URL: $repoUrl" -ForegroundColor Cyan
}

Write-Host ""

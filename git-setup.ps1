<# 
Git setup and push script

OAuth-first:
- Uses GitHub CLI (`gh`) OAuth login + `gh auth setup-git` (recommended)
- Falls back to PAT from local `git-credentials.txt` ONLY if `gh` isn't available

SECURITY:
- Never prints token values
- Removes tokenized remote URL after push (PAT fallback only)
#>

$ErrorActionPreference = "Continue"

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-GitHubCliAuth {
    param([string]$Hostname = "github.com")

    if (-not (Test-Command "gh")) {
        return $false
    }

    gh auth status -h $Hostname 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] GitHub CLI is installed but not authenticated." -ForegroundColor Yellow
        Write-Host "[INFO] Run one of the following, then re-run this script:" -ForegroundColor Cyan
        Write-Host "  gh auth login -h $Hostname -p https --web" -ForegroundColor White
        Write-Host "  gh auth login -h $Hostname -p https --device" -ForegroundColor White
        return $false
    }

    # Configure git to use GH's OAuth token for HTTPS operations
    gh auth setup-git -h $Hostname 2>$null | Out-Null
    return $true
}

$repoPath = "C:\Users\USER\OneDrive"
Set-Location $repoPath

Write-Host "Setting up Git repository..." -ForegroundColor Cyan
Write-Host ""

# Optional PAT fallback (local-only, gitignored)
$credFile = Join-Path $PSScriptRoot "git-credentials.txt"
$githubToken = $null
$githubUser = $null

if (Test-Path $credFile) {
    try {
        $tokenLine = Get-Content $credFile -ErrorAction Stop | Where-Object { $_ -match "^GITHUB_TOKEN=" } | Select-Object -First 1
        if ($tokenLine) { $githubToken = ($tokenLine -split "=", 2)[1].Trim() }

        $userLine = Get-Content $credFile -ErrorAction Stop | Where-Object { $_ -match "^GITHUB_USER=" } | Select-Object -First 1
        if ($userLine) { $githubUser = ($userLine -split "=", 2)[1].Trim() }
    } catch {
        Write-Host "[WARNING] Could not read git-credentials.txt (PAT fallback)." -ForegroundColor Yellow
    }
}

if (-not $githubUser) { $githubUser = "Mouy-leng" }

# Ensure git is installed
if (-not (Test-Command "git")) {
    Write-Host "[ERROR] git is not installed or not on PATH." -ForegroundColor Red
    exit 1
}

# Prefer OAuth via GitHub CLI
$hasGhOAuth = Ensure-GitHubCliAuth -Hostname "github.com"

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

Write-Host "[8] Pushing to GitHub..." -ForegroundColor Yellow

$cleanOrigin = "https://github.com/Mouy-leng/Window-setup.git"

if ($hasGhOAuth) {
    # OAuth via GitHub CLI (recommended)
    git remote set-url origin $cleanOrigin 2>$null | Out-Null
    git push -u origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] Successfully pushed to GitHub (OAuth via gh)!" -ForegroundColor Green
        Write-Host "Repository: $cleanOrigin" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "[ERROR] Push failed even though gh is authenticated." -ForegroundColor Red
        Write-Host "[INFO] Try: gh auth setup-git -h github.com" -ForegroundColor Yellow
        Write-Host "[INFO] Then re-run this script." -ForegroundColor Yellow
    }
} elseif ($githubToken) {
    # PAT fallback (less ideal; keep token out of logs, remove from remote after push)
    Write-Host "[WARNING] Using PAT fallback (git-credentials.txt). Prefer 'gh auth login' instead." -ForegroundColor Yellow
    $tokenOrigin = "https://${githubUser}:${githubToken}@github.com/Mouy-leng/Window-setup.git"

    try {
        git remote set-url origin $tokenOrigin 2>$null | Out-Null
        git push -u origin main

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] Successfully pushed to GitHub (PAT fallback)!" -ForegroundColor Green
            Write-Host "Repository: $cleanOrigin" -ForegroundColor Cyan
        } else {
            Write-Host ""
            Write-Host "[ERROR] Failed to push to GitHub." -ForegroundColor Red
            Write-Host "Check token permissions (repo/workflow) and repository access." -ForegroundColor Yellow
        }
    } finally {
        # Always reset origin to remove token from config
        git remote set-url origin $cleanOrigin 2>$null | Out-Null
        $githubToken = $null
    }
} else {
    Write-Host ""
    Write-Host "[ERROR] No GitHub auth available." -ForegroundColor Red
    Write-Host "[INFO] Recommended: install GitHub CLI and login via OAuth:" -ForegroundColor Cyan
    Write-Host "  winget install --id GitHub.cli" -ForegroundColor White
    Write-Host "  gh auth login -h github.com -p https --web" -ForegroundColor White
    Write-Host "[INFO] Fallback: create a PAT in a local gitignored file (git-credentials.txt)." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

<# 
Automated Git Push

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

    gh auth setup-git -h $Hostname 2>$null | Out-Null
    return $true
}

$repoPath = "C:\Users\USER\OneDrive"
Set-Location $repoPath

Write-Host "Automated Git Push" -ForegroundColor Cyan
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

if (-not (Test-Command "git")) {
    Write-Host "[ERROR] git is not installed or not on PATH." -ForegroundColor Red
    exit 1
}

$hasGhOAuth = Ensure-GitHubCliAuth -Hostname "github.com"

# Check if git is initialized
if (-not (Test-Path ".git")) {
    Write-Host "[1] Initializing git repository..." -ForegroundColor Yellow
    git init | Out-Null
    Write-Host "    [OK] Git initialized" -ForegroundColor Green
}

# Check and set remote
$remotes = git remote -v 2>&1
if (-not ($remotes -match "origin")) {
    Write-Host "[2] Adding remote repository..." -ForegroundColor Yellow
    git remote add origin "https://github.com/Mouy-leng/Window-setup.git" 2>&1 | Out-Null
    Write-Host "    [OK] Remote added" -ForegroundColor Green
} else {
    # Update remote to use HTTPS
    git remote set-url origin "https://github.com/Mouy-leng/Window-setup.git" 2>&1 | Out-Null
    Write-Host "[2] Remote configured" -ForegroundColor Green
}

# Set branch to main
Write-Host "[3] Setting branch to main..." -ForegroundColor Yellow
git branch -M main 2>&1 | Out-Null
Write-Host "    [OK] Branch set to main" -ForegroundColor Green

# Add all files
Write-Host "[4] Adding files..." -ForegroundColor Yellow
git add . 2>&1 | Out-Null
Write-Host "    [OK] Files staged" -ForegroundColor Green

# Check if there are changes
$status = git status --porcelain
if ($status) {
    # Generate intelligent commit message based on changes
    $commitMessage = "Auto-commit: Update Windows setup scripts and configuration"
    
    Write-Host "[5] Committing changes..." -ForegroundColor Yellow
    git commit -m $commitMessage 2>&1 | Out-Null
    Write-Host "    [OK] Changes committed" -ForegroundColor Green
    
    $cleanOrigin = "https://github.com/Mouy-leng/Window-setup.git"

    # Push to repository
    Write-Host "[6] Pushing to GitHub..." -ForegroundColor Yellow

    if ($hasGhOAuth) {
        git remote set-url origin $cleanOrigin 2>$null | Out-Null
        $pushResult = git push -u origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Successfully pushed to GitHub (OAuth via gh)!" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] Push failed even though gh is authenticated." -ForegroundColor Red
            Write-Host "    Output: $pushResult" -ForegroundColor Yellow
        }
    } elseif ($githubToken) {
        Write-Host "    [WARNING] Using PAT fallback (git-credentials.txt). Prefer 'gh auth login' instead." -ForegroundColor Yellow
        $tokenOrigin = "https://${githubUser}:${githubToken}@github.com/Mouy-leng/Window-setup.git"

        try {
            git remote set-url origin $tokenOrigin 2>$null | Out-Null
            $pushResult = git push -u origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] Successfully pushed to GitHub (PAT fallback)!" -ForegroundColor Green
            } else {
                Write-Host "    [ERROR] Failed to push" -ForegroundColor Red
                Write-Host "    Output: $pushResult" -ForegroundColor Yellow
            }
        } finally {
            git remote set-url origin $cleanOrigin 2>$null | Out-Null
            $githubToken = $null
        }
    } else {
        Write-Host "    [ERROR] No GitHub auth available." -ForegroundColor Red
        Write-Host "    [INFO] Install GitHub CLI and login via OAuth:" -ForegroundColor Cyan
        Write-Host "      winget install --id GitHub.cli" -ForegroundColor White
        Write-Host "      gh auth login -h github.com -p https --web" -ForegroundColor White
    }
} else {
    Write-Host "[5] No changes to commit" -ForegroundColor Yellow
    Write-Host "    [OK] Repository is up to date" -ForegroundColor Green
}

Write-Host ""
Write-Host "Automated Git Push Complete!" -ForegroundColor Cyan

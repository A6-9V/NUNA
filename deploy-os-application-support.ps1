# Deployment Script
# Deploys everything to GitHub and manages the repository

param(
    [switch]$PushToGitHub,
    [switch]$PullFromGitHub,
    [switch]$FullDeploy,
    [switch]$RunAsAdmin
)

$ErrorActionPreference = "Continue"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"
$script:RepoUrl = "https://github.com/A6-9V/OS-application-support-.git"
$script:RepoUrlSSH = "git@github.com:A6-9V/OS-application-support-.git"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OS Application Support - Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $RunAsAdmin) {
    Write-Host "[WARNING] Not running as administrator. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -RunAsAdmin" -Wait
    exit
}

if (-not (Test-Path $script:RepoPath)) {
    Write-Host "[ERROR] Repository path not found: $script:RepoPath" -ForegroundColor Red
    Write-Host "[INFO] Run setup-os-application-support.ps1 first" -ForegroundColor Yellow
    exit 1
}

Set-Location $script:RepoPath

# Pull from GitHub
if ($PullFromGitHub -or $FullDeploy) {
    Write-Host "[1] Pulling from GitHub..." -ForegroundColor Yellow
    try {
        # Try SSH first
        git pull upstream main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Pulled from SSH remote" -ForegroundColor Green
        } else {
            # Fallback to HTTPS
            git pull origin main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] Pulled from HTTPS remote" -ForegroundColor Green
            } else {
                Write-Host "    [WARNING] Pull failed or no changes" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "    [ERROR] Pull failed: $_" -ForegroundColor Red
    }
}

# Add all files
Write-Host "[2] Staging files..." -ForegroundColor Yellow
try {
    git add . 2>&1 | Out-Null
    Write-Host "    [OK] Files staged" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to stage files: $_" -ForegroundColor Red
}

# Check for changes
$status = git status --porcelain 2>&1
if ($status) {
    Write-Host "[3] Committing changes..." -ForegroundColor Yellow
    try {
        $commitMessage = "Deploy: OS Application Support - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git commit -m $commitMessage 2>&1 | Out-Null
        Write-Host "    [OK] Changes committed" -ForegroundColor Green
    } catch {
        Write-Host "    [ERROR] Commit failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[3] No changes to commit" -ForegroundColor Yellow
}

# Push to GitHub
if ($PushToGitHub -or $FullDeploy) {
    Write-Host "[4] Pushing to GitHub..." -ForegroundColor Yellow
    try {
        # Push to HTTPS remote
        git push origin main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Pushed to HTTPS remote" -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] HTTPS push failed" -ForegroundColor Yellow
        }
        
        # Try SSH remote
        git push upstream main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Pushed to SSH remote" -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] SSH push failed (may need SSH key setup)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [ERROR] Push failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[OK] Deployment complete!" -ForegroundColor Green

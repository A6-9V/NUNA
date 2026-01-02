# OS Application Support - Complete Setup Script
# Sets up remote device management, trading system, and 24/7 automation
# Target: Samsung A6 9V device
# Repository: https://github.com/A6-9V/OS-application-support-.git

param(
    [switch]$RunAsAdmin,
    [switch]$SkipGitSetup,
    [switch]$SkipDeviceSetup
)

$ErrorActionPreference = "Stop"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"
$script:RepoUrl = "https://github.com/A6-9V/OS-application-support-.git"
$script:RepoUrlSSH = "git@github.com:A6-9V/OS-application-support-.git"
$script:DeviceName = "A6-9V"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OS Application Support - Complete Setup" -ForegroundColor Cyan
Write-Host "Target Device: Samsung $script:DeviceName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $RunAsAdmin) {
    Write-Host "[WARNING] Not running as administrator. Some features may not work." -ForegroundColor Yellow
    Write-Host "[INFO] Restarting with administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -RunAsAdmin" -Wait
    exit
}

Write-Host "[OK] Running with administrator privileges" -ForegroundColor Green
Write-Host ""

# Step 1: Create project directory structure
Write-Host "[1] Creating project directory structure..." -ForegroundColor Yellow
try {
    if (-not (Test-Path $script:RepoPath)) {
        New-Item -ItemType Directory -Path $script:RepoPath -Force | Out-Null
        Write-Host "    [OK] Created directory: $script:RepoPath" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Directory exists: $script:RepoPath" -ForegroundColor Green
    }
    
    # Create subdirectories
    $directories = @(
        "remote-device",
        "trading-system",
        "security",
        "monitoring",
        "deployment",
        "scripts",
        "config",
        "logs"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $script:RepoPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Host "    [OK] Created: $dir" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "    [ERROR] Failed to create directories: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Git repository setup
if (-not $SkipGitSetup) {
    Write-Host "[2] Setting up Git repository..." -ForegroundColor Yellow
    try {
        Set-Location $script:RepoPath
        
        # Initialize git if needed
        if (-not (Test-Path ".git")) {
            git init | Out-Null
            Write-Host "    [OK] Git initialized" -ForegroundColor Green
        }
        
        # Configure git user
        git config user.name "A6-9V" | Out-Null
        git config user.email "A6-9V@users.noreply.github.com" | Out-Null
        Write-Host "    [OK] Git user configured" -ForegroundColor Green
        
        # Set up remotes
        $remotes = git remote -v 2>&1
        if (-not ($remotes -match "origin")) {
            git remote add origin $script:RepoUrl 2>&1 | Out-Null
            Write-Host "    [OK] Added HTTPS remote" -ForegroundColor Green
        } else {
            git remote set-url origin $script:RepoUrl 2>&1 | Out-Null
            Write-Host "    [OK] Updated HTTPS remote" -ForegroundColor Green
        }
        
        # Add SSH remote as upstream
        $upstreamCheck = git remote -v 2>&1 | Select-String "upstream"
        if (-not $upstreamCheck) {
            git remote add upstream $script:RepoUrlSSH 2>&1 | Out-Null
            Write-Host "    [OK] Added SSH remote (upstream)" -ForegroundColor Green
        }
        
        # Set branch to main
        git branch -M main 2>&1 | Out-Null
        Write-Host "    [OK] Branch set to main" -ForegroundColor Green
        
    } catch {
        Write-Host "    [ERROR] Git setup failed: $_" -ForegroundColor Red
    }
}

# Step 3: Create core configuration files
Write-Host "[3] Creating configuration files..." -ForegroundColor Yellow
try {
    # Main README
    $readmeContent = @"
# OS Application Support

Complete system for remote device management, trading system support, and 24/7 automation.

## Target Device
- **Device**: Samsung A6 9V
- **Purpose**: Trading system support with real-time updates
- **Features**: Remote control, VPS support, WiFi security, app protection

## Repository
- HTTPS: $script:RepoUrl
- SSH: $script:RepoUrlSSH

## Structure
- `remote-device/` - Remote device management scripts
- `trading-system/` - Trading system support infrastructure
- `security/` - Security features (VPS, WiFi, app protection)
- `monitoring/` - 24/7 monitoring and automation
- `deployment/` - Deployment scripts
- `scripts/` - Utility scripts
- `config/` - Configuration files
- `logs/` - Log files

## Setup
Run `setup-os-application-support.ps1` as administrator to set up everything.

## Security
All credentials and tokens are stored securely and never committed to git.
"@
    Set-Content -Path (Join-Path $script:RepoPath "README.md") -Value $readmeContent
    Write-Host "    [OK] Created README.md" -ForegroundColor Green
    
    # .gitignore
    $gitignoreContent = @"
# Security - Never commit
*.token
*.secret
*credentials*
*config.local*
*.pem
*.key

# Logs
logs/
*.log

# Temporary files
*.tmp
*.temp
__pycache__/
*.pyc

# OS files
.DS_Store
Thumbs.db
desktop.ini
"@
    Set-Content -Path (Join-Path $script:RepoPath ".gitignore") -Value $gitignoreContent
    Write-Host "    [OK] Created .gitignore" -ForegroundColor Green
    
} catch {
    Write-Host "    [ERROR] Failed to create config files: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[OK] Initial setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: .\setup-remote-device.ps1" -ForegroundColor Yellow
Write-Host "2. Run: .\setup-trading-system.ps1" -ForegroundColor Yellow
Write-Host "3. Run: .\setup-security.ps1" -ForegroundColor Yellow
Write-Host "4. Run: .\setup-monitoring.ps1" -ForegroundColor Yellow
Write-Host ""

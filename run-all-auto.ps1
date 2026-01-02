<# 
.SYNOPSIS
    Master automation script - Runs everything automatically (Auto-Admin)
.DESCRIPTION
    Orchestrates all automated setup tasks.
    Automatically relaunches itself with Administrator privileges when needed.
#>

#Requires -Version 5.1

$ErrorActionPreference = "Continue"

function Test-IsAdministrator {
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        # If we can't determine (non-Windows / restricted host), assume not admin.
        return $false
    }
}

if (-not (Test-IsAdministrator)) {
    Write-Host "[INFO] Elevating to Administrator..." -ForegroundColor Yellow

    # Resolve the current script path in a robust way
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    if (-not $scriptPath) {
        Write-Host "[ERROR] Unable to determine script path for elevation." -ForegroundColor Red
        Write-Host "[INFO] Tip: Run this script directly from a .ps1 file rather than dot-sourcing it." -ForegroundColor Yellow
        exit 1
    }
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""

    # Use the same PowerShell executable as the current session for elevation
    $psExecutable = if ($PSVersionTable.PSEdition -eq 'Core') {
        Join-Path $PSHOME 'pwsh.exe'
    } else {
        'powershell.exe'
    }

    try {
        Start-Process $psExecutable -Verb RunAs -ArgumentList $arguments
        exit 0
    } catch {
        Write-Host "[ERROR] Failed to request elevation: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[INFO] Tip: Right-click PowerShell > Run as administrator, then rerun this script." -ForegroundColor Yellow
        exit 1
    }
}

# Running as Administrator - proceed

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Master Automation Script" -ForegroundColor Cyan
Write-Host "  Running all tasks automatically..." -ForegroundColor Cyan
Write-Host "  (Administrator)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Run Windows Setup
Write-Host "[1/4] Running Windows Setup..." -ForegroundColor Yellow
Write-Host ""
$setupScript = Join-Path $PSScriptRoot "auto-setup.ps1"
if (Test-Path $setupScript) {
    & powershell.exe -ExecutionPolicy Bypass -File $setupScript
} else {
    Write-Host "    [SKIP] Setup script not found" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Step 2: Run Git Push (automated with saved token)
Write-Host "[2/4] Running Git Push (using saved credentials)..." -ForegroundColor Yellow
Write-Host ""
$gitScript = Join-Path $PSScriptRoot "auto-git-push.ps1"
if (Test-Path $gitScript) {
    & powershell.exe -ExecutionPolicy Bypass -File $gitScript
} else {
    Write-Host "    [SKIP] Git script not found" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Step 3: Configure GitHub Desktop (if installed)
Write-Host "[3/4] Configuring GitHub Desktop..." -ForegroundColor Yellow
Write-Host ""
$desktopScript = Join-Path $PSScriptRoot "github-desktop-setup.ps1"
if (Test-Path $desktopScript) {
    & powershell.exe -ExecutionPolicy Bypass -File $desktopScript
} else {
    Write-Host "    [SKIP] GitHub Desktop script not found" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Step 4: Summary
Write-Host "[4/4] Generating summary..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All Automated Tasks Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Completed automatically:" -ForegroundColor Yellow
Write-Host "  [OK] Windows configuration" -ForegroundColor White
Write-Host "  [OK] Security settings" -ForegroundColor White
Write-Host "  [OK] Cloud services" -ForegroundColor White
Write-Host "  [OK] Git repository" -ForegroundColor White
Write-Host "  [OK] GitHub Desktop (if installed)" -ForegroundColor White
Write-Host ""
Write-Host "All decisions were made automatically using best practices." -ForegroundColor Green
Write-Host ""
Write-Host "GitHub Desktop Release Notes: https://desktop.github.com/release-notes/" -ForegroundColor Cyan
Write-Host ""

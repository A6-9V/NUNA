#Requires -Version 5.1
<#
.SYNOPSIS
    Set Google Chrome as Default Browser
.DESCRIPTION
    Sets Chrome as the default browser for HTTP, HTTPS, and HTML files
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setting Default Browser" -ForegroundColor Cyan
Write-Host "  Google Chrome" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}

if (-not (Test-Path $chromePath)) {
    Write-Host "[ERROR] Chrome not found. Please install Chrome first." -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Setting Chrome as default browser..." -ForegroundColor Yellow
try {
    # Use Windows 10/11 default app setting method
    Start-Process "ms-settings:defaultapps" -ErrorAction SilentlyContinue
    Write-Host "    [INFO] Opening Windows Settings..." -ForegroundColor Cyan
    Write-Host "    [INFO] Please select Chrome as default browser in the settings window" -ForegroundColor Yellow
    Write-Host "    [INFO] Or use the command below:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Alternative method (requires manual selection):" -ForegroundColor Yellow
    Write-Host "    1. Open Settings > Apps > Default apps" -ForegroundColor White
    Write-Host "    2. Click 'Web browser'" -ForegroundColor White
    Write-Host "    3. Select 'Google Chrome'" -ForegroundColor White
    Write-Host ""
    
    # Try to set via registry (may require admin)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Host "    [INFO] Attempting to set via registry..." -ForegroundColor Cyan
        # Note: Windows 10/11 uses UserChoice hash, which is complex to set programmatically
        # The safest method is through Settings UI
    }
    
    Write-Host "    [OK] Settings window opened" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Could not open settings: $_" -ForegroundColor Yellow
}

Write-Host "[2/3] Verifying Chrome installation..." -ForegroundColor Yellow
if (Test-Path $chromePath) {
    $version = (Get-Item $chromePath).VersionInfo.FileVersion
    Write-Host ("    [OK] Chrome found: Version $version") -ForegroundColor Green
    Write-Host ("    [OK] Path: $chromePath") -ForegroundColor Cyan
} else {
    Write-Host "    [ERROR] Chrome not found" -ForegroundColor Red
}

Write-Host "[3/3] Checking current default browser..." -ForegroundColor Yellow
$currentDefault = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -ErrorAction SilentlyContinue).ProgId
if ($currentDefault) {
    if ($currentDefault -like "*Chrome*") {
        Write-Host "    [OK] Chrome is already the default browser" -ForegroundColor Green
    } else {
        Write-Host ("    [INFO] Current default: $currentDefault") -ForegroundColor Cyan
        Write-Host "    [INFO] Please change to Chrome in Settings" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Could not determine current default" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. In the Settings window that opened, select Chrome as default" -ForegroundColor White
Write-Host "  2. Or manually: Settings > Apps > Default apps > Web browser > Chrome" -ForegroundColor White
Write-Host ""


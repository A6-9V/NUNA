# Apply Registry Settings for ASUS PC Optimization
# Requires Administrator privileges

param(
    [switch]$DryRun
)

# Requires Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Continue"

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    
    try {
        if (-not (Test-Path $Path)) {
            if (-not $DryRun) {
                New-Item -Path $Path -Force | Out-Null
            }
            Write-Host "  Created registry path: $Path" -ForegroundColor Gray
        }
        
        if (-not $DryRun) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
            Write-Host "  ✓ $Name = $Value" -ForegroundColor Green
        } else {
            Write-Host "  [DRY RUN] Would set $Name = $Value" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ✗ Failed to set $Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=== Applying Registry Settings ===" -ForegroundColor Cyan
Write-Host "Dry Run Mode: $DryRun`n" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "White" })

# Performance Optimizations
Write-Host "Performance Optimizations..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 1
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 1

# File Explorer Settings
Write-Host "`nFile Explorer Settings..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1

# Developer Mode
Write-Host "`nDeveloper Settings..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1

# ASUS-Specific Settings
Write-Host "`nASUS Settings..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\ASUS" -Name "ShowNotifications" -Value 0 -ErrorAction SilentlyContinue

# Windows Search (Optional - disable on non-OS drives)
Write-Host "`nWindows Search Settings..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Search" -Name "SetupCompletedSuccessfully" -Value 1 -ErrorAction SilentlyContinue

# Network Optimizations
Write-Host "`nNetwork Optimizations..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue

Write-Host "`n=== Registry Settings Applied ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n⚠️ DRY RUN MODE - No changes were made" -ForegroundColor Yellow
}


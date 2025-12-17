#Requires -Version 5.1
<#
.SYNOPSIS
    Configure Windows Firewall for MetaTrader Exness Trading Bridge Port 5500
.DESCRIPTION
    This script creates a firewall rule to allow inbound connections on port 5500
    for the MetaTrader Exness trading bridge communication.
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Firewall Configuration" -ForegroundColor Cyan
Write-Host "  MetaTrader Exness Bridge Port 5500" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires administrator privileges" -ForegroundColor Red
    Write-Host "[INFO] Please run this script as administrator" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Right-click and select 'Run as administrator'" -ForegroundColor Cyan
    exit 1
}

$port = 5500
$ruleName = "MetaTrader Exness Trading Bridge"
$ruleDescription = "Allow inbound connections on port 5500 for MetaTrader Exness trading bridge communication"

Write-Host "[1/3] Checking existing firewall rules..." -ForegroundColor Yellow
try {
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "    [INFO] Firewall rule already exists" -ForegroundColor Cyan
        Write-Host "    [INFO] Removing existing rule to update..." -ForegroundColor Cyan
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        Write-Host "    [OK] Existing rule removed" -ForegroundColor Green
    }
    else {
        Write-Host "    [OK] No existing rule found" -ForegroundColor Green
    }
}
catch {
    Write-Host "    [WARNING] Could not check existing rules: $_" -ForegroundColor Yellow
}

Write-Host "[2/3] Creating firewall rule for port $port..." -ForegroundColor Yellow
try {
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Description $ruleDescription `
        -Direction Inbound `
        -LocalPort $port `
        -Protocol TCP `
        -Action Allow `
        -Profile Any `
        -ErrorAction Stop
    
    Write-Host "    [OK] Firewall rule created successfully" -ForegroundColor Green
    Write-Host "    [INFO] Rule name: $ruleName" -ForegroundColor Cyan
    Write-Host "    [INFO] Port: $port" -ForegroundColor Cyan
    Write-Host "    [INFO] Protocol: TCP" -ForegroundColor Cyan
    Write-Host "    [INFO] Action: Allow" -ForegroundColor Cyan
}
catch {
    Write-Host "    [ERROR] Failed to create firewall rule: $_" -ForegroundColor Red
    exit 1
}

Write-Host "[3/3] Verifying firewall rule..." -ForegroundColor Yellow
try {
    $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
    $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
    
    if ($rule -and $portFilter.LocalPort -eq $port) {
        Write-Host "    [OK] Firewall rule verified successfully" -ForegroundColor Green
        Write-Host "    [INFO] Rule enabled: $($rule.Enabled)" -ForegroundColor Cyan
        Write-Host "    [INFO] Rule direction: $($rule.Direction)" -ForegroundColor Cyan
    }
    else {
        Write-Host "    [WARNING] Rule verification incomplete" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "    [WARNING] Could not verify firewall rule: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Firewall rule configured:" -ForegroundColor Green
Write-Host "  - Port: $port" -ForegroundColor White
Write-Host "  - Protocol: TCP" -ForegroundColor White
Write-Host "  - Direction: Inbound" -ForegroundColor White
Write-Host "  - Action: Allow" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Ensure MetaTrader Exness terminal is running" -ForegroundColor White
Write-Host "  2. Start the Python trading bridge service" -ForegroundColor White
Write-Host "  3. Verify connection on port $port" -ForegroundColor White
Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green


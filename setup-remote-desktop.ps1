#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Setup Remote Desktop Connection (RDP) on Windows 11
.DESCRIPTION
    Enables and configures Remote Desktop for remote access to this computer
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Remote Desktop Setup" -ForegroundColor Cyan
Write-Host "  Windows 11 Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Enable Remote Desktop
Write-Host "[1/5] Enabling Remote Desktop..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -ErrorAction Stop
    Write-Host "    [OK] Remote Desktop enabled" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to enable Remote Desktop: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Configure Windows Firewall
Write-Host "[2/5] Configuring Windows Firewall..." -ForegroundColor Yellow
try {
    # Enable RDP firewall rule
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    Write-Host "    [OK] Firewall rules configured" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Firewall configuration had issues: $_" -ForegroundColor Yellow
}

# Step 3: Set Network Level Authentication (NLA)
Write-Host "[3/5] Configuring Network Level Authentication..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1 -ErrorAction Stop
    Write-Host "    [OK] Network Level Authentication enabled (more secure)" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] NLA configuration had issues: $_" -ForegroundColor Yellow
}

# Step 4: Get current IP address
Write-Host "[4/5] Getting network information..." -ForegroundColor Yellow
try {
    $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
    if ($ipAddresses) {
        $localIP = $ipAddresses.IPAddress
        Write-Host "    [OK] Local IP Address: $localIP" -ForegroundColor Green
    } else {
        Write-Host "    [WARNING] Could not determine IP address" -ForegroundColor Yellow
        $localIP = "Unknown"
    }
} catch {
    Write-Host "    [WARNING] Network information unavailable: $_" -ForegroundColor Yellow
    $localIP = "Unknown"
}

# Step 5: Display connection information
Write-Host "[5/5] Remote Desktop Configuration Complete!" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Connection Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To connect to this computer:" -ForegroundColor Yellow
Write-Host "  1. From another computer, open Remote Desktop Connection" -ForegroundColor White
Write-Host "  2. Enter computer name or IP address:" -ForegroundColor White
Write-Host "     - Computer Name: $env:COMPUTERNAME" -ForegroundColor Cyan
if ($localIP -ne "Unknown") {
    Write-Host "     - IP Address: $localIP" -ForegroundColor Cyan
}
Write-Host "  3. Use your Windows username and password" -ForegroundColor White
Write-Host ""
Write-Host "Security Notes:" -ForegroundColor Yellow
Write-Host "  - Network Level Authentication is enabled (recommended)" -ForegroundColor White
Write-Host "  - Only users with password-protected accounts can connect" -ForegroundColor White
Write-Host "  - Consider using a VPN for remote access over internet" -ForegroundColor White
Write-Host ""
Write-Host "To find your IP address later:" -ForegroundColor Yellow
Write-Host "  ipconfig" -ForegroundColor Cyan
Write-Host ""

# Save connection info to file
$connectionInfo = @"
========================================
Remote Desktop Connection Information
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

Computer Name: $env:COMPUTERNAME
IP Address: $localIP

To Connect:
----------
1. Open Remote Desktop Connection (mstsc.exe)
2. Enter: $env:COMPUTERNAME
   Or: $localIP
3. Use your Windows username and password

Security:
---------
- Network Level Authentication: Enabled
- Firewall: Configured
- Only password-protected accounts can connect

Notes:
------
- For internet access, configure port forwarding on your router (port 3389)
- Consider using VPN for better security
- Keep Windows updated for security patches

========================================
"@

$infoFile = Join-Path $PSScriptRoot "remote-desktop-info.txt"
$connectionInfo | Out-File -FilePath $infoFile -Encoding UTF8
Write-Host "[OK] Connection information saved to: remote-desktop-info.txt" -ForegroundColor Green
Write-Host ""

# Verify Remote Desktop is enabled
Write-Host "Verifying Remote Desktop status..." -ForegroundColor Yellow
$rdpEnabled = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections
if ($rdpEnabled -eq 0) {
    Write-Host "[OK] Remote Desktop is ENABLED" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Remote Desktop is still DISABLED" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""





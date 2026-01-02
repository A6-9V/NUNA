#Requires -Version 5.1
<#
.SYNOPSIS
    Open Windows Firewall for Trading System (bridge + website).
.DESCRIPTION
    Creates Windows Defender Firewall allow rules for the trading system:
    - Trading Bridge (default TCP 5500)  -> loopback-only by default (secure)
    - Website service (default TCP 8000) -> LAN-only by default
    - Support portal (default TCP 8080)  -> LAN-only by default

    The script is idempotent: it replaces any existing rules with the same DisplayName.

    Security defaults follow project guidance: do NOT expose the bridge port to the internet.
.PARAMETER BridgePort
    TCP port for the Python<->MQL5 bridge (default 5500).
.PARAMETER WebsitePort
    TCP port for the local website service (default 8000).
.PARAMETER PortalPort
    TCP port for the support-portal container (default 8080).
.PARAMETER AllowBridgeFromLAN
    Allow bridge connections from LocalSubnet (NOT recommended unless you know why you need it).
.PARAMETER AllowWebsiteFromAny
    Allow website/portal from any remote address (internet). Use with extreme caution.
.PARAMETER IncludePublicProfile
    Include the Public firewall profile (default: false). Prefer Domain/Private.
.EXAMPLE
    # Run as Administrator
    .\open-trading-system-firewall.ps1
.EXAMPLE
    # If you must access the website from another LAN device
    .\open-trading-system-firewall.ps1 -WebsitePort 8000
.EXAMPLE
    # If MT5 is on another machine in the same LAN (not recommended on VPS)
    .\open-trading-system-firewall.ps1 -AllowBridgeFromLAN
#>

[CmdletBinding()]
param(
    [int]$BridgePort = 5500,
    [int]$WebsitePort = 8000,
    [int]$PortalPort = 8080,
    [switch]$AllowBridgeFromLAN,
    [switch]$AllowWebsiteFromAny,
    [switch]$IncludePublicProfile
)

$ErrorActionPreference = "Continue"

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Err([string]$Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Assert-Administrator {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
        if (-not $isAdmin) {
            Write-Err "This script requires administrator privileges."
            Write-Info "Right-click PowerShell and choose 'Run as administrator'."
            exit 1
        }
    } catch {
        Write-Err "Could not verify administrator privileges: $($_.Exception.Message)"
        exit 1
    }
}

function Get-Profiles {
    if ($IncludePublicProfile) { return @("Domain", "Private", "Public") }
    return @("Domain", "Private")
}

function Ensure-InboundTcpPortRule {
    param(
        [Parameter(Mandatory=$true)][string]$DisplayName,
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][int]$Port,
        [Parameter(Mandatory=$true)][string[]]$Profiles,
        [Parameter(Mandatory=$true)][string[]]$RemoteAddresses
    )

    try {
        $existing = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Info "Updating existing firewall rule: $DisplayName"
            Remove-NetFirewallRule -DisplayName $DisplayName -ErrorAction Stop
            Write-Ok "Removed previous rule"
        } else {
            Write-Info "Creating firewall rule: $DisplayName"
        }

        New-NetFirewallRule `
            -DisplayName $DisplayName `
            -Description $Description `
            -Group "Trading System" `
            -Direction Inbound `
            -LocalPort $Port `
            -Protocol TCP `
            -Action Allow `
            -Profile $Profiles `
            -RemoteAddress $RemoteAddresses `
            -Enabled True `
            -ErrorAction Stop | Out-Null

        $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction Stop
        $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue
        $addrFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue

        Write-Ok "Rule active: $DisplayName"
        if ($portFilter) { Write-Info "  Port: $($portFilter.LocalPort) / Protocol: $($portFilter.Protocol)" }
        if ($addrFilter) { Write-Info "  RemoteAddress: $($addrFilter.RemoteAddress -join ', ')" }
        Write-Info "  Profiles: $($Profiles -join ', ')"
    } catch {
        Write-Err "Failed to create/update rule '$DisplayName': $($_.Exception.Message)"
        throw
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Firewall Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Assert-Administrator

$profiles = Get-Profiles

Write-Info "Firewall profiles: $($profiles -join ', ')"
Write-Host ""

# Bridge: secure default (loopback only)
$bridgeRemote = @("127.0.0.1")
if ($AllowBridgeFromLAN) {
    Write-Warn "AllowBridgeFromLAN enabled: bridge port will be reachable from LocalSubnet."
    $bridgeRemote = @("LocalSubnet")
}

# Website/Portal: LAN by default, optionally Any
$siteRemote = @("LocalSubnet")
if ($AllowWebsiteFromAny) {
    Write-Warn "AllowWebsiteFromAny enabled: website/portal will be reachable from ANY remote address."
    $siteRemote = @("Any")
}

Write-Host "[1/3] Trading Bridge (TCP $BridgePort)" -ForegroundColor Yellow
Ensure-InboundTcpPortRule `
    -DisplayName "Trading System - Bridge (TCP $BridgePort)" `
    -Description "Allow inbound TCP $BridgePort for Python<->MQL5 trading bridge (default loopback-only)" `
    -Port $BridgePort `
    -Profiles $profiles `
    -RemoteAddresses $bridgeRemote

Write-Host ""
Write-Host "[2/3] Website Service (TCP $WebsitePort)" -ForegroundColor Yellow
Ensure-InboundTcpPortRule `
    -DisplayName "Trading System - Website (TCP $WebsitePort)" `
    -Description "Allow inbound TCP $WebsitePort for local website service (LAN by default)" `
    -Port $WebsitePort `
    -Profiles $profiles `
    -RemoteAddresses $siteRemote

Write-Host ""
Write-Host "[3/3] Support Portal (TCP $PortalPort)" -ForegroundColor Yellow
Ensure-InboundTcpPortRule `
    -DisplayName "Trading System - Portal (TCP $PortalPort)" `
    -Description "Allow inbound TCP $PortalPort for support portal container/static site (LAN by default)" `
    -Port $PortalPort `
    -Profiles $profiles `
    -RemoteAddresses $siteRemote

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Firewall setup complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Ok "Rules created/updated under firewall group: Trading System"
Write-Info "If you only need local access on the VPS, the defaults are safest."


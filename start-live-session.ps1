<# 
.SYNOPSIS
    Start a new Live Session (Trading / Earnings / Plugin).
.DESCRIPTION
    Creates a timestamped session folder, archives current VPS logs, and starts
    long-running services in the background:
    - Trading: master-trading-orchestrator.ps1 + trading-bridge-service.ps1
    - Earnings: research-service.ps1
    - Plugin: mql5-service.ps1
    - Live: master-controller.ps1 (24/7 service supervisor)

    Designed to run from the OneDrive workspace root (recommended), but will
    attempt to locate it automatically when launched elsewhere.
.NOTES
    Requires admin. Auto-elevates if needed.
#>

[CmdletBinding()]
param(
    [string]$SessionName = "live",
    [switch]$Trading,
    [switch]$Earnings,
    [switch]$Plugin,
    [switch]$Live
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet("OK","INFO","WARNING","ERROR")]
        [string]$Level = "INFO"
    )

    $color = switch ($Level) {
        "OK" { "Green" }
        "INFO" { "Cyan" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-IsAdmin {
    try {
        return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
            IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Get-WorkspaceRoot {
    param([string]$HintPath)

    # If running from the workspace root, prefer that.
    if ($HintPath) {
        try {
            $root = Split-Path -Parent $HintPath
            if (Test-Path (Join-Path $root "vps-services")) { return $root }
        } catch {}
    }

    # If script is in workspace root.
    try {
        if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "vps-services"))) {
            return $PSScriptRoot
        }
    } catch {}

    # Try OneDrive.
    $oneDrive = $null
    try { $oneDrive = $env:OneDrive } catch {}
    if (-not $oneDrive) {
        try {
            if ($env:USERPROFILE) { $oneDrive = Join-Path $env:USERPROFILE "OneDrive" }
        } catch {}
    }
    if ($oneDrive -and (Test-Path (Join-Path $oneDrive "vps-services"))) { return $oneDrive }

    # Fallback: current directory.
    try { return (Get-Location).Path } catch { return "C:\Users\USER\OneDrive" }
}

# If user didn't specify any session toggles, enable all.
if (-not ($Trading -or $Earnings -or $Plugin -or $Live)) {
    $Trading = $true
    $Earnings = $true
    $Plugin = $true
    $Live = $true
}

# Auto-elevate if needed.
if (-not (Test-IsAdmin)) {
    Write-Status "Elevating to Administrator..." "WARNING"
    $scriptPath = $MyInvocation.MyCommand.Path
    $argsList = @("-ExecutionPolicy","Bypass","-File",$scriptPath)
    if ($SessionName) { $argsList += @("-SessionName", $SessionName) }
    if ($Trading) { $argsList += "-Trading" }
    if ($Earnings) { $argsList += "-Earnings" }
    if ($Plugin) { $argsList += "-Plugin" }
    if ($Live) { $argsList += "-Live" }

    Start-Process powershell.exe -Verb RunAs -ArgumentList $argsList -WindowStyle Normal
    exit 0
}

$workspaceRoot = Get-WorkspaceRoot -HintPath $MyInvocation.MyCommand.Path
$vpsServicesPath = Join-Path $workspaceRoot "vps-services"
$vpsLogsPath = Join-Path $workspaceRoot "vps-logs"
$sessionsRoot = Join-Path $workspaceRoot "vps-sessions"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safeSessionName = ($SessionName -replace "[^a-zA-Z0-9\-_]+","-").Trim("-")
if (-not $safeSessionName) { $safeSessionName = "live" }
$sessionId = "$timestamp-$safeSessionName"
$sessionPath = Join-Path $sessionsRoot $sessionId

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting NEW LIVE SESSION" -ForegroundColor Cyan
Write-Host "  Session: $sessionId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($dir in @($vpsLogsPath, $sessionsRoot, $sessionPath)) {
    try {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Status "Created: $dir" "OK"
        }
    } catch {
        Write-Status "Failed to create directory ($dir): $_" "ERROR"
    }
}

# Create session structure + markers
$tradingDir  = Join-Path $sessionPath "trading-session"
$earningsDir = Join-Path $sessionPath "earnings-session"
$pluginDir   = Join-Path $sessionPath "plugin-session"
$metaDir     = Join-Path $sessionPath "meta"

foreach ($dir in @($tradingDir, $earningsDir, $pluginDir, $metaDir)) {
    try { New-Item -ItemType Directory -Path $dir -Force | Out-Null } catch {}
}

try {
    $manifestPath = Join-Path $metaDir "session-info.json"
    $manifest = [PSCustomObject]@{
        sessionId = $sessionId
        sessionName = $SessionName
        startedAt = (Get-Date).ToString("o")
        workspaceRoot = $workspaceRoot
        enabled = @{
            trading = [bool]$Trading
            earnings = [bool]$Earnings
            plugin = [bool]$Plugin
            live = [bool]$Live
        }
    } | ConvertTo-Json -Depth 5
    $manifest | Out-File -FilePath $manifestPath -Encoding UTF8 -Force
} catch {
    Write-Status "Could not write session manifest: $_" "WARNING"
}

# Archive existing VPS logs into this session
try {
    $archiveDir = Join-Path $metaDir "vps-logs-archive"
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

    $logFiles = Get-ChildItem -Path $vpsLogsPath -File -ErrorAction SilentlyContinue
    if ($logFiles) {
        foreach ($f in $logFiles) {
            try {
                $dest = Join-Path $archiveDir $f.Name
                Move-Item -Path $f.FullName -Destination $dest -Force
            } catch {
                # If move fails (locked file), copy instead.
                try {
                    Copy-Item -Path $f.FullName -Destination (Join-Path $archiveDir $f.Name) -Force
                } catch {}
            }
        }
        Write-Status "Archived existing vps-logs into session folder" "OK"
    } else {
        Write-Status "No existing vps-logs to archive" "INFO"
    }
} catch {
    Write-Status "Log archive step had issues: $_" "WARNING"
}

function Start-BackgroundScript {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [Parameter(Mandatory=$true)][string]$Name
    )

    if (-not (Test-Path $ScriptPath)) {
        Write-Status "$Name script not found: $ScriptPath" "WARNING"
        return
    }

    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy","Bypass",
            "-WindowStyle","Hidden",
            "-File",$ScriptPath
        ) -WindowStyle Hidden | Out-Null
        Write-Status "Started: $Name" "OK"
    } catch {
        Write-Status "Failed to start $Name: $_" "ERROR"
    }
}

# Trading session
if ($Trading) {
    try { "startedAt=$([DateTime]::Now.ToString("o"))" | Out-File -FilePath (Join-Path $tradingDir "started.txt") -Force } catch {}

    $orchestrator = Join-Path $workspaceRoot "master-trading-orchestrator.ps1"
    Start-BackgroundScript -ScriptPath $orchestrator -Name "Trading Orchestrator"

    $tradingBridgeService = Join-Path $vpsServicesPath "trading-bridge-service.ps1"
    Start-BackgroundScript -ScriptPath $tradingBridgeService -Name "Trading Bridge Service"
}

# Earnings session
if ($Earnings) {
    try { "startedAt=$([DateTime]::Now.ToString("o"))" | Out-File -FilePath (Join-Path $earningsDir "started.txt") -Force } catch {}

    $researchService = Join-Path $vpsServicesPath "research-service.ps1"
    Start-BackgroundScript -ScriptPath $researchService -Name "Earnings/Research Service"
}

# Plugin session
if ($Plugin) {
    try { "startedAt=$([DateTime]::Now.ToString("o"))" | Out-File -FilePath (Join-Path $pluginDir "started.txt") -Force } catch {}

    $mql5Service = Join-Path $vpsServicesPath "mql5-service.ps1"
    Start-BackgroundScript -ScriptPath $mql5Service -Name "Plugin/MQL5 Service"
}

# Live session (service supervisor)
if ($Live) {
    $masterController = Join-Path $vpsServicesPath "master-controller.ps1"
    Start-BackgroundScript -ScriptPath $masterController -Name "Live Master Controller"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LIVE SESSION STARTED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Status "Session folder: $sessionPath" "OK"
Write-Status "VPS logs folder: $vpsLogsPath" "INFO"
Write-Status "Verify services: .\vps-verification.ps1" "INFO"


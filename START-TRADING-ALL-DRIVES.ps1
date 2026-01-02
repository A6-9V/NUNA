#Requires -Version 5.1
<#
.SYNOPSIS
    Start trading services by locating this repo on any drive.
.DESCRIPTION
    - Finds `trading-bridge\start-background.ps1` across available drives (C:, D:, E:, ...)
    - Starts the Python trading background service once (avoids duplicate instances)
    - Optionally launches Exness MT5 (terminal64.exe) using the existing launcher if present

    This solves setups where the workspace exists on different drive letters.
#>

param(
    # Also launch Exness/MT5 using launch-exness-trading.ps1 (if present)
    [Parameter(Mandatory = $false)]
    [switch]$LaunchExness,

    # Deep scan can be slow; default is fast scan of common locations.
    [Parameter(Mandatory = $false)]
    [switch]$DeepScan
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
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Get-DriveRoots {
    try {
        $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        if ($drives) {
            return $drives | ForEach-Object { "$($_.DeviceID)\" }
        }
    } catch { }

    # Fallback
    return @("C:\")
}

function Find-TradingBridgeStartScript {
    param([switch]$DeepScan)

    # First: relative to this script (if running from repo root)
    try {
        $local = Join-Path $PSScriptRoot "trading-bridge\start-background.ps1"
        if (Test-Path $local) { return $local }
    } catch { }

    $user = $env:USERNAME
    $candidateRelativePaths = @(
        "trading-bridge\start-background.ps1",
        "Users\$user\OneDrive\trading-bridge\start-background.ps1",
        "Users\$user\OneDrive\Documents\trading-bridge\start-background.ps1",
        "Users\$user\Desktop\trading-bridge\start-background.ps1"
    )

    foreach ($root in (Get-DriveRoots)) {
        foreach ($rel in $candidateRelativePaths) {
            $p = Join-Path $root $rel
            if (Test-Path $p) { return $p }
        }
    }

    if (-not $DeepScan) { return $null }

    # Deep scan: look for start-background.ps1 but avoid huge recursion when possible
    foreach ($root in (Get-DriveRoots)) {
        try {
            $found = Get-ChildItem -Path $root -Filter "start-background.ps1" -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -like "*\trading-bridge\start-background.ps1" } |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        } catch { }
    }

    return $null
}

function Test-PythonServiceRunning {
    try {
        $p = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -like "*background_service.py*"
        }
        return [bool]$p
    } catch {
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  START TRADING (All Drives)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-PythonServiceRunning) {
    Write-Status "Python trading service already running (background_service.py)" "OK"
} else {
    $startScript = Find-TradingBridgeStartScript -DeepScan:$DeepScan
    if (-not $startScript) {
        Write-Status "Could not find trading-bridge start script on any drive." "ERROR"
        Write-Status "Expected: trading-bridge\\start-background.ps1 (somewhere on C:/D:/E:...)" "INFO"
        exit 1
    }

    Write-Status "Found trading bridge start script: $startScript" "OK"
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $startScript
        ) -WindowStyle Hidden | Out-Null

        Start-Sleep -Seconds 2
        if (Test-PythonServiceRunning) {
            Write-Status "Python trading service started." "OK"
        } else {
            Write-Status "Start requested, but Python process not detected yet (check logs)." "WARNING"
        }
    } catch {
        Write-Status "Failed to start trading bridge: $_" "ERROR"
        exit 1
    }
}

if ($LaunchExness) {
    $launcher = Join-Path $PSScriptRoot "launch-exness-trading.ps1"
    if (Test-Path $launcher) {
        Write-Status "Launching Exness MT5..." "INFO"
        try {
            Start-Process powershell.exe -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Hidden",
                "-File", $launcher
            ) -WindowStyle Hidden | Out-Null
            Write-Status "Exness launcher started." "OK"
        } catch {
            Write-Status "Exness launcher failed: $_" "WARNING"
        }
    } else {
        Write-Status "launch-exness-trading.ps1 not found next to this script." "WARNING"
    }
}

Write-Host ""
Write-Status "Done. Check logs in trading-bridge\\logs\\" "INFO"


#Requires -Version 5.1
<#
.SYNOPSIS
    Export Exness/MT5 data and create an AES-256 encrypted archive.
.DESCRIPTION
    This script collects important MetaTrader/Exness terminal data (MQL5 code, profiles, templates, etc.)
    and optionally includes Program Files / ProgramData.

    It then creates an encrypted .7z archive using 7-Zip (AES-256).

    SECURITY:
    - Does NOT print the password.
    - Excludes common credential/session files by default.
    - Output folder should NOT be committed to git.

.PARAMETER OutputDir
    Where to write the export folder and encrypted archive.
.PARAMETER PasswordEnvVar
    Name of env var containing the archive password (default: BACKUP_PASSPHRASE).
.PARAMETER IncludeProgramFiles
    Include installation binaries (large; usually not needed).
.PARAMETER IncludeProgramData
    Include ProgramData (can contain sensitive info; recommended only when encrypted).
.PARAMETER TerminalExePath
    Path to terminal64.exe (used to infer install directory).
.PARAMETER DryRun
    If set, prints what it would do without copying/archiving.
#>

param(
    [string]$OutputDir,
    [string]$PasswordEnvVar = "BACKUP_PASSPHRASE",
    [switch]$IncludeProgramFiles,
    [switch]$IncludeProgramData,
    [string]$TerminalExePath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe",
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("OK","INFO","WARNING","ERROR")][string]$Level = "INFO"
    )
    $color = switch ($Level) {
        "OK" { "Green" }
        "INFO" { "Cyan" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Get-FirstExistingPath {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)
    if ($DryRun) { return }
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-Tree {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [string[]]$ExcludeFiles = @(),
        [string[]]$ExcludeDirs = @()
    )
    if (-not (Test-Path $Source)) {
        Write-Status "Missing source, skipping: $Source" "WARNING"
        return
    }
    Ensure-Directory -Path $Destination

    # Use robocopy for stability and exclusions
    $args = @(
        $Source,
        $Destination,
        "/E",
        "/COPY:DAT",
        "/R:1",
        "/W:1",
        "/NFL", "/NDL", "/NP"
    )

    foreach ($xf in $ExcludeFiles) { $args += @("/XF", $xf) }
    foreach ($xd in $ExcludeDirs)  { $args += @("/XD", $xd) }

    if ($DryRun) {
        Write-Status "DRY RUN robocopy $($args -join ' ')" "INFO"
        return
    }

    & robocopy @args | Out-Null
    $code = $LASTEXITCODE
    if ($code -le 1) {
        Write-Status "Copied: $Source -> $Destination" "OK"
    } else {
        Write-Status "Copy completed with warnings ($code): $Source" "WARNING"
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Exness/MT5 Encrypted Backup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Output directory default
if (-not $OutputDir) {
    $preferred = @("D:\Backups", (Join-Path $env:USERPROFILE "Backups"))
    $OutputDir = Get-FirstExistingPath -Paths $preferred
    if (-not $OutputDir) {
        $OutputDir = Join-Path $env:USERPROFILE "Backups"
    }
}
Ensure-Directory -Path $OutputDir

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$workDir = Join-Path $OutputDir "Exness-MT5-Export-$timestamp"
Ensure-Directory -Path $workDir

Write-Status "Output: $OutputDir" "INFO"
Write-Status "Workdir: $workDir" "INFO"

# Locate install dir (optional)
$installDir = $null
if (Test-Path $TerminalExePath) {
    $installDir = Split-Path $TerminalExePath -Parent
    Write-Status "Found terminal: $TerminalExePath" "OK"
} else {
    Write-Status "terminal64.exe not found at $TerminalExePath (will still export data folders)" "WARNING"
}

# MetaQuotes data roots
$roamingMq = Join-Path $env:APPDATA "MetaQuotes\Terminal"
$localMq   = Join-Path $env:LOCALAPPDATA "MetaQuotes\Terminal"
$programDataMq = "C:\ProgramData\MetaQuotes\Terminal"

Write-Status "Searching MT5 terminal data folders..." "INFO"
$terminalRoots = @()
foreach ($root in @($roamingMq, $localMq, $programDataMq)) {
    if (Test-Path $root) {
        $terminalRoots += $root
    }
}
if ($terminalRoots.Count -eq 0) {
    Write-Status "No MetaQuotes Terminal roots found (APPDATA/LOCALAPPDATA/PROGRAMDATA)." "WARNING"
}

# Exclusions: avoid common session/credential artifacts
$excludeFiles = @(
    "*.log", "*.tmp", "*.dat", "*.srv", "*.lck",
    "terminal.ini", "common.ini", "servers.dat", "accounts.dat"
)
$excludeDirs = @(
    "logs", "log", "cache", "Caches", "History", "tester", "MQL5\Files"
)

# Export core folders from each detected terminal instance
$exportRoot = Join-Path $workDir "Terminal-Data"
Ensure-Directory -Path $exportRoot

foreach ($root in $terminalRoots) {
    try {
        $instances = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
        foreach ($inst in $instances) {
            $src = $inst.FullName
            $dst = Join-Path $exportRoot ("{0}-{1}" -f ($root.Split('\')[-1]), $inst.Name)

            # Copy just the highest-signal folders if present
            foreach ($sub in @("MQL5", "profiles", "templates", "config")) {
                $subSrc = Join-Path $src $sub
                if (Test-Path $subSrc) {
                    Copy-Tree -Source $subSrc -Destination (Join-Path $dst $sub) -ExcludeFiles $excludeFiles -ExcludeDirs $excludeDirs
                }
            }
        }
    } catch {
        Write-Status "Failed reading terminal root $root: $($_.Exception.Message)" "WARNING"
    }
}

# Optionally include install binaries (Program Files)
if ($IncludeProgramFiles -and $installDir) {
    Write-Status "Including Program Files install dir (large): $installDir" "WARNING"
    Copy-Tree -Source $installDir -Destination (Join-Path $workDir "ProgramFiles-MetaTrader5-EXNESS") -ExcludeFiles @("*.log","*.tmp") -ExcludeDirs @("logs","log","cache")
}

# Optionally include ProgramData (encrypted archive strongly recommended)
if ($IncludeProgramData -and (Test-Path $programDataMq)) {
    Write-Status "Including ProgramData MetaQuotes (may contain sensitive info): $programDataMq" "WARNING"
    Copy-Tree -Source $programDataMq -Destination (Join-Path $workDir "ProgramData-MetaQuotes-Terminal") -ExcludeFiles $excludeFiles -ExcludeDirs $excludeDirs
}

# Create encrypted archive
$archivePath = Join-Path $OutputDir ("Exness-MT5-Encrypted-{0}.7z" -f $timestamp)
$password = [Environment]::GetEnvironmentVariable($PasswordEnvVar)
if (-not $password) {
    Write-Status "Password env var '$PasswordEnvVar' not set." "WARNING"
    Write-Status "Set it (recommended) or you'll be prompted." "INFO"
    if (-not $DryRun) {
        $secure = Read-Host "Enter archive password" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    } else {
        $password = "DRYRUN"
    }
}

$sevenZip = Get-FirstExistingPath -Paths @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe"
)

if (-not $sevenZip) {
    Write-Status "7-Zip not found. Install 7-Zip (7z.exe) to create AES-256 encrypted archive." "ERROR"
    Write-Status "Expected: C:\Program Files\7-Zip\7z.exe" "INFO"
    exit 1
}

Write-Status "Creating encrypted archive: $archivePath" "INFO"

$sevenArgs = @(
    "a",
    "-t7z",
    "-mhe=on",
    "-mx=7",
    ("-p{0}" -f $password),
    $archivePath,
    $workDir
)

if ($DryRun) {
    Write-Status "DRY RUN: `"$sevenZip`" $($sevenArgs -join ' ')" "INFO"
} else {
    & $sevenZip @sevenArgs | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Encrypted archive created successfully." "OK"
    } else {
        Write-Status "7-Zip failed with exit code $LASTEXITCODE" "ERROR"
        exit $LASTEXITCODE
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Workdir: $workDir" -ForegroundColor White
Write-Host "Archive: $archivePath" -ForegroundColor White
Write-Host ""


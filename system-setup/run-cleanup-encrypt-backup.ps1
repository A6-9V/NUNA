#Requires -Version 5.1
<#
.SYNOPSIS
    One-run VPS chore: cleanup drives + encrypted Exness/MT5 backup.
.DESCRIPTION
    Runs the safer cleanup script, then creates an AES-256 encrypted backup archive for Exness/MT5.
    Intended for Windows VPS operation.

    NOTE:
    - This does NOT push/commit anything automatically (to avoid leaking secrets or committing huge archives).
    - Use existing git scripts after verifying `git status` is clean and backups are NOT staged.

.PARAMETER Full
    Includes Program Files install directory and ProgramData (large). Use only when archiving encrypted.
.PARAMETER OutputDir
    Backup output directory (e.g., D:\Backups).
.PARAMETER ExcludeDrives
    Drives to skip during cleanup (default: C).
.PARAMETER DryRun
    Runs cleanup in dry-run and shows what backup would do.
#>

param(
    [switch]$Full,
    [string]$OutputDir,
    [string[]]$ExcludeDrives = @("C"),
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VPS Cleanup + Encrypted Backup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cleanupScript = Join-Path $scriptDir "cleanup-all-drives.ps1"
$backupScript  = Join-Path $scriptDir "backup-exness-mt5-encrypted.ps1"
$securityTrading = Join-Path (Split-Path -Parent $scriptDir) "security-check-trading.ps1"
$securityGeneral = Join-Path (Split-Path -Parent $scriptDir) "security-check.ps1"

if (-not (Test-Path $cleanupScript)) { Write-Status "Missing: $cleanupScript" "ERROR"; exit 1 }
if (-not (Test-Path $backupScript))  { Write-Status "Missing: $backupScript" "ERROR"; exit 1 }

Write-Status "Step 1/3: Drive cleanup (safe mode)..." "INFO"
try {
    & $cleanupScript -DryRun:$DryRun -ExcludeDrives $ExcludeDrives | Out-Null
    Write-Status "Drive cleanup complete." "OK"
} catch {
    Write-Status "Drive cleanup had issues: $($_.Exception.Message)" "WARNING"
}

Write-Host ""
Write-Status "Step 2/3: Encrypted Exness/MT5 backup..." "INFO"
try {
    $includePF = $false
    $includePD = $false
    if ($Full) {
        $includePF = $true
        $includePD = $true
        Write-Status "Full mode enabled: including Program Files + ProgramData (large)." "WARNING"
    }

    & $backupScript -OutputDir $OutputDir -IncludeProgramFiles:$includePF -IncludeProgramData:$includePD -DryRun:$DryRun
    Write-Status "Encrypted backup complete." "OK"
} catch {
    Write-Status "Backup had issues: $($_.Exception.Message)" "WARNING"
}

Write-Host ""
Write-Status "Step 3/3: Security checks (best-effort)..." "INFO"
try {
    if (Test-Path $securityGeneral) {
        & $securityGeneral | Out-Null
        Write-Status "General security check finished." "OK"
    } else {
        Write-Status "Missing: $securityGeneral (skipping)" "WARNING"
    }
} catch {
    Write-Status "General security check had issues." "WARNING"
}

try {
    if (Test-Path $securityTrading) {
        & $securityTrading | Out-Null
        Write-Status "Trading security check finished." "OK"
    } else {
        Write-Status "Missing: $securityTrading (skipping)" "WARNING"
    }
} catch {
    Write-Status "Trading security check had issues." "WARNING"
}

Write-Host ""
Write-Status "All steps complete." "OK"
Write-Status "Reminder: Do NOT commit backups or ProgramData to git. Keep only scripts/config templates in GitHub." "WARNING"


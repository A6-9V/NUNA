#Requires -Version 5.1
<#
.SYNOPSIS
    Safe Google Drive cleanup helper via rclone (dry-run by default).
.DESCRIPTION
    This script is designed for Google Drive cleanup when you have Drive mounted/configured via rclone.
    It does NOT require Google API code here; it delegates to rclone.

    Defaults to "audit" mode (no deletions). To actually delete, pass -Apply.

    REQUIREMENTS:
    - rclone installed and available in PATH on the Windows VPS
    - an rclone remote configured (default remote name: gdrive)

.PARAMETER Remote
    rclone remote name, e.g. "gdrive:" (default) or "mydrive:".
.PARAMETER Path
    Subfolder inside the remote to target, e.g. "My Drive/Projects" (default: root).
.PARAMETER DaysOld
    Used for candidate selection of old files (default: 30).
.PARAMETER Apply
    If set, will delete candidates (uses rclone deletefile / purge patterns).
#>

param(
    [string]$Remote = "gdrive:",
    [string]$Path = "",
    [int]$DaysOld = 30,
    [switch]$Apply
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
Write-Host "  Google Drive Cleanup (rclone)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Status "rclone not found in PATH. Install rclone and configure your Google Drive remote first." "ERROR"
    exit 1
}

$target = if ($Path) { "$Remote$Path" } else { $Remote }
Write-Status "Target: $target" "INFO"
Write-Status "Mode: $((if ($Apply) { 'APPLY (deleting)' } else { 'AUDIT (no deletions)' }))" "WARNING"
Write-Status "DaysOld: $DaysOld" "INFO"
Write-Host ""

# 1) Show top largest files (audit)
Write-Status "Listing large files (top 50)..." "INFO"
try {
    # rclone size --json is heavy; use lsf + du is not available. We use a pragmatic approach:
    # rclone lsjson provides sizes; we sort in PowerShell.
    $json = rclone lsjson $target --recursive --files-only 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) {
        Write-Status "Failed to list files via lsjson (check remote permissions/path)." "WARNING"
    } else {
        $items = $json | ConvertFrom-Json
        $largest = $items | Sort-Object -Property Size -Descending | Select-Object -First 50
        $largest | ForEach-Object {
            "{0,10:N0}  {1}" -f $_.Size, $_.Path
        } | Write-Host
    }
} catch {
    Write-Status "Large-file listing failed: $($_.Exception.Message)" "WARNING"
}

Write-Host ""

# 2) Find old trashed candidates: rclone can't see Drive Trash via normal listing.
# Instead, we select "old" files under the target path (review list), then optionally delete.
Write-Status "Selecting candidates older than $DaysOld days (review list)..." "INFO"
$cutoff = (Get-Date).AddDays(-$DaysOld)

$candidates = @()
try {
    $json2 = rclone lsjson $target --recursive --files-only 2>$null
    if ($LASTEXITCODE -eq 0 -and $json2) {
        $items2 = $json2 | ConvertFrom-Json
        $candidates = $items2 | Where-Object { $_.ModTime -and ([DateTime]$_.ModTime) -lt $cutoff }
    }
} catch {
    Write-Status "Candidate scan failed: $($_.Exception.Message)" "WARNING"
}

Write-Status ("Candidates found: {0}" -f ($candidates.Count)) "INFO"
if ($candidates.Count -gt 0) {
    $preview = $candidates | Sort-Object -Property ModTime | Select-Object -First 50
    Write-Host ""
    Write-Host "Oldest 50 candidates (preview):" -ForegroundColor Yellow
    $preview | ForEach-Object {
        "{0}  {1,10:N0}  {2}" -f ([DateTime]$_.ModTime).ToString("yyyy-MM-dd"), $_.Size, $_.Path
    } | Write-Host
}

if (-not $Apply) {
    Write-Host ""
    Write-Status "AUDIT mode complete. Re-run with -Apply to delete the candidates (dangerous)." "WARNING"
    exit 0
}

# 3) Apply deletions (dangerous) - delete files one by one to avoid accidental purge
Write-Host ""
Write-Status "APPLY mode: deleting candidates one-by-one..." "WARNING"

$deleted = 0
foreach ($c in $candidates) {
    try {
        $file = $c.Path
        if (-not $file) { continue }
        rclone deletefile "$target/$file" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $deleted++ }
    } catch {
        # continue
    }
}

Write-Host ""
Write-Status "Deleted: $deleted file(s)" "OK"
Write-Status "NOTE: For Drive Trash cleanup, use Google Drive UI or an rclone config that supports trash operations." "INFO"


#Requires -Version 5.1
<#
.SYNOPSIS
    Finds and quarantines likely sensitive ID/passport/credit-card images from cloud-synced folders.
.DESCRIPTION
    This script helps you "clean up" pictures of sensitive documents (ID cards, passports, credit/debit cards)
    that may be sitting inside Dropbox / Google Drive sync folders.

    IMPORTANT:
    - This is a filename/path heuristic scanner (fast, safe) — it does NOT read image contents or OCR.
    - Expect false positives/negatives. Always review the report before applying changes.
    - Default mode is AUDIT (no file moves). Use -Apply to move files to a quarantine folder.

    What it does:
    - Auto-detects common Dropbox and Google Drive sync root folders
    - Scans for common image/PDF file extensions
    - Scores each candidate based on keywords in the path/filename (e.g., "passport", "id", "credit card")
    - Writes a timestamped CSV report
    - If -Apply is provided: moves flagged files into a local quarantine folder (outside cloud sync)

.PARAMETER Targets
    Optional explicit folder path(s) to scan instead of auto-detection.

.PARAMETER Apply
    If set, moves flagged files into the quarantine folder. Without -Apply, runs in audit mode.

.PARAMETER MinScore
    Minimum score threshold for flagging a file (default: 3). Increase to reduce false positives.

.PARAMETER QuarantineRoot
    Root folder where quarantined files will be moved (default: %USERPROFILE%\Documents\Quarantine-Sensitive-CloudFiles).

.PARAMETER ReportRoot
    Folder where the CSV report will be saved (default: %USERPROFILE%\Documents\Sensitive-Cloud-Cleanup-Reports).

.PARAMETER IncludeDropbox
    Include auto-detected Dropbox sync roots (default: enabled).

.PARAMETER IncludeGoogleDrive
    Include auto-detected Google Drive sync roots (default: enabled).

.PARAMETER Pause
    If set, waits for a key press before exiting (useful when run by double-click).
.EXAMPLE
    # Audit only (recommended first)
    .\cleanup-sensitive-doc-images.ps1

.EXAMPLE
    # Apply moves to quarantine (after reviewing the report)
    .\cleanup-sensitive-doc-images.ps1 -Apply

.EXAMPLE
    # Scan explicit folders only
    .\cleanup-sensitive-doc-images.ps1 -Targets @("C:\Users\You\Dropbox","D:\Sync\Google Drive") -Apply
#>

[CmdletBinding()]
param(
    [string[]]$Targets,
    [switch]$Apply,
    [int]$MinScore = 3,
    [string]$QuarantineRoot = (Join-Path $env:USERPROFILE "Documents\Quarantine-Sensitive-CloudFiles"),
    [string]$ReportRoot = (Join-Path $env:USERPROFILE "Documents\Sensitive-Cloud-Cleanup-Reports"),
    [switch]$IncludeDropbox,
    [switch]$IncludeGoogleDrive,
    [switch]$Pause
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

function Get-DropboxSyncRoots {
    $roots = New-Object System.Collections.Generic.List[string]

    # Common default
    $default = Join-Path $env:USERPROFILE "Dropbox"
    if (Test-Path $default) { $roots.Add($default) }

    # Preferred: parse Dropbox info.json for actual location(s)
    $infoCandidates = @(
        (Join-Path $env:APPDATA "Dropbox\info.json"),
        (Join-Path $env:LOCALAPPDATA "Dropbox\info.json")
    )

    foreach ($infoPath in $infoCandidates) {
        if (-not (Test-Path $infoPath)) { continue }
        try {
            $raw = Get-Content -LiteralPath $infoPath -Raw -ErrorAction Stop
            $json = $raw | ConvertFrom-Json
            foreach ($k in @("personal","business")) {
                try {
                    $p = $json.$k.path
                    if ($p -and (Test-Path $p)) { $roots.Add($p) }
                } catch {
                    # ignore
                }
            }
        } catch {
            Write-Status "Could not parse Dropbox info.json at $infoPath" "WARNING"
        }
    }

    # De-duplicate
    $roots | Select-Object -Unique
}

function Get-GoogleDriveSyncRoots {
    $roots = New-Object System.Collections.Generic.List[string]

    # Common guesses (Google Drive for desktop "mirrored" folder)
    $common = @(
        (Join-Path $env:USERPROFILE "Google Drive"),
        (Join-Path $env:USERPROFILE "Google Drive (1)"),
        (Join-Path $env:USERPROFILE "Google Drive (2)")
    )
    foreach ($p in $common) {
        if (Test-Path $p) { $roots.Add($p) }
    }

    # If user has a folder named like "Google Drive*" under profile, include it if it looks like a sync root.
    try {
        $profileDirs = Get-ChildItem -LiteralPath $env:USERPROFILE -Directory -ErrorAction SilentlyContinue
        foreach ($d in $profileDirs) {
            if ($d.Name -notlike "Google Drive*") { continue }
            $candidate = $d.FullName
            $looksLikeRoot = (Test-Path (Join-Path $candidate "My Drive")) -or (Test-Path (Join-Path $candidate "Shared drives"))
            if ($looksLikeRoot) { $roots.Add($candidate) }
        }
    } catch {
        # ignore
    }

    $roots | Select-Object -Unique
}

function Get-SafeLeafName {
    param([Parameter(Mandatory=$true)][string]$Path)
    $leaf = Split-Path -Path $Path -Leaf
    if (-not $leaf) { $leaf = "root" }
    return ($leaf -replace '[<>:"/\\|?*]', '_')
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$FullName
    )

    $rootResolved = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path.TrimEnd('\')
    $fullResolved = $FullName
    if ($fullResolved.StartsWith($rootResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullResolved.Substring($rootResolved.Length).TrimStart('\')
    }
    return (Split-Path -Path $FullName -Leaf)
}

function Score-SensitivePath {
    param([Parameter(Mandatory=$true)][string]$FullPath)

    $p = $FullPath.ToLowerInvariant()
    $score = 0

    # High-signal keywords
    $high = @(
        "passport","nationalid","national-id","idcard","id-card","identity","identification",
        "driverlicense","driver-license","drivinglicense","driving-license","license","licence",
        "aadhar","aadhaar","pan","taxid","tin","ssn","socialsecurity","social-security",
        "creditcard","credit-card","debitcard","debit-card","cardnumber","card-number",
        "cvv","cvc","iban","swift","bankstatement","bank-statement","routing","accountnumber","account-number",
        "kyc","aml"
    )

    # Medium signal keywords
    $medium = @("id","card","visa","mastercard","amex","front","back","scan","scanned","document","documents","proof","verification")

    foreach ($w in $high) {
        if ($p -like "*$w*") { $score += 3 }
    }
    foreach ($w in $medium) {
        if ($p -like "*$w*") { $score += 1 }
    }

    # Folder context bumps (common doc vault folders inside sync roots)
    $folderBumps = @("\kyc\", "\documents\", "\ids\", "\identity\", "\passport\", "\bank\", "\cards\")
    foreach ($b in $folderBumps) {
        if ($p -like "*$b*") { $score += 1 }
    }

    # Numeric patterns (often appear in card/id filenames)
    if ($p -match '(?<!\d)\d{12,16}(?!\d)') { $score += 2 }

    return $score
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Get-UniqueDestinationPath {
    param(
        [Parameter(Mandatory=$true)][string]$DestinationFilePath
    )
    if (-not (Test-Path $DestinationFilePath)) { return $DestinationFilePath }

    $dir = Split-Path -Path $DestinationFilePath -Parent
    $base = [System.IO.Path]::GetFileNameWithoutExtension($DestinationFilePath)
    $ext = [System.IO.Path]::GetExtension($DestinationFilePath)

    for ($i = 1; $i -le 999; $i++) {
        $candidate = Join-Path $dir ("{0}__DUP{1}{2}" -f $base, $i, $ext)
        if (-not (Test-Path $candidate)) { return $candidate }
    }
    return (Join-Path $dir ("{0}__DUP{1}{2}" -f $base, ([Guid]::NewGuid().ToString("N").Substring(0,8)), $ext))
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sensitive Document Image Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $IncludeDropbox.IsPresent -and -not $IncludeGoogleDrive.IsPresent) {
    # Default behavior: include both
    $IncludeDropbox = $true
    $IncludeGoogleDrive = $true
}

$extensions = @(".jpg",".jpeg",".png",".webp",".gif",".bmp",".tif",".tiff",".heic",".pdf")
$excludePathFragments = @(
    "\.dropbox.cache\",
    "\appdata\local\google\drivefs\",
    "\.git\",
    "\node_modules\"
)

$scanRoots = @()
if ($Targets -and $Targets.Count -gt 0) {
    $scanRoots = $Targets
} else {
    if ($IncludeDropbox) { $scanRoots += (Get-DropboxSyncRoots) }
    if ($IncludeGoogleDrive) { $scanRoots += (Get-GoogleDriveSyncRoots) }
}

$scanRoots = $scanRoots | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

if ($scanRoots.Count -eq 0) {
    Write-Status "No scan roots found. Provide -Targets with your Dropbox/Google Drive folder path(s)." "ERROR"
    if ($Pause) { Write-Host ""; Write-Host "Press any key to exit..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
    exit 1
}

$mode = if ($Apply) { "APPLY (moving to quarantine)" } else { "AUDIT (no changes)" }
Write-Status "Mode: $mode" "WARNING"
Write-Status ("MinScore: {0}" -f $MinScore) "INFO"
Write-Status ("Roots: {0}" -f ($scanRoots -join " | ")) "INFO"
Write-Host ""

Ensure-Directory -Path $ReportRoot

$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = Join-Path $ReportRoot ("sensitive-cloud-cleanup_{0}.csv" -f $timestamp)

$quarantineSessionRoot = Join-Path $QuarantineRoot $timestamp
if ($Apply) {
    Ensure-Directory -Path $quarantineSessionRoot
}

$results = New-Object System.Collections.Generic.List[object]
$scanned = 0
$flagged = 0
$moved = 0
$moveErrors = 0

foreach ($root in $scanRoots) {
    Write-Status "Scanning: $root" "INFO"

    $serviceName = if ($root -like "*Dropbox*") { "Dropbox" } elseif ($root -like "*Google Drive*") { "GoogleDrive" } else { "Custom" }
    $rootTag = Get-SafeLeafName -Path $root
    $destBase = Join-Path $quarantineSessionRoot ("{0}-{1}" -f $serviceName, $rootTag)

    try {
        $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Status "Failed to enumerate files under: $root ($($_.Exception.Message))" "WARNING"
        continue
    }

    foreach ($f in $files) {
        $scanned++

        $ext = ($f.Extension | ForEach-Object { $_.ToLowerInvariant() })
        if (-not ($extensions -contains $ext)) { continue }

        $full = $f.FullName
        $lower = $full.ToLowerInvariant()
        $skip = $false
        foreach ($frag in $excludePathFragments) {
            if ($lower -like "*$frag*") { $skip = $true; break }
        }
        if ($skip) { continue }

        $score = Score-SensitivePath -FullPath $full
        if ($score -lt $MinScore) { continue }

        $flagged++

        $action = if ($Apply) { "MOVE" } else { "AUDIT" }
        $dest = ""
        $status = "Flagged"
        $error = ""

        if ($Apply) {
            try {
                Ensure-Directory -Path $destBase
                $relative = Get-RelativePath -Root $root -FullName $full
                $dest = Join-Path $destBase $relative
                Ensure-Directory -Path (Split-Path -Path $dest -Parent)
                $dest2 = Get-UniqueDestinationPath -DestinationFilePath $dest
                Move-Item -LiteralPath $full -Destination $dest2 -Force -ErrorAction Stop
                $dest = $dest2
                $status = "Moved"
                $moved++
            } catch {
                $status = "MoveFailed"
                $error = $_.Exception.Message
                $moveErrors++
            }
        }

        $results.Add([pscustomobject]@{
            Timestamp = (Get-Date).ToString("s")
            Mode      = $mode
            Root      = $root
            File      = $full
            Extension = $ext
            SizeBytes = $f.Length
            Score     = $score
            Action    = $action
            Status    = $status
            Destination = $dest
            Error     = $error
        })
    }
}

try {
    $results | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host ""
    Write-Status "Report saved: $reportPath" "OK"
} catch {
    Write-Status "Failed to write report CSV: $($_.Exception.Message)" "WARNING"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Status ("Files scanned (all types): {0}" -f $scanned) "INFO"
Write-Status ("Files flagged (score >= {0}): {1}" -f $MinScore, $flagged) "INFO"

if ($Apply) {
    Write-Status ("Moved to quarantine: {0}" -f $moved) "OK"
    if ($moveErrors -gt 0) {
        Write-Status ("Move errors: {0} (see report)" -f $moveErrors) "WARNING"
    }
    Write-Status ("Quarantine folder: {0}" -f $quarantineSessionRoot) "INFO"
} else {
    Write-Status "AUDIT complete. Review the report, then re-run with -Apply to move flagged files." "WARNING"
}

Write-Host ""

if ($Pause) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


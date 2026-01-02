#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy MQL5 code to MT5 VPS and compile it properly.
.DESCRIPTION
    - Locates your MQL5 source repo (default: OneDrive\mql5-repo)
    - Locates the active MetaTrader 5 data folder (Terminal\<hash>\MQL5)
    - Copies MQL5 folders (Experts/Include/Indicators/Scripts/...) into the MT5 data folder
    - Compiles all .mq5 files using MetaEditor CLI and reports failures

    This script is intended to be run ON the Windows VPS where MT5 is installed.
.PARAMETER WorkspaceRoot
    Root folder for this automation workspace (defaults to OneDrive if available).
.PARAMETER SourceRepoPath
    Path to your MQL5 repository (defaults to <WorkspaceRoot>\mql5-repo).
.PARAMETER TerminalDataPath
    Override the detected MT5 Terminal data directory (the folder containing MQL5\).
.PARAMETER MetaEditorPath
    Override the detected metaeditor64.exe path.
.PARAMETER SkipGitPull
    Skip `git pull` for the SourceRepoPath.
.PARAMETER SkipCopy
    Skip copying code into the MT5 data folder.
.PARAMETER SkipCompile
    Skip compilation.
.PARAMETER MirrorCopy
    Use Robocopy /MIR (mirror) instead of a non-destructive /E copy.
#>

[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$SourceRepoPath,
    [string]$TerminalDataPath,
    [string]$MetaEditorPath,
    [switch]$SkipGitPull,
    [switch]$SkipCopy,
    [switch]$SkipCompile,
    [switch]$MirrorCopy
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MQL5 VPS Deploy + Compile" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Resolve-WorkspaceRoot {
    param([string]$Override)

    if ($Override -and (Test-Path $Override)) { return $Override }

    $candidates = @()
    if ($env:OneDrive) { $candidates += $env:OneDrive }
    if ($env:USERPROFILE) { $candidates += (Join-Path $env:USERPROFILE "OneDrive") }
    $candidates += $PSScriptRoot

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }

    return $PSScriptRoot
}

function Resolve-MetaEditorPath {
    param([string]$Override)

    if ($Override -and (Test-Path $Override)) { return $Override }

    $programFilesX86 = $null
    try { $programFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value } catch { }

    $candidates = @(
        "C:\Program Files\MetaTrader 5 EXNESS\metaeditor64.exe",
        "$env:LOCALAPPDATA\Programs\MetaTrader 5 EXNESS\metaeditor64.exe",
        "$env:PROGRAMFILES\MetaTrader 5 EXNESS\metaeditor64.exe",
        "C:\Program Files\MetaTrader 5\metaeditor64.exe",
        "$env:LOCALAPPDATA\Programs\MetaTrader 5\metaeditor64.exe"
    )
    if ($programFilesX86) {
        $candidates += (Join-Path $programFilesX86 "MetaTrader 5 EXNESS\metaeditor64.exe")
        $candidates += (Join-Path $programFilesX86 "MetaTrader 5\metaeditor64.exe")
    }

    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }

    return $null
}

function Resolve-TerminalDataPath {
    param([string]$Override)

    if ($Override -and (Test-Path $Override) -and (Test-Path (Join-Path $Override "MQL5"))) {
        return $Override
    }

    if (-not $env:APPDATA) { return $null }

    $terminalRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal"
    if (-not (Test-Path $terminalRoot)) { return $null }

    $candidates = @()
    try {
        $dirs = Get-ChildItem -Path $terminalRoot -Directory -ErrorAction SilentlyContinue
        foreach ($d in $dirs) {
            $mql5Path = Join-Path $d.FullName "MQL5"
            if (Test-Path $mql5Path) {
                $originTxt = Join-Path $d.FullName "origin.txt"
                $origin = $null
                if (Test-Path $originTxt) {
                    $origin = (Get-Content $originTxt -ErrorAction SilentlyContinue | Select-Object -First 1)
                }
                $candidates += [PSCustomObject]@{
                    Path = $d.FullName
                    Origin = $origin
                    LastWrite = $d.LastWriteTime
                }
            }
        }
    } catch { }

    if (-not $candidates -or $candidates.Count -eq 0) { return $null }

    if ($candidates.Count -eq 1) { return $candidates[0].Path }

    $exness = $candidates | Where-Object { $_.Origin -match "EXNESS|Exness|MetaTrader 5 EXNESS" }
    if ($exness -and $exness.Count -ge 1) {
        return ($exness | Sort-Object LastWrite -Descending | Select-Object -First 1).Path
    }

    return ($candidates | Sort-Object LastWrite -Descending | Select-Object -First 1).Path
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Robocopy-Folder {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Mirror
    )

    Ensure-Directory -Path $Destination

    $mode = if ($Mirror) { "/MIR" } else { "/E" }
    $args = @(
        "`"$Source`"",
        "`"$Destination`"",
        $mode,
        "/R:3",
        "/W:5",
        "/NP",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/XD", ".git", ".github",
        "/XF", "*.ex5"
    )

    $p = Start-Process -FilePath "robocopy.exe" -ArgumentList $args -Wait -PassThru -NoNewWindow
    # Robocopy exit codes 0-7 are success-ish; 8+ are failures
    return ($p.ExitCode -lt 8)
}

function Compile-MQL5 {
    param(
        [string]$MetaEditor,
        [string]$TerminalMql5Path
    )

    $targets = @()
    $compileRoots = @(
        (Join-Path $TerminalMql5Path "Experts"),
        (Join-Path $TerminalMql5Path "Indicators"),
        (Join-Path $TerminalMql5Path "Scripts")
    )

    foreach ($root in $compileRoots) {
        if (Test-Path $root) {
            $targets += Get-ChildItem -Path $root -Filter "*.mq5" -Recurse -ErrorAction SilentlyContinue
        }
    }

    $targets = $targets | Sort-Object FullName -Unique

    if (-not $targets -or $targets.Count -eq 0) {
        Write-Host "[WARNING] No .mq5 files found under: $TerminalMql5Path" -ForegroundColor Yellow
        return @{ Total = 0; Success = 0; Failed = 0 }
    }

    Write-Host "[INFO] Compiling $($targets.Count) .mq5 file(s) via MetaEditor..." -ForegroundColor Cyan
    $success = 0
    $failed = 0

    foreach ($t in $targets) {
        $startTime = Get-Date
        $ex5 = ($t.FullName -replace "\.mq5$", ".ex5")

        Write-Host "  Compiling: $($t.FullName)" -ForegroundColor White
        try {
            $argumentList = @(
                "/compile:`"$($t.FullName)`"",
                "/log"
            )
            $proc = Start-Process -FilePath $MetaEditor -ArgumentList $argumentList -Wait -PassThru -NoNewWindow

            if ((Test-Path $ex5) -and ((Get-Item $ex5).LastWriteTime -ge $startTime)) {
                Write-Host "    [OK] $($t.Name)" -ForegroundColor Green
                $success++
            } else {
                Write-Host "    [ERROR] Compile failed (no fresh .ex5): $($t.Name)" -ForegroundColor Red
                $failed++
            }
        } catch {
            Write-Host "    [ERROR] Compile crashed for $($t.Name): $_" -ForegroundColor Red
            $failed++
        }
    }

    return @{ Total = $targets.Count; Success = $success; Failed = $failed }
}

$workspaceRootResolved = Resolve-WorkspaceRoot -Override $WorkspaceRoot
$logsPath = Join-Path $workspaceRootResolved "vps-logs"
Ensure-Directory -Path $logsPath

Write-Host "[INFO] WorkspaceRoot: $workspaceRootResolved" -ForegroundColor Cyan

if (-not $SourceRepoPath) {
    $SourceRepoPath = Join-Path $workspaceRootResolved "mql5-repo"
}

if (-not (Test-Path $SourceRepoPath)) {
    Write-Host "[ERROR] MQL5 source repo not found: $SourceRepoPath" -ForegroundColor Red
    Write-Host "[INFO] Ensure `vps-services/mql5-service.ps1` has cloned it, or pass -SourceRepoPath." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Source repo: $SourceRepoPath" -ForegroundColor Green

if (-not $SkipGitPull) {
    try {
        if (Test-Path (Join-Path $SourceRepoPath ".git")) {
            Write-Host "[INFO] Pulling latest MQL5 changes..." -ForegroundColor Cyan
            Push-Location $SourceRepoPath
            $pullOut = git pull origin main 2>&1
            Pop-Location
            $pullOut | Out-File -Append (Join-Path $logsPath "mql5-git-pull.log")
            Write-Host "[OK] Git pull completed (see vps-logs\mql5-git-pull.log)" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] SourceRepoPath is not a git repo, skipping pull." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARNING] Git pull failed (continuing): $_" -ForegroundColor Yellow
    }
}

$terminalDataResolved = Resolve-TerminalDataPath -Override $TerminalDataPath
if (-not $terminalDataResolved) {
    Write-Host "[ERROR] Could not locate MT5 Terminal data folder (MetaQuotes\\Terminal\\<hash>)." -ForegroundColor Red
    Write-Host "[INFO] Pass -TerminalDataPath pointing to the folder that contains MQL5\." -ForegroundColor Yellow
    exit 1
}

$terminalMql5Path = Join-Path $terminalDataResolved "MQL5"
Write-Host "[OK] MT5 data folder: $terminalDataResolved" -ForegroundColor Green

$metaEditorResolved = Resolve-MetaEditorPath -Override $MetaEditorPath
if (-not $metaEditorResolved) {
    Write-Host "[ERROR] MetaEditor not found (metaeditor64.exe)." -ForegroundColor Red
    Write-Host "[INFO] Install MetaTrader 5 / Exness MT5, or pass -MetaEditorPath." -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] MetaEditor: $metaEditorResolved" -ForegroundColor Green

if (-not $SkipCopy) {
    Write-Host ""
    Write-Host "[1/2] Deploying code into MT5 data folder..." -ForegroundColor Yellow

    $sourceMql5Root = $SourceRepoPath
    $repoMql5 = Join-Path $SourceRepoPath "MQL5"
    if (Test-Path $repoMql5) { $sourceMql5Root = $repoMql5 }

    $foldersToCopy = @("Experts", "Include", "Indicators", "Scripts", "Libraries", "Services", "Images", "Files")
    $copiedAny = $false
    foreach ($f in $foldersToCopy) {
        $src = Join-Path $sourceMql5Root $f
        $dst = Join-Path $terminalMql5Path $f
        if (Test-Path $src) {
            Write-Host "  Copying $f ..." -ForegroundColor Cyan
            $ok = Robocopy-Folder -Source $src -Destination $dst -Mirror:$MirrorCopy
            if ($ok) {
                Write-Host "    [OK] $f" -ForegroundColor Green
                $copiedAny = $true
            } else {
                Write-Host "    [ERROR] Copy failed: $f" -ForegroundColor Red
            }
        }
    }

    if (-not $copiedAny) {
        Write-Host "[WARNING] No MQL5 folders found to copy in: $sourceMql5Root" -ForegroundColor Yellow
        Write-Host "[INFO] Expected folders like MQL5\\Experts, MQL5\\Include, ..." -ForegroundColor Cyan
    }
}

if (-not $SkipCompile) {
    Write-Host ""
    Write-Host "[2/2] Compiling in MT5 data folder..." -ForegroundColor Yellow
    $result = Compile-MQL5 -MetaEditor $metaEditorResolved -TerminalMql5Path $terminalMql5Path

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Compile Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Total:   $($result.Total)" -ForegroundColor White
    Write-Host "  Success: $($result.Success)" -ForegroundColor Green
    Write-Host "  Failed:  $($result.Failed)" -ForegroundColor $(if ($result.Failed -eq 0) { "Green" } else { "Red" })
    Write-Host ""

    if ($result.Failed -gt 0) { exit 1 }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Done" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan


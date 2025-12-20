#Requires -Version 5.1
<#
.SYNOPSIS
    Compile MQL5 Expert Advisors using MetaEditor
.DESCRIPTION
    Compiles all Expert Advisors in the Advisors directory using MetaEditor command-line compiler
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MQL5 Expert Advisor Compiler" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$mt5TerminalPath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
$mt5MetaEditorPath = "C:\Program Files\MetaTrader 5 EXNESS\metaeditor64.exe"

function Resolve-TerminalDataPath {
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

$terminalDataPath = Resolve-TerminalDataPath
if (-not $terminalDataPath) {
    Write-Host "[ERROR] Could not locate MT5 Terminal data folder (MetaQuotes\Terminal\<hash>)." -ForegroundColor Red
    Write-Host "[INFO] Run MT5 once, then retry this script." -ForegroundColor Yellow
    exit 1
}

$expertsPath = Join-Path $terminalDataPath "MQL5\Experts\Advisors"

# Check if MetaEditor exists
$metaEditorFound = $false
$programFilesX86 = $null
try { $programFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value } catch { }

$metaEditorPaths = @(
    "C:\Program Files\MetaTrader 5 EXNESS\metaeditor64.exe",
    "$env:LOCALAPPDATA\Programs\MetaTrader 5 EXNESS\metaeditor64.exe",
    "$env:PROGRAMFILES\MetaTrader 5 EXNESS\metaeditor64.exe",
    $(if ($programFilesX86) { Join-Path $programFilesX86 "MetaTrader 5 EXNESS\metaeditor64.exe" })
)

foreach ($path in $metaEditorPaths) {
    if (Test-Path $path) {
        $mt5MetaEditorPath = $path
        $metaEditorFound = $true
        Write-Host "[OK] Found MetaEditor at: $path" -ForegroundColor Green
        break
    }
}

if (-not $metaEditorFound) {
    Write-Host "[ERROR] MetaEditor not found. Please install MetaTrader 5." -ForegroundColor Red
    Write-Host "[INFO] Attempting to use terminal64.exe for compilation..." -ForegroundColor Yellow
    
    # Try using terminal64.exe with /compile parameter
    if (Test-Path $mt5TerminalPath) {
        Write-Host "[INFO] Using terminal64.exe for compilation" -ForegroundColor Yellow
        $mt5MetaEditorPath = $mt5TerminalPath
    } else {
        Write-Host "[ERROR] MetaTrader 5 terminal not found." -ForegroundColor Red
        exit 1
    }
}

# Get all .mq5 files in Advisors directory
Write-Host "[1/3] Scanning for Expert Advisors..." -ForegroundColor Yellow
$eaFiles = Get-ChildItem -Path $expertsPath -Filter "*.mq5" -ErrorAction SilentlyContinue

if ($null -eq $eaFiles -or $eaFiles.Count -eq 0) {
    Write-Host "[WARNING] No .mq5 files found in $expertsPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "    Found $($eaFiles.Count) Expert Advisor(s):" -ForegroundColor Cyan
foreach ($ea in $eaFiles) {
    Write-Host "      - $($ea.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "[2/3] Compiling Expert Advisors..." -ForegroundColor Yellow

$compiledCount = 0
$failedCount = 0
$compilationResults = @()

foreach ($eaFile in $eaFiles) {
    $eaName = $eaFile.Name
    $eaFullPath = $eaFile.FullName
    
    Write-Host "    Compiling: $eaName..." -ForegroundColor Cyan
    
    try {
        # MetaEditor command-line compilation
        # Format: metaeditor64.exe /compile:"path\to\file.mq5" /log
        $compileArgs = @(
            "/compile:`"$eaFullPath`"",
            "/log"
        )
        
        $process = Start-Process -FilePath $mt5MetaEditorPath -ArgumentList $compileArgs -Wait -PassThru -NoNewWindow
        
        # Check if .ex5 file was created (compiled successfully)
        $ex5Path = $eaFullPath -replace "\.mq5$", ".ex5"
        
        if (Test-Path $ex5Path) {
            Write-Host "      [OK] Compiled successfully: $eaName" -ForegroundColor Green
            $compiledCount++
            $compilationResults += @{
                File = $eaName
                Status = "Success"
                Ex5Path = $ex5Path
            }
        } else {
            Write-Host "      [WARNING] Compilation may have failed: $eaName" -ForegroundColor Yellow
            Write-Host "      [INFO] Check MetaEditor logs for details" -ForegroundColor Cyan
            $failedCount++
            $compilationResults += @{
                File = $eaName
                Status = "Failed"
                Ex5Path = $null
            }
        }
    } catch {
        Write-Host "      [ERROR] Failed to compile $eaName : $_" -ForegroundColor Red
        $failedCount++
        $compilationResults += @{
            File = $eaName
            Status = "Error"
            Ex5Path = $null
            Error = $_.Exception.Message
        }
    }
}

Write-Host ""
Write-Host "[3/3] Compilation Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total EAs: $($eaFiles.Count)" -ForegroundColor White
Write-Host "  Compiled: $compiledCount" -ForegroundColor Green
Write-Host "  Failed: $failedCount" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($compiledCount -gt 0) {
    Write-Host "Successfully compiled Expert Advisors:" -ForegroundColor Green
    foreach ($result in $compilationResults) {
        if ($result.Status -eq "Success") {
            Write-Host "  [OK] $($result.File) -> $($result.Ex5Path)" -ForegroundColor White
        }
    }
}

if ($failedCount -gt 0) {
    Write-Host ""
    Write-Host "Failed to compile:" -ForegroundColor Yellow
    foreach ($result in $compilationResults) {
        if ($result.Status -ne "Success") {
            Write-Host "  [FAILED] $($result.File)" -ForegroundColor Red
            if ($result.Error) {
                Write-Host "    Error: $($result.Error)" -ForegroundColor Red
            }
        }
    }
    Write-Host ""
    Write-Host "[INFO] To compile manually:" -ForegroundColor Cyan
    Write-Host "  1. Open MetaEditor" -ForegroundColor White
    Write-Host "  2. Open the .mq5 file" -ForegroundColor White
    Write-Host "  3. Press F7 or click Compile" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Compilation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

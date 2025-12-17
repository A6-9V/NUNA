#Requires -Version 5.1
<#
.SYNOPSIS
    Export Browser Data (Chrome, Firefox, Edge)
.DESCRIPTION
    Exports bookmarks, history, and other data from installed browsers
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Browser Data Export" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$exportDir = "C:\Users\USER\OneDrive\Browser-Exports"
if (-not (Test-Path $exportDir)) {
    New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$chromeDir = "$exportDir\Chrome-$timestamp"
$firefoxDir = "$exportDir\Firefox-$timestamp"
$edgeDir = "$exportDir\Edge-$timestamp"

# Export Chrome Data
Write-Host "[1/3] Exporting Chrome data..." -ForegroundColor Yellow
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}

if (Test-Path $chromePath) {
    New-Item -ItemType Directory -Path $chromeDir -Force | Out-Null
    $chromeDataPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
    
    if (Test-Path $chromeDataPath) {
        Write-Host "    [OK] Chrome data directory found" -ForegroundColor Green
        
        # Export bookmarks
        $bookmarksPath = Join-Path $chromeDataPath "Bookmarks"
        if (Test-Path $bookmarksPath) {
            Copy-Item $bookmarksPath "$chromeDir\bookmarks.json" -Force
            Write-Host "    [OK] Bookmarks exported" -ForegroundColor Green
        }
        
        # Export history (SQLite database)
        $historyPath = Join-Path $chromeDataPath "History"
        if (Test-Path $historyPath) {
            Copy-Item $historyPath "$chromeDir\history.db" -Force -ErrorAction SilentlyContinue
            Write-Host "    [OK] History database copied" -ForegroundColor Green
        }
        
        Write-Host "    [OK] Chrome data exported to: $chromeDir" -ForegroundColor Green
    } else {
        Write-Host "    [WARNING] Chrome data directory not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Chrome not installed" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[2/3] Exporting Firefox data..." -ForegroundColor Yellow
$firefoxPath = "C:\Program Files\Mozilla Firefox\firefox.exe"
if (-not (Test-Path $firefoxPath)) {
    $firefoxPath = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
}

if (Test-Path $firefoxPath) {
    New-Item -ItemType Directory -Path $firefoxDir -Force | Out-Null
    $firefoxProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
    
    if (Test-Path $firefoxProfiles) {
        Write-Host "    [OK] Firefox profiles directory found" -ForegroundColor Green
        
        # Find default profile
        $profiles = Get-ChildItem $firefoxProfiles -Directory | Where-Object {$_.Name -like "*.default*"} | Select-Object -First 1
        if ($profiles) {
            $profilePath = $profiles.FullName
            
            # Export bookmarks
            $placesPath = Join-Path $profilePath "places.sqlite"
            if (Test-Path $placesPath) {
                Copy-Item $placesPath "$firefoxDir\places.sqlite" -Force -ErrorAction SilentlyContinue
                Write-Host "    [OK] Bookmarks/history database copied" -ForegroundColor Green
            }
            
            # Export bookmarks backup
            $bookmarksBackup = Join-Path $profilePath "bookmarkbackups"
            if (Test-Path $bookmarksBackup) {
                Copy-Item $bookmarksBackup "$firefoxDir\bookmarkbackups" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "    [OK] Bookmarks backup copied" -ForegroundColor Green
            }
            
            Write-Host "    [OK] Firefox data exported to: $firefoxDir" -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] Firefox default profile not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [WARNING] Firefox profiles directory not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Firefox not installed" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[3/3] Exporting Edge data..." -ForegroundColor Yellow
$edgeDataPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
if (Test-Path $edgeDataPath) {
    New-Item -ItemType Directory -Path $edgeDir -Force | Out-Null
    Write-Host "    [OK] Edge data directory found" -ForegroundColor Green
    
    # Export bookmarks
    $bookmarksPath = Join-Path $edgeDataPath "Bookmarks"
    if (Test-Path $bookmarksPath) {
        Copy-Item $bookmarksPath "$edgeDir\bookmarks.json" -Force
        Write-Host "    [OK] Bookmarks exported" -ForegroundColor Green
    }
    
    Write-Host "    [OK] Edge data exported to: $edgeDir" -ForegroundColor Green
} else {
    Write-Host "    [INFO] Edge data directory not found" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Export Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Browser data exported to: $exportDir" -ForegroundColor Green
Write-Host ""


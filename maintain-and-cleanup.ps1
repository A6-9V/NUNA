#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive System Maintenance and Cleanup Script
.DESCRIPTION
    Performs system maintenance including:
    - Disk space check
    - Temporary file cleanup
    - Code cleanup (duplicates, empty dirs)
    - Old log file cleanup
    - System status verification
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  System Maintenance and Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# 1. Disk Space Check
# ========================================
Write-Host "[1/5] Checking Disk Space..." -ForegroundColor Yellow

try {
    $cDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $totalGB = [math]::Round($cDrive.Size / 1GB, 2)
    $freeGB = [math]::Round($cDrive.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round(($cDrive.Size - $cDrive.FreeSpace) / 1GB, 2)
    $freePercent = [math]::Round(($cDrive.FreeSpace / $cDrive.Size) * 100, 1)
    
    Write-Host "  C: Drive Status:" -ForegroundColor Cyan
    Write-Host "    Total: $totalGB GB" -ForegroundColor White
    Write-Host "    Used: $usedGB GB" -ForegroundColor Yellow
    Write-Host "    Free: $freeGB GB ($freePercent%)" -ForegroundColor $(if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 20) { "Yellow" } else { "Green" })
    
    if ($freePercent -lt 10) {
        Write-Host "  [WARNING] C: drive is critically low on space!" -ForegroundColor Red
    } elseif ($freePercent -lt 20) {
        Write-Host "  [WARNING] C: drive is running low on space" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] C: drive has adequate free space" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] Could not check disk space: $_" -ForegroundColor Red
}

Write-Host ""

# ========================================
# 2. Clean Temporary Files
# ========================================
Write-Host "[2/5] Cleaning Temporary Files..." -ForegroundColor Yellow

$tempPaths = @(
    @{ Path = $env:TEMP; Name = "User Temp" },
    @{ Path = "$env:LOCALAPPDATA\Temp"; Name = "Local AppData Temp" },
    @{ Path = "C:\Windows\Temp"; Name = "Windows Temp" }
)

$totalCleaned = 0
foreach ($tempPath in $tempPaths) {
    if (Test-Path $tempPath.Path) {
        try {
            $files = Get-ChildItem -Path $tempPath.Path -Recurse -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }
            $size = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($size) {
                $sizeGB = [math]::Round($size / 1GB, 2)
                Write-Host "  Found $sizeGB GB in $($tempPath.Name)" -ForegroundColor Cyan
                Remove-Item "$($tempPath.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
                $totalCleaned += $size
                Write-Host "  [OK] Cleaned $($tempPath.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [WARNING] Could not clean $($tempPath.Name): $_" -ForegroundColor Yellow
        }
    }
}

if ($totalCleaned -gt 0) {
    Write-Host "  [OK] Cleaned $([math]::Round($totalCleaned / 1GB, 2)) GB of temporary files" -ForegroundColor Green
} else {
    Write-Host "  [OK] No temporary files to clean" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 3. Code Cleanup (Duplicates, Empty Dirs)
# ========================================
Write-Host "[3/5] Cleaning Code and Project Files..." -ForegroundColor Yellow

$workspaceRoot = $PSScriptRoot
if (-not $workspaceRoot) {
    $workspaceRoot = Get-Location
}

$cleanupStats = @{
    DuplicatesRemoved = 0
    EmptyDirsRemoved = 0
    OldLogsRemoved = 0
}

# Find and remove duplicate files
$duplicatePatterns = @("* (1).*", "* (2).*", "* - Copy.*", "* - Copy (1).*")
foreach ($pattern in $duplicatePatterns) {
    $duplicates = Get-ChildItem -Path $workspaceRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notlike "*\.git\*" -and
        $_.FullName -notlike "*\node_modules\*" -and
        $_.FullName -notlike "*\vps-logs\*"
    }
    
    foreach ($dup in $duplicates) {
        try {
            Remove-Item -Path $dup.FullName -Force -ErrorAction Stop
            $cleanupStats.DuplicatesRemoved++
        } catch {
            # Ignore errors
        }
    }
}

if ($cleanupStats.DuplicatesRemoved -gt 0) {
    Write-Host "  [OK] Removed $($cleanupStats.DuplicatesRemoved) duplicate file(s)" -ForegroundColor Green
} else {
    Write-Host "  [OK] No duplicate files found" -ForegroundColor Green
}

# Remove empty directories
$emptyDirs = Get-ChildItem -Path $workspaceRoot -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\node_modules\*" -and
    (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0
}

foreach ($dir in $emptyDirs) {
    try {
        Remove-Item -Path $dir.FullName -Force -ErrorAction Stop
        $cleanupStats.EmptyDirsRemoved++
    } catch {
        # Ignore errors
    }
}

if ($cleanupStats.EmptyDirsRemoved -gt 0) {
    Write-Host "  [OK] Removed $($cleanupStats.EmptyDirsRemoved) empty directory(ies)" -ForegroundColor Green
} else {
    Write-Host "  [OK] No empty directories found" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 4. Clean Old Log Files
# ========================================
Write-Host "[4/5] Cleaning Old Log Files..." -ForegroundColor Yellow

$logDirs = @(
    "vps-logs",
    "trading-bridge\logs",
    "logs"
)

$cutoffDate = (Get-Date).AddDays(-30)
foreach ($logDir in $logDirs) {
    $logPath = Join-Path $workspaceRoot $logDir
    if (Test-Path $logPath) {
        $oldLogs = Get-ChildItem -Path $logPath -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.LastWriteTime -lt $cutoffDate
        }
        
        foreach ($log in $oldLogs) {
            try {
                Remove-Item -Path $log.FullName -Force -ErrorAction Stop
                $cleanupStats.OldLogsRemoved++
            } catch {
                # Ignore errors
            }
        }
    }
}

if ($cleanupStats.OldLogsRemoved -gt 0) {
    Write-Host "  [OK] Removed $($cleanupStats.OldLogsRemoved) old log file(s) (older than 30 days)" -ForegroundColor Green
} else {
    Write-Host "  [OK] No old log files to clean" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 5. System Status Verification
# ========================================
Write-Host "[5/5] Verifying System Status..." -ForegroundColor Yellow

# Check if key services/processes are running
$keyProcesses = @("Cursor", "Code")
$runningProcesses = @()
foreach ($proc in $keyProcesses) {
    $procs = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($procs) {
        $runningProcesses += "$proc ($($procs.Count) instance(s))"
    }
}

if ($runningProcesses.Count -gt 0) {
    Write-Host "  [INFO] Running processes:" -ForegroundColor Cyan
    foreach ($proc in $runningProcesses) {
        Write-Host "    - $proc" -ForegroundColor White
    }
} else {
    Write-Host "  [INFO] No key processes currently running" -ForegroundColor Cyan
}

# Check network connectivity
try {
    $networkTest = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($networkTest) {
        Write-Host "  [OK] Network connectivity: OK" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Network connectivity: Failed" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [INFO] Network check skipped" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# Summary
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Maintenance Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Temporary Files Cleaned: $([math]::Round($totalCleaned / 1GB, 2)) GB" -ForegroundColor Green
Write-Host "Duplicate Files Removed: $($cleanupStats.DuplicatesRemoved)" -ForegroundColor Green
Write-Host "Empty Directories Removed: $($cleanupStats.EmptyDirsRemoved)" -ForegroundColor Green
Write-Host "Old Log Files Removed: $($cleanupStats.OldLogsRemoved)" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] Maintenance and cleanup completed successfully!" -ForegroundColor Green
Write-Host ""


# Comprehensive Drive Cleanup Script
# Cleans up all drives with safety checks and logging

param(
    [switch]$DryRun,
    [switch]$Verbose,
    # Accepts "C", "C:", or "C:\"
    [string[]]$ExcludeDrives = @("C"),
    [int]$MinFileAgeDays = 30,
    # Off by default: Deep scanning an entire drive is slow and risky.
    [switch]$DeepScan
)

$ErrorActionPreference = "Continue"
$script:LogFile = Join-Path $PSScriptRoot "cleanup-log-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARNING") { "Yellow" } elseif ($Level -eq "SUCCESS") { "Green" } else { "White" })
    Add-Content -Path $script:LogFile -Value $logEntry
}

Write-Log "=== Drive Cleanup Started ===" -Level "INFO"
Write-Log "Dry Run Mode: $DryRun" -Level "INFO"
Write-Log "Excluded Drives: $($ExcludeDrives -join ', ')" -Level "INFO"
Write-Log "Deep Scan Mode: $DeepScan" -Level "INFO"

# Normalize excluded drive letters (C, D, etc.)
$excludedDriveNames = @(
    $ExcludeDrives |
        ForEach-Object { $_.Trim().TrimEnd('\').TrimEnd(':').ToUpperInvariant() } |
        Where-Object { $_ }
) | Select-Object -Unique

# Get all drives
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { 
    $_.Used -ne $null -and 
    $_.Free -ne $null -and 
    $_.Root -notlike "*\*" -and
    $excludedDriveNames -notcontains $_.Name.ToUpperInvariant()
}

$cleanupStats = @{
    TotalDrives = $drives.Count
    DrivesProcessed = 0
    FilesDeleted = 0
    FoldersDeleted = 0
    SpaceFreed = 0
    Errors = 0
}

# Cleanup patterns
$cleanupPatterns = @{
    TempFiles = @("*.tmp", "*.temp", "~$*", "*.bak", "*.old")
    # NOTE: Do NOT include "*.txt" here — it can delete real documents.
    LogFiles = @("*.log")
    CacheFiles = @("Thumbs.db", "desktop.ini", ".DS_Store")
    BrowserCache = @("Cache", "Temp", "Cookies")
    SystemTemp = @("$env:TEMP\*", "$env:LOCALAPPDATA\Temp\*")
}

function Clean-TempFiles {
    param([string]$Path, [int]$MaxAgeDays = $MinFileAgeDays)
    
    $deleted = 0
    $spaceFreed = 0
    
    try {
        foreach ($pattern in $cleanupPatterns.TempFiles) {
            $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -ErrorAction SilentlyContinue |
                Where-Object { 
                    $_.LastWriteTime -lt (Get-Date).AddDays(-$MaxAgeDays) -and
                    -not $_.PSIsContainer
                }
            
            foreach ($file in $files) {
                try {
                    if (-not $DryRun) {
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    }
                    $deleted++
                    $spaceFreed += $file.Length
                    if ($Verbose) {
                        Write-Log "Deleted: $($file.FullName)" -Level "SUCCESS"
                    }
                } catch {
                    Write-Log "Failed to delete: $($file.FullName) - $($_.Exception.Message)" -Level "ERROR"
                    $script:cleanupStats.Errors++
                }
            }
        }
    } catch {
        Write-Log "Error cleaning temp files in $Path : $($_.Exception.Message)" -Level "ERROR"
    }
    
    return @{ Deleted = $deleted; SpaceFreed = $spaceFreed }
}

function Clean-EmptyFolders {
    param([string]$Path)
    
    $deleted = 0
    
    try {
        $emptyFolders = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { 
                (Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0
            } |
            Sort-Object -Property FullName -Descending
        
        foreach ($folder in $emptyFolders) {
            try {
                if (-not $DryRun) {
                    Remove-Item -Path $folder.FullName -Force -ErrorAction Stop
                }
                $deleted++
                if ($Verbose) {
                    Write-Log "Deleted empty folder: $($folder.FullName)" -Level "SUCCESS"
                }
            } catch {
                Write-Log "Failed to delete folder: $($folder.FullName)" -Level "ERROR"
                $script:cleanupStats.Errors++
            }
        }
    } catch {
        Write-Log "Error cleaning empty folders in $Path : $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $deleted
}

function Clean-Drive {
    param([object]$Drive)
    
    $drivePath = $Drive.Root
    Write-Log "Processing drive: $drivePath" -Level "INFO"
    
    $driveStats = @{
        FilesDeleted = 0
        FoldersDeleted = 0
        SpaceFreed = 0
    }
    
    $systemDriveName = $env:SystemDrive.TrimEnd('\').TrimEnd(':').ToUpperInvariant()

    # Clean temp files (safe locations only)
    $pathsToClean = @()

    # Per-drive "Temp" folders (common on data drives)
    $pathsToClean += @(
        (Join-Path $drivePath "Temp"),
        (Join-Path $drivePath "tmp")
    )

    # System drive temp locations
    if ($Drive.Name.ToUpperInvariant() -eq $systemDriveName) {
        $pathsToClean += @(
            $env:TEMP,
            (Join-Path $env:WINDIR "Temp"),
            (Join-Path $env:LOCALAPPDATA "Temp")
        )

        # Windows Update download cache (safe to clear; Windows will re-download)
        $pathsToClean += @(
            (Join-Path $env:WINDIR "SoftwareDistribution\Download")
        )
    }

    $pathsToClean = $pathsToClean | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

    Write-Log "Cleaning temp/cache locations on $($Drive.Name): $($pathsToClean.Count) path(s)..." -Level "INFO"
    foreach ($path in $pathsToClean) {
        $tempResult = Clean-TempFiles -Path $path
        $driveStats.FilesDeleted += $tempResult.Deleted
        $driveStats.SpaceFreed += $tempResult.SpaceFreed
    }

    # Empty folder cleanup only in DeepScan mode (can be slow on full drives)
    if ($DeepScan) {
        Write-Log "Deep scan enabled: cleaning empty folders on $drivePath..." -Level "INFO"
        $driveStats.FoldersDeleted += Clean-EmptyFolders -Path $drivePath
    }
    
    # Clean system cache files
    if ($DeepScan) {
        Write-Log "Deep scan enabled: cleaning cache marker files on $drivePath..." -Level "INFO"
        foreach ($cacheFile in $cleanupPatterns.CacheFiles) {
            $files = Get-ChildItem -Path $drivePath -Filter $cacheFile -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    if (-not $DryRun) {
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    }
                    $driveStats.FilesDeleted++
                    $driveStats.SpaceFreed += $file.Length
                } catch {
                    $script:cleanupStats.Errors++
                }
            }
        }
    }

    # Recycle Bin cleanup (best-effort)
    try {
        if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) {
            if (-not $DryRun) {
                Clear-RecycleBin -DriveLetter $Drive.Name -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Write-Log "Recycle Bin processed for drive $($Drive.Name):\" -Level "INFO"
        }
    } catch {
        # Non-fatal
    }
    
    Write-Log "Drive $drivePath cleanup complete: $($driveStats.FilesDeleted) files, $($driveStats.FoldersDeleted) folders, $([math]::Round($driveStats.SpaceFreed/1MB, 2)) MB freed" -Level "SUCCESS"
    
    $script:cleanupStats.FilesDeleted += $driveStats.FilesDeleted
    $script:cleanupStats.FoldersDeleted += $driveStats.FoldersDeleted
    $script:cleanupStats.SpaceFreed += $driveStats.SpaceFreed
    $script:cleanupStats.DrivesProcessed++
}

# Process each drive
foreach ($drive in $drives) {
    Clean-Drive -Drive $drive
}

# Summary
Write-Log "`n=== Cleanup Summary ===" -Level "INFO"
Write-Log "Drives Processed: $($cleanupStats.DrivesProcessed)" -Level "INFO"
Write-Log "Files Deleted: $($cleanupStats.FilesDeleted)" -Level "INFO"
Write-Log "Folders Deleted: $($cleanupStats.FoldersDeleted)" -Level "INFO"
Write-Log "Space Freed: $([math]::Round($cleanupStats.SpaceFreed/1GB, 2)) GB" -Level "SUCCESS"
Write-Log "Errors: $($cleanupStats.Errors)" -Level $(if ($cleanupStats.Errors -gt 0) { "WARNING" } else { "INFO" })
Write-Log "Log file: $script:LogFile" -Level "INFO"

if ($DryRun) {
    Write-Log "`n⚠️ DRY RUN MODE - No files were actually deleted" -Level "WARNING"
}


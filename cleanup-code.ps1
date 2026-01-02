#Requires -Version 5.1
<#
.SYNOPSIS
    Code Cleanup Script
.DESCRIPTION
    Cleans up duplicate files, organizes code, removes unused files
    Consolidates VPS services and standardizes formatting
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$cleanupLog = Join-Path $workspaceRoot "cleanup-log_$(Get-Date -Format 'yyyyMMdd').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Code Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Write-CleanupLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append $cleanupLog
    Write-Host $Message
}

# Track cleanup actions
$cleanupActions = @{
    "duplicates_removed" = 0
    "files_organized" = 0
    "empty_dirs_removed" = 0
    "old_files_removed" = 0
}

# Step 1: Find and remove duplicate files
Write-Host "[1/6] Finding duplicate files..." -ForegroundColor Yellow

$duplicatePatterns = @(
    @{ "pattern" = "* (1).*"; "description" = "Windows duplicate files" },
    @{ "pattern" = "* (2).*"; "description" = "Windows duplicate files" },
    @{ "pattern" = "* - Copy.*"; "description" = "Copy files" },
    @{ "pattern" = "* - Copy (1).*"; "description" = "Copy files" }
)

$duplicatesFound = @()
foreach ($dup in $duplicatePatterns) {
    $files = Get-ChildItem -Path $workspaceRoot -Filter $dup.pattern -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notlike "*\.git\*" -and
        $_.FullName -notlike "*\node_modules\*" -and
        $_.FullName -notlike "*\vps-logs\*" -and
        $_.FullName -notlike "*\trading-bridge\logs\*"
    }
    
    foreach ($file in $files) {
        $duplicatesFound += $file
        Write-CleanupLog "Found duplicate: $($file.FullName)"
    }
}

if ($duplicatesFound.Count -gt 0) {
    Write-Host "  Found $($duplicatesFound.Count) duplicate file(s)" -ForegroundColor Yellow
    foreach ($file in $duplicatesFound) {
        try {
            Remove-Item -Path $file.FullName -Force -Recurse -ErrorAction Stop
            $cleanupActions.duplicates_removed++
            Write-CleanupLog "Removed: $($file.FullName)"
        } catch {
            Write-CleanupLog "ERROR: Could not remove $($file.FullName) - $_"
        }
    }
} else {
    Write-Host "  [OK] No duplicate files found" -ForegroundColor Green
}

# Step 2: Consolidate duplicate directories
Write-Host "[2/6] Consolidating duplicate directories..." -ForegroundColor Yellow

$duplicateDirs = @(
    @{ "source" = "my-drive-projects\vps-services"; "target" = "vps-services"; "description" = "VPS services" },
    @{ "source" = "my-drive-projects\storage-management"; "target" = "storage-management"; "description" = "Storage management" }
)

foreach ($dir in $duplicateDirs) {
    $sourcePath = Join-Path $workspaceRoot $dir.source
    $targetPath = Join-Path $workspaceRoot $dir.target
    
    if ((Test-Path $sourcePath) -and (Test-Path $targetPath)) {
        Write-Host "  Consolidating $($dir.description)..." -ForegroundColor Cyan
        
        # Compare and merge files
        $sourceFiles = Get-ChildItem -Path $sourcePath -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $sourceFiles) {
            $relativePath = $file.FullName.Replace($sourcePath, "").TrimStart("\")
            $targetFile = Join-Path $targetPath $relativePath
            
            if (-not (Test-Path $targetFile)) {
                # Copy unique files
                $targetDir = Split-Path $targetFile -Parent
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                Copy-Item -Path $file.FullName -Destination $targetFile -Force
                Write-CleanupLog "Copied: $relativePath"
                $cleanupActions.files_organized++
            }
        }
        
        # Remove source directory after consolidation
        try {
            Remove-Item -Path $sourcePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-CleanupLog "Removed duplicate directory: $($dir.source)"
        } catch {
            Write-CleanupLog "WARNING: Could not remove $($dir.source) - may contain unique files"
        }
    }
}

# Step 3: Remove empty directories
Write-Host "[3/6] Removing empty directories..." -ForegroundColor Yellow

$emptyDirs = Get-ChildItem -Path $workspaceRoot -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\node_modules\*" -and
    (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0
}

foreach ($dir in $emptyDirs) {
    try {
        Remove-Item -Path $dir.FullName -Force -ErrorAction Stop
        $cleanupActions.empty_dirs_removed++
        Write-CleanupLog "Removed empty directory: $($dir.FullName)"
    } catch {
        # Ignore errors for empty dir removal
    }
}

Write-Host "  Removed $($cleanupActions.empty_dirs_removed) empty directory(ies)" -ForegroundColor Green

# Step 4: Remove old log files (older than 30 days)
Write-Host "[4/6] Cleaning old log files..." -ForegroundColor Yellow

$logDirs = @(
    "vps-logs",
    "trading-bridge\logs",
    "logs"
)

$cutoffDate = (Get-Date).AddDays(-30)
$oldLogsRemoved = 0

foreach ($logDir in $logDirs) {
    $logPath = Join-Path $workspaceRoot $logDir
    if (Test-Path $logPath) {
        $oldLogs = Get-ChildItem -Path $logPath -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.LastWriteTime -lt $cutoffDate
        }
        
        foreach ($log in $oldLogs) {
            try {
                Remove-Item -Path $log.FullName -Force -ErrorAction Stop
                $oldLogsRemoved++
                Write-CleanupLog "Removed old log: $($log.Name)"
            } catch {
                Write-CleanupLog "WARNING: Could not remove $($log.FullName)"
            }
        }
    }
}

$cleanupActions.old_files_removed = $oldLogsRemoved
Write-Host "  Removed $oldLogsRemoved old log file(s)" -ForegroundColor Green

# Step 5: Organize documentation files
Write-Host "[5/6] Organizing documentation..." -ForegroundColor Yellow

$docFiles = Get-ChildItem -Path $workspaceRoot -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*REPORT*" -or
    $_.Name -like "*SUMMARY*" -or
    $_.Name -like "*COMPLETE*" -or
    $_.Name -like "*FINAL*"
}

$docsDir = Join-Path $workspaceRoot "Documentation\Reports"
if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}

foreach ($doc in $docFiles) {
    try {
        $targetPath = Join-Path $docsDir $doc.Name
        if (-not (Test-Path $targetPath)) {
            Move-Item -Path $doc.FullName -Destination $targetPath -Force
            Write-CleanupLog "Moved documentation: $($doc.Name)"
            $cleanupActions.files_organized++
        }
    } catch {
        Write-CleanupLog "WARNING: Could not move $($doc.Name)"
    }
}

# Step 6: Standardize PowerShell script formatting
Write-Host "[6/6] Checking PowerShell script formatting..." -ForegroundColor Yellow

$psScripts = Get-ChildItem -Path $workspaceRoot -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\node_modules\*" -and
    $_.FullName -notlike "*\trading-bridge\*"
}

$scriptsChecked = 0
foreach ($script in $psScripts) {
    try {
        $content = Get-Content $script.FullName -Raw -ErrorAction Stop
        
        # Check for common issues
        $issues = @()
        if ($content -notmatch "#Requires|#Requires -Version") {
            # Not critical, just note
        }
        # Check for potential credential exposure (case-insensitive, whole word)
        if ($content -match "(?i)Write-Host.*\`$.*(password|key|secret|token|credential)", "Write-Host.*\`$.*(password|key|secret|token|credential)") {
            $issues += "Potential credential exposure"
        }
        
        if ($issues.Count -gt 0) {
            Write-CleanupLog "WARNING: $($script.Name) - $($issues -join ', ')"
        }
        
        $scriptsChecked++
    } catch {
        Write-CleanupLog "ERROR: Could not check $($script.Name)"
    }
}

Write-Host "  Checked $scriptsChecked PowerShell script(s)" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Duplicates removed: $($cleanupActions.duplicates_removed)" -ForegroundColor Green
Write-Host "Files organized: $($cleanupActions.files_organized)" -ForegroundColor Green
Write-Host "Empty directories removed: $($cleanupActions.empty_dirs_removed)" -ForegroundColor Green
Write-Host "Old files removed: $($cleanupActions.old_files_removed)" -ForegroundColor Green
Write-Host ""
Write-Host "Cleanup log: $cleanupLog" -ForegroundColor Cyan
Write-Host ""


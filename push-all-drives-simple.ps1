#Requires -Version 5.1
<#
.SYNOPSIS
    Push All Drives to Same GitHub Repository (Simple Version)
.DESCRIPTION
    Finds git repositories on all drives and pushes them to my-drive-projects
#>

$ErrorActionPreference = "Continue"
$targetRepo = "https://github.com/A6-9V/my-drive-projects.git"
$targetRemote = "drive-projects"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Push All Drives to Same Repository" -ForegroundColor Cyan
Write-Host "  Target: $targetRepo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all drives
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[A-Z]$' }
Write-Host "Found $($drives.Count) drive(s): $($drives.Name -join ', ')" -ForegroundColor Yellow
Write-Host ""

$repos = @()

# Check each drive for .vscode directory with .git
foreach ($drive in $drives) {
    $vscodePath = "$($drive.Root).vscode"
    if (Test-Path "$vscodePath\.git") {
        $repos += $vscodePath
        Write-Host "[FOUND] $vscodePath" -ForegroundColor Green
    }
}

# Also check current directory
$currentPath = (Get-Location).Path
if (Test-Path "$currentPath\.git") {
    if ($currentPath -notin $repos) {
        $repos += $currentPath
        Write-Host "[FOUND] $currentPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Found $($repos.Count) repository(ies) to process" -ForegroundColor Cyan
Write-Host ""

if ($repos.Count -eq 0) {
    Write-Host "[ERROR] No repositories found" -ForegroundColor Red
    exit 1
}

# Process each repository
$success = 0
$failed = 0

foreach ($repoPath in $repos) {
    Write-Host "Processing: $repoPath" -ForegroundColor Yellow
    
    try {
        Push-Location $repoPath
        
        # Check if valid git repo
        $branch = git branch --show-current 2>&1
        if (-not $branch -or $LASTEXITCODE -ne 0) {
            Write-Host "  [SKIP] Not a valid git repository" -ForegroundColor Gray
            Pop-Location
            continue
        }
        
        Write-Host "  Branch: $branch" -ForegroundColor Gray
        
        # Add/update remote
        $remotes = git remote 2>&1
        if ($targetRemote -notin $remotes) {
            git remote add $targetRemote $targetRepo 2>&1 | Out-Null
            Write-Host "  [INFO] Added remote: $targetRemote" -ForegroundColor Cyan
        } else {
            git remote set-url $targetRemote $targetRepo 2>&1 | Out-Null
            Write-Host "  [INFO] Updated remote: $targetRemote" -ForegroundColor Cyan
        }
        
        # Stage and commit
        git add . 2>&1 | Out-Null
        $status = git status --porcelain 2>&1
        if ($status) {
            $commitMsg = "Push from $repoPath - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            git commit -m $commitMsg 2>&1 | Out-Null
            Write-Host "  [INFO] Committed changes" -ForegroundColor Cyan
        }
        
        # Fetch and merge
        git fetch $targetRemote 2>&1 | Out-Null
        git pull $targetRemote main --no-edit 2>&1 | Out-Null
        
        # Push
        Write-Host "  [INFO] Pushing to $targetRemote..." -ForegroundColor Cyan
        $pushOut = git push $targetRemote $branch:main 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Successfully pushed!" -ForegroundColor Green
            $success++
        } else {
            Write-Host "  [ERROR] Push failed" -ForegroundColor Red
            Write-Host "  $($pushOut -split \"`n\" | Select-Object -First 2)" -ForegroundColor Red
            $failed++
        }
        
        Pop-Location
    } catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $failed++
        Pop-Location
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Repositories: $($repos.Count)" -ForegroundColor Cyan
Write-Host "  Successful: $success" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host ""


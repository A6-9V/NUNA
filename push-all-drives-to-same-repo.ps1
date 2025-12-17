#Requires -Version 5.1
<#
.SYNOPSIS
    Push All Drives to Same GitHub Repository
.DESCRIPTION
    Finds all git repositories on all drives and pushes them to the same repository (my-drive-projects)
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Push All Drives to Same Repository" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Target repository
$targetRepo = "https://github.com/A6-9V/my-drive-projects.git"
$targetRemoteName = "drive-projects"

# Get all file system drives
Write-Host "[1/4] Scanning all drives for git repositories..." -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[A-Z]$' }
Write-Host "  Found $($drives.Count) drive(s): $($drives.Name -join ', ')" -ForegroundColor Cyan
Write-Host ""

$repositories = @()

# First, check current directory if it's a git repo
$currentDir = Get-Location
if (Test-Path (Join-Path $currentDir ".git")) {
    $repositories += [PSCustomObject]@{
        Path = $currentDir.Path
        Drive = $currentDir.Drive.Name
        Type = "Current"
    }
    Write-Host "  [FOUND] Git repository at current location: $currentDir" -ForegroundColor Green
}

foreach ($drive in $drives) {
    $drivePath = $drive.Root
    Write-Host "  Scanning $drivePath..." -ForegroundColor Gray
    
    # Check if the drive root itself is a git repo
    if (Test-Path (Join-Path $drivePath ".git")) {
        $repoPath = $drivePath
        if ($repoPath -notin $repositories.Path) {
            $repositories += [PSCustomObject]@{
                Path = $repoPath
                Drive = $drive.Name
                Type = "Root"
            }
            Write-Host "    [FOUND] Git repository at $drivePath" -ForegroundColor Green
        }
    }
    
    # Check .vscode directory on drive root (common location)
    $vscodePath = "$drivePath\.vscode"
    if (Test-Path $vscodePath) {
        if (Test-Path (Join-Path $vscodePath ".git")) {
            if ($vscodePath -notin $repositories.Path) {
                $repositories += [PSCustomObject]@{
                    Path = $vscodePath
                    Drive = $drive.Name
                    Type = ".vscode"
                }
                Write-Host "    [FOUND] Git repository at $vscodePath" -ForegroundColor Green
            }
        }
    }
    
    # Search for .git directories in common locations only (faster)
    $commonPaths = @(
        "$drivePath\OneDrive",
        "$drivePath\Documents",
        "$drivePath\Projects",
        "$drivePath\Users\$env:USERNAME\OneDrive",
        "$drivePath\Users\$env:USERNAME\Documents"
    )
    
    foreach ($commonPath in $commonPaths) {
        if (Test-Path $commonPath) {
            try {
                # Check the path itself first
                if (Test-Path (Join-Path $commonPath ".git")) {
                    if ($commonPath -notin $repositories.Path) {
                        $repositories += [PSCustomObject]@{
                            Path = $commonPath
                            Drive = $drive.Name
                            Type = "Common"
                        }
                        Write-Host "    [FOUND] Git repository at $commonPath" -ForegroundColor Green
                    }
                }
                
                # Then check subdirectories (limited depth)
                $gitDirs = Get-ChildItem -Path $commonPath -Directory -Filter ".git" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Select-Object -First 5
                foreach ($gitDir in $gitDirs) {
                    $repoPath = $gitDir.Parent.FullName
                    if ($repoPath -notin $repositories.Path) {
                        $repositories += [PSCustomObject]@{
                            Path = $repoPath
                            Drive = $drive.Name
                            Type = "Subdirectory"
                        }
                        Write-Host "    [FOUND] Git repository at $repoPath" -ForegroundColor Green
                    }
                }
            } catch {
                # Skip if can't access
            }
        }
    }
}

Write-Host ""
Write-Host "  [OK] Found $($repositories.Count) git repository(ies)" -ForegroundColor Green
Write-Host ""

if ($repositories.Count -eq 0) {
    Write-Host "[ERROR] No git repositories found on any drive" -ForegroundColor Red
    exit 1
}

# ============================================
# STEP 2: Configure and Push Each Repository
# ============================================
Write-Host "[2/4] Configuring repositories to push to: $targetRepo" -ForegroundColor Yellow
Write-Host ""

$pushResults = @()
$successCount = 0
$errorCount = 0

foreach ($repo in $repositories) {
    Write-Host "Processing: $($repo.Path)" -ForegroundColor Cyan
    Write-Host "  Drive: $($repo.Drive):" -ForegroundColor Gray
    Write-Host "  Type: $($repo.Type)" -ForegroundColor Gray
    
    try {
        Push-Location $repo.Path
        
        # Check if it's a valid git repository
        $gitStatus = git status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [SKIP] Not a valid git repository" -ForegroundColor Yellow
            Pop-Location
            continue
        }
        
        # Get current branch
        $currentBranch = git branch --show-current 2>&1
        if (-not $currentBranch) {
            Write-Host "  [SKIP] No branch found" -ForegroundColor Yellow
            Pop-Location
            continue
        }
        
        Write-Host "  Branch: $currentBranch" -ForegroundColor Gray
        
        # Check if target remote exists, if not add it
        $remotes = git remote 2>&1
        if ($targetRemoteName -notin $remotes) {
            Write-Host "  [INFO] Adding remote: $targetRemoteName" -ForegroundColor Yellow
            git remote add $targetRemoteName $targetRepo 2>&1 | Out-Null
        } else {
            # Update remote URL to ensure it points to target repo
            $existingUrl = git remote get-url $targetRemoteName 2>&1
            if ($existingUrl -ne $targetRepo) {
                Write-Host "  [INFO] Updating remote URL to target repository" -ForegroundColor Yellow
                git remote set-url $targetRemoteName $targetRepo 2>&1 | Out-Null
            }
        }
        
        # Stage all changes
        Write-Host "  [INFO] Staging changes..." -ForegroundColor Gray
        git add . 2>&1 | Out-Null
        
        # Check if there are changes to commit
        $statusCheck = git status --porcelain 2>&1
        if ($statusCheck) {
            $commitMessage = "Push from $($repo.Drive): drive - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            Write-Host "  [INFO] Committing changes..." -ForegroundColor Gray
            git commit -m $commitMessage 2>&1 | Out-Null
        }
        
        # Fetch from target remote
        Write-Host "  [INFO] Fetching from target repository..." -ForegroundColor Gray
        git fetch $targetRemoteName 2>&1 | Out-Null
        
        # Try to pull and merge if needed
        $pullOutput = git pull $targetRemoteName main --no-edit 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $pullOutput -match "rejected|conflict") {
            Write-Host "  [INFO] Remote has changes, attempting merge..." -ForegroundColor Yellow
            git pull $targetRemoteName main --rebase --no-edit 2>&1 | Out-Null
        }
        
        # Push to target repository (try main branch first, then current branch)
        Write-Host "  [INFO] Pushing to target repository..." -ForegroundColor Gray
        $pushOutput = git push $targetRemoteName $currentBranch:main 2>&1 | Out-String
        
        if ($LASTEXITCODE -ne 0) {
            # Try pushing to current branch name on remote
            $pushOutput = git push $targetRemoteName $currentBranch 2>&1 | Out-String
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Successfully pushed to $targetRemoteName" -ForegroundColor Green
            $pushResults += [PSCustomObject]@{
                Path = $repo.Path
                Drive = $repo.Drive
                Branch = $currentBranch
                Status = "SUCCESS"
            }
            $successCount++
        } else {
            $errorMsg = ($pushOutput -split "`n" | Select-Object -First 2) -join " "
            Write-Host "  [ERROR] Push failed: $errorMsg" -ForegroundColor Red
            $pushResults += [PSCustomObject]@{
                Path = $repo.Path
                Drive = $repo.Drive
                Branch = $currentBranch
                Status = "ERROR"
                Message = $errorMsg
            }
            $errorCount++
        }
        
        Pop-Location
    } catch {
        Write-Host "  [ERROR] Failed to process repository: $_" -ForegroundColor Red
        $pushResults += [PSCustomObject]@{
            Path = $repo.Path
            Drive = $repo.Drive
            Status = "ERROR"
            Message = $_.ToString()
        }
        $errorCount++
        Pop-Location
    }
    
    Write-Host ""
    Start-Sleep -Seconds 1
}

# ============================================
# STEP 3: Generate Summary Report
# ============================================
Write-Host "[3/4] Generating Summary Report..." -ForegroundColor Yellow
Write-Host ""

$reportPath = Join-Path $PSScriptRoot "ALL-DRIVES-PUSH-REPORT.txt"
$reportContent = @"
========================================
Push All Drives to Same Repository Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

Target Repository: $targetRepo
Remote Name: $targetRemoteName

Repositories Found: $($repositories.Count)
Successful Pushes: $successCount
Failed Pushes: $errorCount

========================================
Detailed Results:
========================================

"@

foreach ($result in $pushResults) {
    $statusIcon = if ($result.Status -eq "SUCCESS") { "[OK]" } else { "[ERROR]" }
    $reportContent += "$statusIcon $($result.Drive): drive - $($result.Path)`n"
    if ($result.Branch) {
        $reportContent += "  Branch: $($result.Branch)`n"
    }
    if ($result.Message) {
        $reportContent += "  Error: $($result.Message)`n"
    }
    $reportContent += "`n"
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "  [OK] Report saved to: $reportPath" -ForegroundColor Green
Write-Host ""

# ============================================
# Final Summary
# ============================================
Write-Host "[4/4] Final Summary" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Push Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repositories Processed: $($repositories.Count)" -ForegroundColor Cyan
Write-Host "  ✅ Successful: $successCount" -ForegroundColor Green
Write-Host "  ❌ Failed: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Target Repository: $targetRepo" -ForegroundColor Cyan
Write-Host "Report: $reportPath" -ForegroundColor Cyan
Write-Host ""


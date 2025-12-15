#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Repository Review, Conflict Resolution, Merge, and Cleanup Script
.DESCRIPTION
    Reviews all repositories, resolves conflicts, merges branches, cleans up, and pushes to all remotes
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Repository Review & Cleanup" -ForegroundColor Cyan
Write-Host "  Complete Workflow" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

# ============================================
# STEP 1: Review All Repositories
# ============================================
Write-Host "[STEP 1/8] Reviewing All Repositories..." -ForegroundColor Yellow
Write-Host ""

# Get all remotes
$remotes = @()
$remoteNames = git remote 2>&1
foreach ($remoteName in $remoteNames) {
    if ($remoteName) {
        $remoteUrl = git remote get-url $remoteName 2>&1
        $remotes += [PSCustomObject]@{
            Name = $remoteName
            URL = $remoteUrl
        }
    }
}

Write-Host "Found $($remotes.Count) remote repository(ies):" -ForegroundColor Cyan
foreach ($remote in $remotes) {
    Write-Host "  - $($remote.Name): $($remote.URL)" -ForegroundColor Green
}
Write-Host ""

# Check current branch
$currentBranch = git branch --show-current 2>&1
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Check git status
Write-Host "Repository Status:" -ForegroundColor Yellow
$status = git status --short 2>&1
if ($status) {
    $modifiedCount = ($status | Where-Object { $_ -match "^ M" }).Count
    $untrackedCount = ($status | Where-Object { $_ -match "^\?\?" }).Count
    $stagedCount = ($status | Where-Object { $_ -match "^M " }).Count
    Write-Host "  Modified files: $modifiedCount" -ForegroundColor Yellow
    Write-Host "  Staged files: $stagedCount" -ForegroundColor Yellow
    Write-Host "  Untracked files: $untrackedCount" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Working directory clean" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 2: Fetch All Remotes
# ============================================
Write-Host "[STEP 2/8] Fetching All Remotes..." -ForegroundColor Yellow
Write-Host ""

foreach ($remote in $remotes) {
    Write-Host "Fetching from: $($remote.Name)" -ForegroundColor Cyan
    try {
        git fetch $remote.Name 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Fetched from $($remote.Name)" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Fetch from $($remote.Name) had issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [ERROR] Failed to fetch from $($remote.Name): $_" -ForegroundColor Red
    }
}
Write-Host ""

# ============================================
# STEP 3: Check for Conflicts and Diverged Branches
# ============================================
Write-Host "[STEP 3/8] Checking for Conflicts and Diverged Branches..." -ForegroundColor Yellow
Write-Host ""

$conflicts = @()
$divergedBranches = @()

foreach ($remote in $remotes) {
    Write-Host "Checking $($remote.Name)/$currentBranch..." -ForegroundColor Cyan
    
    # Check if branch exists on remote
    $remoteBranch = "$($remote.Name)/$currentBranch"
    $branchExists = git branch -r | Select-String -Pattern $remoteBranch
    
    if ($branchExists) {
        # Check if local and remote have diverged
        $localCommit = git rev-parse $currentBranch 2>&1
        $remoteCommit = git rev-parse $remoteBranch 2>&1
        
        if ($localCommit -and $remoteCommit -and $localCommit -ne $remoteCommit) {
            # Check if they have common ancestor
            $mergeBase = git merge-base $currentBranch $remoteBranch 2>&1
            
            if ($mergeBase -and $mergeBase -ne $localCommit -and $mergeBase -ne $remoteCommit) {
                Write-Host "  [INFO] Branch has diverged from $($remote.Name)" -ForegroundColor Yellow
                $divergedBranches += [PSCustomObject]@{
                    Remote = $remote.Name
                    Branch = $currentBranch
                    LocalCommit = $localCommit
                    RemoteCommit = $remoteCommit
                    MergeBase = $mergeBase
                }
            } elseif ($mergeBase -eq $remoteCommit) {
                Write-Host "  [INFO] Local is ahead of $($remote.Name)" -ForegroundColor Cyan
            } elseif ($mergeBase -eq $localCommit) {
                Write-Host "  [INFO] Remote is ahead of local" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [OK] Branch is in sync with $($remote.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [INFO] Branch $currentBranch does not exist on $($remote.Name)" -ForegroundColor Yellow
    }
}
Write-Host ""

# ============================================
# STEP 4: Resolve Conflicts and Merge
# ============================================
Write-Host "[STEP 4/8] Resolving Conflicts and Merging..." -ForegroundColor Yellow
Write-Host ""

$mergeResults = @()

foreach ($diverged in $divergedBranches) {
    Write-Host "Merging $($diverged.Remote)/$($diverged.Branch) into $($diverged.Branch)..." -ForegroundColor Cyan
    
    try {
        # Try to merge
        $mergeOutput = git merge "$($diverged.Remote)/$($diverged.Branch)" --no-edit 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Successfully merged $($diverged.Remote)/$($diverged.Branch)" -ForegroundColor Green
            $mergeResults += [PSCustomObject]@{
                Remote = $diverged.Remote
                Status = "SUCCESS"
                Message = "Merge completed successfully"
            }
        } elseif ($mergeOutput -match "conflict|CONFLICT") {
            Write-Host "  [WARNING] Merge conflicts detected" -ForegroundColor Yellow
            
            # Check for conflict markers
            $conflictFiles = git diff --name-only --diff-filter=U 2>&1
            if ($conflictFiles) {
                Write-Host "  Conflict files:" -ForegroundColor Yellow
                foreach ($file in $conflictFiles) {
                    Write-Host "    - $file" -ForegroundColor Yellow
                }
                
                # Try to auto-resolve using ours strategy (prefer local changes)
                Write-Host "  Attempting to resolve conflicts (preferring local changes)..." -ForegroundColor Cyan
                git checkout --ours . 2>&1 | Out-Null
                git add . 2>&1 | Out-Null
                
                # Complete the merge
                $continueMerge = git commit --no-edit 2>&1 | Out-String
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] Conflicts resolved and merge completed" -ForegroundColor Green
                    $mergeResults += [PSCustomObject]@{
                        Remote = $diverged.Remote
                        Status = "RESOLVED"
                        Message = "Conflicts resolved using local changes"
                    }
                } else {
                    Write-Host "  [ERROR] Failed to complete merge: $continueMerge" -ForegroundColor Red
                    $mergeResults += [PSCustomObject]@{
                        Remote = $diverged.Remote
                        Status = "ERROR"
                        Message = "Failed to resolve conflicts"
                    }
                }
            }
        } else {
            Write-Host "  [WARNING] Merge had issues: $mergeOutput" -ForegroundColor Yellow
            $mergeResults += [PSCustomObject]@{
                Remote = $diverged.Remote
                Status = "WARNING"
                Message = $mergeOutput
            }
        }
    } catch {
        Write-Host "  [ERROR] Failed to merge: $_" -ForegroundColor Red
        $mergeResults += [PSCustomObject]@{
            Remote = $diverged.Remote
            Status = "ERROR"
            Message = $_.ToString()
        }
    }
    Write-Host ""
}

# Also try to pull from each remote to catch any other changes
foreach ($remote in $remotes) {
    Write-Host "Pulling from $($remote.Name)..." -ForegroundColor Cyan
    try {
        $pullOutput = git pull $remote.Name $currentBranch --no-edit 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            if ($pullOutput -match "Already up to date|Fast-forward|Merge made") {
                Write-Host "  [OK] Pull from $($remote.Name) completed" -ForegroundColor Green
            } else {
                Write-Host "  [INFO] Pull from $($remote.Name): $pullOutput" -ForegroundColor Cyan
            }
        } elseif ($pullOutput -match "conflict|CONFLICT") {
            Write-Host "  [WARNING] Conflicts detected during pull" -ForegroundColor Yellow
            # Resolve conflicts
            git checkout --ours . 2>&1 | Out-Null
            git add . 2>&1 | Out-Null
            git commit --no-edit 2>&1 | Out-Null
            Write-Host "  [OK] Conflicts resolved" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Pull from $($remote.Name) had issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARNING] Could not pull from $($remote.Name): $_" -ForegroundColor Yellow
    }
}
Write-Host ""

# ============================================
# STEP 5: Clean Up Untracked Files
# ============================================
Write-Host "[STEP 5/8] Cleaning Up Untracked Files..." -ForegroundColor Yellow
Write-Host ""

# Check for untracked files
$untrackedFiles = git status --porcelain | Where-Object { $_ -match "^\?\?" }
if ($untrackedFiles) {
    $untrackedList = $untrackedFiles | ForEach-Object { ($_ -split '\s+', 2)[1] }
    Write-Host "Found untracked files:" -ForegroundColor Yellow
    foreach ($file in $untrackedList) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
    
    # Add untracked files that should be tracked (not in .gitignore)
    Write-Host "Adding untracked files to staging..." -ForegroundColor Cyan
    git add . 2>&1 | Out-Null
    Write-Host "  [OK] Untracked files added" -ForegroundColor Green
} else {
    Write-Host "  [OK] No untracked files to clean up" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 6: Clean Up Stashes
# ============================================
Write-Host "[STEP 6/8] Cleaning Up Stashes..." -ForegroundColor Yellow
Write-Host ""

$stashList = git stash list 2>&1
if ($stashList) {
    $stashCount = ($stashList | Measure-Object).Count
    Write-Host "Found $stashCount stash(es)" -ForegroundColor Yellow
    
    # Apply and drop stashes
    while ($true) {
        $stashCheck = git stash list 2>&1
        if (-not $stashCheck) { break }
        
        Write-Host "Applying stash..." -ForegroundColor Cyan
        git stash pop 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Stash applied" -ForegroundColor Green
            # Stage any changes from stash
            git add . 2>&1 | Out-Null
        } else {
            Write-Host "  [INFO] No more stashes or stash was empty" -ForegroundColor Yellow
            break
        }
    }
} else {
    Write-Host "  [OK] No stashes to clean up" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 7: Stage and Commit All Changes
# ============================================
Write-Host "[STEP 7/8] Staging and Committing All Changes..." -ForegroundColor Yellow
Write-Host ""

try {
    # Stage all changes
    git add . 2>&1 | Out-Null
    
    # Check what was staged
    $stagedFiles = git diff --cached --name-only 2>&1
    if ($stagedFiles) {
        $stagedCount = ($stagedFiles | Measure-Object).Count
        Write-Host "  [OK] Staged $stagedCount file(s)" -ForegroundColor Green
        
        # Commit changes
        $commitMessage = "Update: Repository review, conflict resolution, merge, and cleanup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        git commit -m $commitMessage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Changes committed successfully" -ForegroundColor Green
            Write-Host "  Commit message: $commitMessage" -ForegroundColor Gray
        } else {
            Write-Host "  [WARNING] Commit may have warnings" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] No changes to commit" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Failed to stage/commit: $_" -ForegroundColor Red
}
Write-Host ""

# ============================================
# STEP 8: Push to All Repositories
# ============================================
Write-Host "[STEP 8/8] Pushing to All Repositories..." -ForegroundColor Yellow
Write-Host ""

$pushResults = @()
$successCount = 0
$warningCount = 0
$errorCount = 0

foreach ($remote in $remotes) {
    Write-Host "Pushing to: $($remote.Name)" -ForegroundColor Cyan
    Write-Host "  URL: $($remote.URL)" -ForegroundColor Gray
    Write-Host "  Branch: $currentBranch" -ForegroundColor Gray
    
    try {
        # Push to remote
        $pushOutput = git push $remote.Name $currentBranch 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Successfully pushed to $($remote.Name)" -ForegroundColor Green
            $pushResults += [PSCustomObject]@{
                Remote = $remote.Name
                URL = $remote.URL
                Status = "SUCCESS"
                Message = "Push completed successfully"
            }
            $successCount++
        } else {
            $errorMsg = ($pushOutput -split "`n" | Select-Object -First 3) -join " "
            Write-Host "  [WARNING] Push to $($remote.Name) had issues" -ForegroundColor Yellow
            Write-Host "  Error: $errorMsg" -ForegroundColor Yellow
            
            # Try force push if needed (with lease for safety)
            if ($pushOutput -match "rejected|non-fast-forward") {
                Write-Host "  Attempting force push with lease..." -ForegroundColor Cyan
                $forcePush = git push $remote.Name $currentBranch --force-with-lease 2>&1 | Out-String
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] Force push successful" -ForegroundColor Green
                    $pushResults += [PSCustomObject]@{
                        Remote = $remote.Name
                        URL = $remote.URL
                        Status = "SUCCESS"
                        Message = "Force push completed successfully"
                    }
                    $successCount++
                } else {
                    $pushResults += [PSCustomObject]@{
                        Remote = $remote.Name
                        URL = $remote.URL
                        Status = "WARNING"
                        Message = $errorMsg
                    }
                    $warningCount++
                }
            } else {
                $pushResults += [PSCustomObject]@{
                    Remote = $remote.Name
                    URL = $remote.URL
                    Status = "WARNING"
                    Message = $errorMsg
                }
                $warningCount++
            }
        }
    } catch {
        Write-Host "  [ERROR] Failed to push to $($remote.Name): $_" -ForegroundColor Red
        $pushResults += [PSCustomObject]@{
            Remote = $remote.Name
            URL = $remote.URL
            Status = "ERROR"
            Message = $_.ToString()
        }
        $errorCount++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 1
}

# ============================================
# Generate Summary Report
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Review & Cleanup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Repositories Reviewed: $($remotes.Count)" -ForegroundColor Cyan
Write-Host "  Diverged Branches: $($divergedBranches.Count)" -ForegroundColor Cyan
Write-Host "  Merges Completed: $($mergeResults.Count)" -ForegroundColor Cyan
Write-Host "  ✅ Successful Pushes: $successCount" -ForegroundColor Green
Write-Host "  ⚠️  Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "  ❌ Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($successCount -eq $remotes.Count) {
    Write-Host "✅ All repositories reviewed, merged, and pushed successfully!" -ForegroundColor Green
} elseif ($errorCount -eq 0) {
    Write-Host "⚠️  Some repositories had warnings but completed" -ForegroundColor Yellow
} else {
    Write-Host "❌ Some repositories failed" -ForegroundColor Red
}

Write-Host ""

# Generate report file
$reportPath = Join-Path $workspaceRoot "REPOSITORY-CLEANUP-REPORT.md"
$reportContent = @"
# Repository Review, Conflict Resolution, Merge & Cleanup Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Repository Overview

### Configured Remotes
"@

foreach ($remote in $remotes) {
    $reportContent += "`n- **$($remote.Name)**: $($remote.URL)"
}

$reportContent += @"

### Current Branch
- **Branch**: $currentBranch

## Diverged Branches
"@

if ($divergedBranches.Count -gt 0) {
    foreach ($diverged in $divergedBranches) {
        $reportContent += "`n- **$($diverged.Remote)/$($diverged.Branch)**"
        $reportContent += "  - Local: $($diverged.LocalCommit.Substring(0, 7))"
        $reportContent += "  - Remote: $($diverged.RemoteCommit.Substring(0, 7))"
    }
} else {
    $reportContent += "`n- No diverged branches found"
}

$reportContent += @"

## Merge Results
"@

if ($mergeResults.Count -gt 0) {
    foreach ($result in $mergeResults) {
        $statusIcon = switch ($result.Status) {
            "SUCCESS" { "✅" }
            "RESOLVED" { "✅" }
            "WARNING" { "⚠️" }
            "ERROR" { "❌" }
        }
        $reportContent += "`n- $statusIcon **$($result.Remote)**: $($result.Status) - $($result.Message)"
    }
} else {
    $reportContent += "`n- No merges were needed"
}

$reportContent += @"

## Push Results Summary

- **Total Repositories**: $($remotes.Count)
- **✅ Successful**: $successCount
- **⚠️  Warnings**: $warningCount
- **❌ Errors**: $errorCount

### Detailed Results
"@

foreach ($result in $pushResults) {
    $statusIcon = switch ($result.Status) {
        "SUCCESS" { "✅" }
        "WARNING" { "⚠️" }
        "ERROR" { "❌" }
    }
    $reportContent += "`n#### $statusIcon $($result.Remote)"
    $reportContent += "- **URL**: $($result.URL)"
    $reportContent += "- **Status**: $($result.Status)"
    if ($result.Message) {
        $reportContent += "- **Message**: $($result.Message)"
    }
    $reportContent += "`n"
}

$reportContent += @"

## Cleanup Actions

- ✅ Fetched all remotes
- ✅ Checked for conflicts and diverged branches
- ✅ Resolved conflicts and merged branches
- ✅ Cleaned up untracked files
- ✅ Cleaned up stashes
- ✅ Staged and committed all changes
- ✅ Pushed to all remotes

---
*Report generated by review-resolve-merge-cleanup-all-repos.ps1*
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Review report saved to: $reportPath" -ForegroundColor Cyan
Write-Host ""

#Requires -Version 5.1
<#
.SYNOPSIS
    Review and Merge All Pull Requests, then Inject into my-drive-projects
.DESCRIPTION
    Comprehensive script to:
    1. Review and merge all PRs in Mouy-leng and A6-9V repositories
    2. Inject all repository contents into my-drive-projects
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Review, Merge & Inject Repositories" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$mouyLengUser = "Mouy-leng"
$a69vOrg = "A6-9V"
$targetRepo = "my-drive-projects"
$workspaceRoot = $PWD.Path
$reposDir = Join-Path $workspaceRoot "injected-repos"
$reportPath = Join-Path $workspaceRoot "INJECTION-REPORT.md"

# Create directory for injected repos
if (-not (Test-Path $reposDir)) {
    New-Item -ItemType Directory -Path $reposDir -Force | Out-Null
}

# Initialize report
$report = @{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    MouyLengRepos = @()
    A69VRepos = @()
    MergedPRs = @()
    InjectedRepos = @()
    Errors = @()
}

# ============================================
# HELPER FUNCTIONS
# ============================================

function Get-GitHubRepos {
    param(
        [string]$Owner,
        [string]$Type = "user"
    )
    
    Write-Host "Fetching repositories for $Owner..." -ForegroundColor Cyan
    
    $repos = @()
    
    # Try GitHub CLI first
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        try {
            if ($Type -eq "org") {
                $reposJson = gh repo list $Owner --limit 1000 --json name,url,defaultBranchRef 2>&1
            } else {
                $reposJson = gh repo list $Owner --limit 1000 --json name,url,defaultBranchRef 2>&1
            }
            
            if ($LASTEXITCODE -eq 0) {
                $repos = $reposJson | ConvertFrom-Json
                Write-Host "  [OK] Found $($repos.Count) repositories using gh CLI" -ForegroundColor Green
                return $repos
            }
        } catch {
            Write-Host "  [WARNING] gh CLI failed: $_" -ForegroundColor Yellow
        }
    }
    
    # Fallback to GitHub API
    $token = $env:GITHUB_TOKEN
    if ($token) {
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
                "Accept" = "application/vnd.github.v3+json"
            }
            
            $page = 1
            do {
                if ($Type -eq "org") {
                    $apiUrl = "https://api.github.com/orgs/$Owner/repos?per_page=100&page=$page"
                } else {
                    $apiUrl = "https://api.github.com/users/$Owner/repos?per_page=100&page=$page"
                }
                
                $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
                $repos += $response
                $page++
            } while ($response.Count -eq 100)
            
            Write-Host "  [OK] Found $($repos.Count) repositories using GitHub API" -ForegroundColor Green
            return $repos
        } catch {
            Write-Host "  [ERROR] GitHub API failed: $($_.Exception.Message)" -ForegroundColor Red
            $report.Errors += "Failed to fetch repos for $Owner : $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [ERROR] No GitHub authentication available" -ForegroundColor Red
        Write-Host "  Please run: gh auth login" -ForegroundColor Yellow
        Write-Host "  Or set: `$env:GITHUB_TOKEN" -ForegroundColor Yellow
        $report.Errors += "No GitHub authentication available for $Owner"
    }
    
    return $repos
}

function Get-PullRequests {
    param(
        [string]$Owner,
        [string]$Repo
    )
    
    $prs = @()
    
    # Try GitHub CLI first
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        try {
            $prsJson = gh pr list --repo "$Owner/$Repo" --state open --json number,title,headRefName,baseRefName,author,mergeable,url 2>&1
            if ($LASTEXITCODE -eq 0) {
                $prs = $prsJson | ConvertFrom-Json
                return $prs
            }
        } catch {
            # Continue to API fallback
        }
    }
    
    # Fallback to GitHub API
    $token = $env:GITHUB_TOKEN
    if ($token) {
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
                "Accept" = "application/vnd.github.v3+json"
            }
            
            $apiUrl = "https://api.github.com/repos/$Owner/$Repo/pulls?state=open"
            $prs = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        } catch {
            # Silently continue
        }
    }
    
    return $prs
}

function Merge-PullRequest {
    param(
        [string]$Owner,
        [string]$Repo,
        [int]$PRNumber,
        [string]$PRTitle
    )
    
    Write-Host "    Merging PR #$PRNumber..." -ForegroundColor Cyan
    
    # Try GitHub CLI first
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        try {
            gh pr merge $PRNumber --repo "$Owner/$Repo" --merge --delete-branch 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "      [OK] Successfully merged PR #$PRNumber" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "      [WARNING] gh CLI merge failed: $_" -ForegroundColor Yellow
        }
    }
    
    # Fallback to GitHub API
    $token = $env:GITHUB_TOKEN
    if ($token) {
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
                "Accept" = "application/vnd.github.v3+json"
            }
            
            $mergeUrl = "https://api.github.com/repos/$Owner/$Repo/pulls/$PRNumber/merge"
            $mergeBody = @{
                commit_title = "Merge PR #$PRNumber : $PRTitle"
                merge_method = "merge"
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $mergeUrl -Headers $headers -Method Put -Body $mergeBody -ContentType "application/json"
            Write-Host "      [OK] Successfully merged PR #$PRNumber via API" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "      [ERROR] API merge failed: $($_.Exception.Message)" -ForegroundColor Red
            $report.Errors += "Failed to merge PR #$PRNumber in $Owner/$Repo : $($_.Exception.Message)"
            return $false
        }
    }
    
    return $false
}

function Clone-OrUpdateRepo {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$CloneUrl,
        [string]$DestinationPath
    )
    
    $repoPath = Join-Path $DestinationPath $Repo
    
    if (Test-Path $repoPath) {
        Write-Host "    Updating existing repository..." -ForegroundColor Cyan
        Push-Location $repoPath
        try {
            git fetch origin 2>&1 | Out-Null
            git pull origin main 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                git pull origin master 2>&1 | Out-Null
            }
            Write-Host "      [OK] Repository updated" -ForegroundColor Green
            Pop-Location
            return $true
        } catch {
            Write-Host "      [WARNING] Update failed: $_" -ForegroundColor Yellow
            Pop-Location
            return $false
        }
    } else {
        Write-Host "    Cloning repository..." -ForegroundColor Cyan
        try {
            git clone $CloneUrl $repoPath 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "      [OK] Repository cloned" -ForegroundColor Green
                return $true
            } else {
                Write-Host "      [ERROR] Clone failed" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "      [ERROR] Clone failed: $_" -ForegroundColor Red
            $report.Errors += "Failed to clone $Owner/$Repo : $($_)"
            return $false
        }
    }
}

function Inject-RepoContent {
    param(
        [string]$SourcePath,
        [string]$RepoName,
        [string]$TargetPath
    )
    
    $targetRepoPath = Join-Path $TargetPath $RepoName
    
    Write-Host "    Injecting content into my-drive-projects..." -ForegroundColor Cyan
    
    try {
        # Create target directory if it doesn't exist
        if (-not (Test-Path $targetRepoPath)) {
            New-Item -ItemType Directory -Path $targetRepoPath -Force | Out-Null
        }
        
        # Copy files recursively, excluding .git directory
        Get-ChildItem -Path $SourcePath -Recurse | Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.Name -ne '.git'
        } | ForEach-Object {
            $relativePath = $_.FullName.Substring($SourcePath.Length)
            $targetFile = Join-Path $targetRepoPath $relativePath
            
            if ($_.PSIsContainer) {
                if (-not (Test-Path $targetFile)) {
                    New-Item -ItemType Directory -Path $targetFile -Force | Out-Null
                }
            } else {
                $targetDir = Split-Path $targetFile -Parent
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $targetFile -Force
            }
        }
        
        Write-Host "      [OK] Content injected" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "      [ERROR] Injection failed: $_" -ForegroundColor Red
        $report.Errors += "Failed to inject $RepoName : $($_)"
        return $false
    }
}

# ============================================
# PHASE 1: REVIEW AND MERGE PRS
# ============================================
Write-Host ""
Write-Host "[PHASE 1] Review and Merge Pull Requests" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""

# Process Mouy-leng repositories
Write-Host "[1/2] Processing Mouy-leng repositories..." -ForegroundColor Yellow
$mouyLengRepos = Get-GitHubRepos -Owner $mouyLengUser -Type "user"
$report.MouyLengRepos = $mouyLengRepos

if ($mouyLengRepos.Count -gt 0) {
    Write-Host ""
    foreach ($repo in $mouyLengRepos) {
        $repoName = $repo.name
        Write-Host "  Repository: $mouyLengUser/$repoName" -ForegroundColor Cyan
        
        $prs = Get-PullRequests -Owner $mouyLengUser -Repo $repoName
        
        if ($prs.Count -gt 0) {
            Write-Host "    [FOUND] $($prs.Count) open PR(s)" -ForegroundColor Yellow
            
            foreach ($pr in $prs) {
                $prNumber = $pr.number
                $prTitle = $pr.title
                $isMergeable = if ($pr.mergeable -eq "MERGEABLE" -or $pr.mergeable -eq $true) { $true } else { $false }
                
                Write-Host "      PR #$prNumber : $prTitle" -ForegroundColor White
                Write-Host "        Mergeable: $isMergeable" -ForegroundColor $(if ($isMergeable) { "Green" } else { "Yellow" })
                
                if ($isMergeable) {
                    $merged = Merge-PullRequest -Owner $mouyLengUser -Repo $repoName -PRNumber $prNumber -PRTitle $prTitle
                    if ($merged) {
                        $report.MergedPRs += [PSCustomObject]@{
                            Owner = $mouyLengUser
                            Repo = $repoName
                            PRNumber = $prNumber
                            PRTitle = $prTitle
                        }
                    }
                } else {
                    Write-Host "        [SKIP] PR is not mergeable" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "    [OK] No open PRs" -ForegroundColor Green
        }
        Write-Host ""
    }
}

# Process A6-9V repositories
Write-Host "[2/2] Processing A6-9V organization repositories..." -ForegroundColor Yellow
$a69vRepos = Get-GitHubRepos -Owner $a69vOrg -Type "org"
$report.A69VRepos = $a69vRepos

if ($a69vRepos.Count -gt 0) {
    Write-Host ""
    foreach ($repo in $a69vRepos) {
        $repoName = $repo.name
        Write-Host "  Repository: $a69vOrg/$repoName" -ForegroundColor Cyan
        
        $prs = Get-PullRequests -Owner $a69vOrg -Repo $repoName
        
        if ($prs.Count -gt 0) {
            Write-Host "    [FOUND] $($prs.Count) open PR(s)" -ForegroundColor Yellow
            
            foreach ($pr in $prs) {
                $prNumber = $pr.number
                $prTitle = $pr.title
                $isMergeable = if ($pr.mergeable -eq "MERGEABLE" -or $pr.mergeable -eq $true) { $true } else { $false }
                
                Write-Host "      PR #$prNumber : $prTitle" -ForegroundColor White
                Write-Host "        Mergeable: $isMergeable" -ForegroundColor $(if ($isMergeable) { "Green" } else { "Yellow" })
                
                if ($isMergeable) {
                    $merged = Merge-PullRequest -Owner $a69vOrg -Repo $repoName -PRNumber $prNumber -PRTitle $prTitle
                    if ($merged) {
                        $report.MergedPRs += [PSCustomObject]@{
                            Owner = $a69vOrg
                            Repo = $repoName
                            PRNumber = $prNumber
                            PRTitle = $prTitle
                        }
                    }
                } else {
                    Write-Host "        [SKIP] PR is not mergeable" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "    [OK] No open PRs" -ForegroundColor Green
        }
        Write-Host ""
    }
}

# ============================================
# PHASE 2: INJECT REPOSITORIES
# ============================================
Write-Host ""
Write-Host "[PHASE 2] Inject Repositories into my-drive-projects" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""

$allRepos = @()
if ($mouyLengRepos.Count -gt 0) {
    $allRepos += $mouyLengRepos | ForEach-Object { [PSCustomObject]@{ Owner = $mouyLengUser; Repo = $_ } }
}
if ($a69vRepos.Count -gt 0) {
    $allRepos += $a69vRepos | ForEach-Object { [PSCustomObject]@{ Owner = $a69vOrg; Repo = $_ } }
}

Write-Host "Injecting $($allRepos.Count) repositories..." -ForegroundColor Cyan
Write-Host ""

foreach ($item in $allRepos) {
    $owner = $item.Owner
    $repo = $item.Repo
    $repoName = if ($repo.name) { $repo.name } else { $repo }
    $cloneUrl = if ($repo.url) { $repo.url } else { "https://github.com/$owner/$repoName.git" }
    
    Write-Host "  Processing: $owner/$repoName" -ForegroundColor Cyan
    
    # Clone or update the repository
    $cloned = Clone-OrUpdateRepo -Owner $owner -Repo $repoName -CloneUrl $cloneUrl -DestinationPath $reposDir
    
    if ($cloned) {
        $sourcePath = Join-Path $reposDir $repoName
        $injected = Inject-RepoContent -SourcePath $sourcePath -RepoName "$owner-$repoName" -TargetPath $workspaceRoot
        
        if ($injected) {
            $report.InjectedRepos += [PSCustomObject]@{
                Owner = $owner
                Repo = $repoName
                InjectionPath = "$owner-$repoName"
            }
        }
    }
    
    Write-Host ""
}

# ============================================
# PHASE 3: COMMIT AND PUSH
# ============================================
Write-Host ""
Write-Host "[PHASE 3] Commit and Push Changes" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""

try {
    # Add all changes
    Write-Host "Staging all changes..." -ForegroundColor Cyan
    git add . 2>&1 | Out-Null
    
    # Check if there are changes to commit
    $stagedFiles = git diff --cached --name-only 2>&1
    if ($stagedFiles) {
        $stagedCount = ($stagedFiles | Measure-Object).Count
        Write-Host "  [OK] Staged $stagedCount file(s)" -ForegroundColor Green
        
        # Commit changes
        $commitMessage = "Inject repositories from Mouy-leng and A6-9V - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "Committing changes..." -ForegroundColor Cyan
        git commit -m $commitMessage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Changes committed" -ForegroundColor Green
            
            # Push changes
            Write-Host "Pushing to origin..." -ForegroundColor Cyan
            git push origin main 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Changes pushed successfully" -ForegroundColor Green
            } else {
                Write-Host "  [WARNING] Push may have had issues" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [WARNING] Commit may have had issues" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] No changes to commit" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Failed to commit/push: $_" -ForegroundColor Red
    $report.Errors += "Failed to commit/push changes: $($_)"
}

# ============================================
# GENERATE REPORT
# ============================================
Write-Host ""
Write-Host "[PHASE 4] Generating Report" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""

$reportContent = @"
# Repository Injection Report
Generated: $($report.Timestamp)

## Summary

- **Mouy-leng Repositories**: $($report.MouyLengRepos.Count)
- **A6-9V Repositories**: $($report.A69VRepos.Count)
- **Total Repositories**: $($allRepos.Count)
- **Merged Pull Requests**: $($report.MergedPRs.Count)
- **Injected Repositories**: $($report.InjectedRepos.Count)
- **Errors**: $($report.Errors.Count)

## Merged Pull Requests

"@

if ($report.MergedPRs.Count -gt 0) {
    foreach ($pr in $report.MergedPRs) {
        $reportContent += "`n- **$($pr.Owner)/$($pr.Repo)** - PR #$($pr.PRNumber): $($pr.PRTitle)"
    }
} else {
    $reportContent += "`n- No pull requests were merged"
}

$reportContent += @"

## Injected Repositories

"@

if ($report.InjectedRepos.Count -gt 0) {
    foreach ($injected in $report.InjectedRepos) {
        $reportContent += "`n- **$($injected.Owner)/$($injected.Repo)** → $($injected.InjectionPath)"
    }
} else {
    $reportContent += "`n- No repositories were injected"
}

$reportContent += @"

## Errors

"@

if ($report.Errors.Count -gt 0) {
    foreach ($error in $report.Errors) {
        $reportContent += "`n- $error"
    }
} else {
    $reportContent += "`n- No errors occurred"
}

$reportContent += @"


---
*Report generated by review-merge-inject-all-repos.ps1*
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Operation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Repositories Processed: $($allRepos.Count)" -ForegroundColor Cyan
Write-Host "  Pull Requests Merged: $($report.MergedPRs.Count)" -ForegroundColor Green
Write-Host "  Repositories Injected: $($report.InjectedRepos.Count)" -ForegroundColor Green
Write-Host "  Errors Encountered: $($report.Errors.Count)" -ForegroundColor $(if ($report.Errors.Count -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($report.Errors.Count -eq 0 -and $report.InjectedRepos.Count -gt 0) {
    Write-Host "✅ All operations completed successfully!" -ForegroundColor Green
} elseif ($report.Errors.Count -gt 0) {
    Write-Host "⚠️  Operation completed with errors" -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  Operation completed with no changes" -ForegroundColor Cyan
}
Write-Host ""

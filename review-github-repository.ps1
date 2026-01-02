#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive GitHub Repository Review Toolbox
.DESCRIPTION
    Reviews GitHub repository status, branches, pull requests, issues, and makes recommendations
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Repository Review Toolbox" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get repository info
$remoteUrl = git remote get-url origin 2>&1
if ($remoteUrl -match "github\.com/([^/]+)/([^/]+)") {
    $owner = $matches[1]
    $repo = $matches[2] -replace '\.git$', ''
    
    Write-Host "Repository: $owner/$repo" -ForegroundColor Cyan
    Write-Host "Remote URL: $remoteUrl" -ForegroundColor Gray
    Write-Host ""
    
    $reviewResults = @{
        Repository = "$owner/$repo"
        RemoteUrl = $remoteUrl
        Status = "REVIEWED"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Findings = @()
        Recommendations = @()
        Actions = @()
    }
    
    # ============================================
    # 1. Local Repository Status
    # ============================================
    Write-Host "[1/7] Reviewing Local Repository Status..." -ForegroundColor Yellow
    Write-Host ""
    
    $currentBranch = git branch --show-current 2>&1
    $status = git status --porcelain 2>&1
    $modifiedFiles = ($status | Where-Object { $_ -match "^ M" }).Count
    $untrackedFiles = ($status | Where-Object { $_ -match "^\?\?" }).Count
    $stagedFiles = ($status | Where-Object { $_ -match "^M " }).Count
    
    Write-Host "  Current Branch: $currentBranch" -ForegroundColor Cyan
    Write-Host "  Modified Files: $modifiedFiles" -ForegroundColor $(if ($modifiedFiles -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  Staged Files: $stagedFiles" -ForegroundColor $(if ($stagedFiles -gt 0) { "Cyan" } else { "Gray" })
    Write-Host "  Untracked Files: $untrackedFiles" -ForegroundColor $(if ($untrackedFiles -gt 0) { "Yellow" } else { "Green" })
    
    if ($modifiedFiles -gt 0 -or $untrackedFiles -gt 0) {
        $reviewResults.Findings += "Uncommitted changes detected: $modifiedFiles modified, $untrackedFiles untracked"
        $reviewResults.Recommendations += "Stage and commit pending changes"
        $reviewResults.Actions += "git add . && git commit -m 'Update: Repository changes'"
    } else {
        Write-Host "  [OK] Working directory is clean" -ForegroundColor Green
    }
    Write-Host ""
    
    # ============================================
    # 2. Branch Review
    # ============================================
    Write-Host "[2/7] Reviewing Branches..." -ForegroundColor Yellow
    Write-Host ""
    
    $localBranches = git branch --format="%(refname:short)" 2>&1
    $remoteBranches = git branch -r --format="%(refname:short)" 2>&1 | Where-Object { $_ -notmatch "HEAD" }
    
    Write-Host "  Local Branches: $($localBranches.Count)" -ForegroundColor Cyan
    foreach ($branch in $localBranches) {
        $isCurrent = $branch -eq $currentBranch
        $marker = if ($isCurrent) { "*" } else { " " }
        Write-Host "    $marker $branch" -ForegroundColor $(if ($isCurrent) { "Green" } else { "White" })
    }
    
    Write-Host ""
    Write-Host "  Remote Branches: $($remoteBranches.Count)" -ForegroundColor Cyan
    $cursorBranches = $remoteBranches | Where-Object { $_ -match "cursor" }
    if ($cursorBranches.Count -gt 0) {
        Write-Host "    Found $($cursorBranches.Count) Cursor-generated branch(es):" -ForegroundColor Yellow
        foreach ($branch in $cursorBranches) {
            Write-Host "      - $branch" -ForegroundColor Gray
        }
        $reviewResults.Findings += "Found $($cursorBranches.Count) Cursor-generated branches that may need cleanup"
        $reviewResults.Recommendations += "Review and delete merged Cursor branches"
    }
    Write-Host ""
    
    # ============================================
    # 3. Commit History Review
    # ============================================
    Write-Host "[3/7] Reviewing Recent Commits..." -ForegroundColor Yellow
    Write-Host ""
    
    $recentCommits = git log --oneline -10 2>&1
    Write-Host "  Recent Commits (last 10):" -ForegroundColor Cyan
    $commitCount = 0
    foreach ($commit in $recentCommits) {
        $commitCount++
        if ($commit -match "Merge pull request") {
            Write-Host "    $commit" -ForegroundColor Green
        } else {
            Write-Host "    $commit" -ForegroundColor White
        }
    }
    
    $mergedPRs = ($recentCommits | Where-Object { $_ -match "Merge pull request" }).Count
    if ($mergedPRs -gt 0) {
        Write-Host ""
        Write-Host "  [INFO] Found $mergedPRs merged pull request(s) in recent history" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # ============================================
    # 4. Check for Open Pull Requests
    # ============================================
    Write-Host "[4/7] Checking for Open Pull Requests..." -ForegroundColor Yellow
    Write-Host ""
    
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    $token = $env:GITHUB_TOKEN
    
    if ($ghAvailable) {
        try {
            Write-Host "  Using GitHub CLI..." -ForegroundColor Cyan
            $prs = gh pr list --repo "$owner/$repo" --state open --json number,title,headRefName,baseRefName,author,state,createdAt 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $prs) {
                $prList = $prs | ConvertFrom-Json
                
                if ($prList.Count -gt 0) {
                    Write-Host "  Found $($prList.Count) open pull request(s):" -ForegroundColor Yellow
                    Write-Host ""
                    
                    foreach ($pr in $prList) {
                        $createdDate = [DateTime]::Parse($pr.createdAt)
                        $age = (Get-Date) - $createdDate
                        $ageDays = [math]::Round($age.TotalDays, 1)
                        
                        Write-Host "    PR #$($pr.number): $($pr.title)" -ForegroundColor Yellow
                        Write-Host "      From: $($pr.headRefName) → $($pr.baseRefName)" -ForegroundColor Gray
                        Write-Host "      Author: $($pr.author.login)" -ForegroundColor Gray
                        Write-Host "      Age: $ageDays days" -ForegroundColor $(if ($ageDays -gt 7) { "Yellow" } else { "Gray" })
                        
                        $reviewResults.Findings += "Open PR #$($pr.number): $($pr.title) (Age: $ageDays days)"
                        $reviewResults.Recommendations += "Review and merge PR #$($pr.number)"
                        $reviewResults.Actions += "gh pr merge $($pr.number) --repo $owner/$repo --merge"
                    }
                } else {
                    Write-Host "  [OK] No open pull requests" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "  [WARNING] Could not check PRs via GitHub CLI: $_" -ForegroundColor Yellow
        }
    } elseif ($token) {
        try {
            Write-Host "  Using GitHub API..." -ForegroundColor Cyan
            $headers = @{
                "Authorization" = "token $token"
                "Accept" = "application/vnd.github.v3+json"
            }
            
            $apiUrl = "https://api.github.com/repos/$owner/$repo/pulls?state=open"
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            
            if ($response.Count -gt 0) {
                Write-Host "  Found $($response.Count) open pull request(s):" -ForegroundColor Yellow
                foreach ($pr in $response) {
                    Write-Host "    PR #$($pr.number): $($pr.title)" -ForegroundColor Yellow
                    $reviewResults.Findings += "Open PR #$($pr.number): $($pr.title)"
                    $reviewResults.Recommendations += "Review and merge PR #$($pr.number)"
                }
            } else {
                Write-Host "  [OK] No open pull requests" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [WARNING] Could not check PRs via API: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] GitHub CLI not available and GITHUB_TOKEN not set" -ForegroundColor Yellow
        Write-Host "    Install GitHub CLI: winget install --id GitHub.cli" -ForegroundColor Gray
        Write-Host "    Or set GITHUB_TOKEN environment variable" -ForegroundColor Gray
    }
    Write-Host ""
    
    # ============================================
    # 5. Check for Issues
    # ============================================
    Write-Host "[5/7] Checking for Open Issues..." -ForegroundColor Yellow
    Write-Host ""
    
    if ($ghAvailable) {
        try {
            $issues = gh issue list --repo "$owner/$repo" --state open --json number,title,author,createdAt,labels 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $issues) {
                $issueList = $issues | ConvertFrom-Json
                
                if ($issueList.Count -gt 0) {
                    Write-Host "  Found $($issueList.Count) open issue(s):" -ForegroundColor Yellow
                    foreach ($issue in $issueList) {
                        $labels = ($issue.labels | ForEach-Object { $_.name }) -join ", "
                        Write-Host "    Issue #$($issue.number): $($issue.title)" -ForegroundColor Yellow
                        if ($labels) {
                            Write-Host "      Labels: $labels" -ForegroundColor Gray
                        }
                        $reviewResults.Findings += "Open Issue #$($issue.number): $($issue.title)"
                        $reviewResults.Recommendations += "Address Issue #$($issue.number)"
                    }
                } else {
                    Write-Host "  [OK] No open issues" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "  [INFO] Could not check issues" -ForegroundColor Yellow
        }
    } elseif ($token) {
        try {
            $apiUrl = "https://api.github.com/repos/$owner/$repo/issues?state=open"
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            
            $issues = $response | Where-Object { -not $_.pull_request }
            if ($issues.Count -gt 0) {
                Write-Host "  Found $($issues.Count) open issue(s):" -ForegroundColor Yellow
                foreach ($issue in $issues) {
                    Write-Host "    Issue #$($issue.number): $($issue.title)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [OK] No open issues" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [INFO] Could not check issues via API" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    
    # ============================================
    # 6. Repository Health Check
    # ============================================
    Write-Host "[6/7] Repository Health Check..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if .gitignore exists
    if (Test-Path ".gitignore") {
        Write-Host "  [OK] .gitignore exists" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] .gitignore not found" -ForegroundColor Yellow
        $reviewResults.Recommendations += "Create .gitignore file"
    }
    
    # Check if README exists
    if (Test-Path "README.md") {
        Write-Host "  [OK] README.md exists" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] README.md not found" -ForegroundColor Yellow
        $reviewResults.Recommendations += "Create README.md file"
    }
    
    # Check repository size
    $repoSize = (Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $repoSizeGB = [math]::Round($repoSize / 1GB, 2)
    Write-Host "  Repository Size: $repoSizeGB GB" -ForegroundColor Cyan
    
    if ($repoSizeGB -gt 1) {
        Write-Host "  [WARNING] Repository is large (>1GB)" -ForegroundColor Yellow
        $reviewResults.Recommendations += "Consider using Git LFS for large files"
    }
    Write-Host ""
    
    # ============================================
    # 7. Generate Recommendations
    # ============================================
    Write-Host "[7/7] Generating Recommendations..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Review Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($reviewResults.Findings.Count -gt 0) {
        Write-Host "Findings:" -ForegroundColor Yellow
        foreach ($finding in $reviewResults.Findings) {
            Write-Host "  • $finding" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($reviewResults.Recommendations.Count -gt 0) {
        Write-Host "Recommendations:" -ForegroundColor Cyan
        foreach ($rec in $reviewResults.Recommendations) {
            Write-Host "  • $rec" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($reviewResults.Actions.Count -gt 0) {
        Write-Host "Suggested Actions:" -ForegroundColor Green
        foreach ($action in $reviewResults.Actions) {
            Write-Host "  $action" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Save review report
    $reportPath = "GITHUB-REVIEW-REPORT-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $reviewResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Review report saved to: $reportPath" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "[ERROR] Could not determine repository owner and name" -ForegroundColor Red
    Write-Host "Remote URL: $remoteUrl" -ForegroundColor Gray
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Review Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


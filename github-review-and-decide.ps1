#Requires -Version 5.1
<#
.SYNOPSIS
    GitHub Repository Review and Decision Toolbox
.DESCRIPTION
    Comprehensive review of GitHub repository with actionable decisions
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Repository Review & Decision" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get repository info
$remoteUrl = git remote get-url origin 2>&1
if ($remoteUrl -match "github\.com/([^/]+)/([^/]+)") {
    $owner = $matches[1]
    $repo = $matches[2] -replace '\.git$', ''
    
    Write-Host "Repository: $owner/$repo" -ForegroundColor Cyan
    Write-Host "URL: https://github.com/$owner/$repo" -ForegroundColor Gray
    Write-Host ""
    
    # ============================================
    # 1. Repository Status
    # ============================================
    Write-Host "[REVIEW 1] Repository Status" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $currentBranch = git branch --show-current 2>&1
    $status = git status --porcelain 2>&1
    $modified = ($status | Where-Object { $_ -match "^ M" }).Count
    $untracked = ($status | Where-Object { $_ -match "^\?\?" }).Count
    
    Write-Host "  Branch: $currentBranch" -ForegroundColor Cyan
    Write-Host "  Modified: $modified files" -ForegroundColor $(if ($modified -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  Untracked: $untracked files" -ForegroundColor $(if ($untracked -gt 0) { "Yellow" } else { "Green" })
    
    $decisions = @()
    if ($modified -gt 0 -or $untracked -gt 0) {
        Write-Host "  [ACTION NEEDED] Uncommitted changes detected" -ForegroundColor Yellow
        $decisions += "COMMIT_CHANGES"
    }
    Write-Host ""
    
    # ============================================
    # 2. Branch Analysis
    # ============================================
    Write-Host "[REVIEW 2] Branch Analysis" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $remoteBranches = git branch -r --format="%(refname:short)" 2>&1 | Where-Object { $_ -notmatch "HEAD" }
    $cursorBranches = $remoteBranches | Where-Object { $_ -match "cursor" }
    $copilotBranches = $remoteBranches | Where-Object { $_ -match "copilot" }
    
    Write-Host "  Total Remote Branches: $($remoteBranches.Count)" -ForegroundColor Cyan
    Write-Host "  Cursor Branches: $($cursorBranches.Count)" -ForegroundColor Yellow
    Write-Host "  Copilot Branches: $($copilotBranches.Count)" -ForegroundColor Yellow
    
    # Check which branches are merged
    Write-Host ""
    Write-Host "  Checking merged branches..." -ForegroundColor Cyan
    $mergedBranches = @()
    foreach ($branch in $remoteBranches) {
        $branchName = $branch -replace "origin/", ""
        $isMerged = git branch -r --merged main 2>&1 | Select-String -Pattern $branch
        if ($isMerged -and $branch -ne "origin/main") {
            $mergedBranches += $branch
        }
    }
    
    if ($mergedBranches.Count -gt 0) {
        Write-Host "  [FOUND] $($mergedBranches.Count) merged branch(es) that can be deleted:" -ForegroundColor Yellow
        foreach ($branch in $mergedBranches | Select-Object -First 10) {
            Write-Host "    - $branch" -ForegroundColor Gray
        }
        if ($mergedBranches.Count -gt 10) {
            Write-Host "    ... and $($mergedBranches.Count - 10) more" -ForegroundColor Gray
        }
        $decisions += "CLEANUP_MERGED_BRANCHES"
    } else {
        Write-Host "  [OK] No merged branches to clean up" -ForegroundColor Green
    }
    Write-Host ""
    
    # ============================================
    # 3. Pull Requests Check
    # ============================================
    Write-Host "[REVIEW 3] Pull Requests" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    $token = $env:GITHUB_TOKEN
    
    if ($ghAvailable) {
        try {
            $prs = gh pr list --repo "$owner/$repo" --state open --json number,title,headRefName,baseRefName,author,createdAt,mergeable 2>&1 | ConvertFrom-Json
            
            if ($prs.Count -gt 0) {
                Write-Host "  [FOUND] $($prs.Count) open pull request(s):" -ForegroundColor Yellow
                foreach ($pr in $prs) {
                    $createdDate = [DateTime]::Parse($pr.createdAt)
                    $age = (Get-Date) - $createdDate
                    $ageDays = [math]::Round($age.TotalDays, 1)
                    
                    Write-Host ""
                    Write-Host "    PR #$($pr.number): $($pr.title)" -ForegroundColor Cyan
                    Write-Host "      Branch: $($pr.headRefName) → $($pr.baseRefName)" -ForegroundColor Gray
                    Write-Host "      Author: $($pr.author.login)" -ForegroundColor Gray
                    Write-Host "      Age: $ageDays days" -ForegroundColor $(if ($ageDays -gt 7) { "Yellow" } else { "Gray" })
                    Write-Host "      Mergeable: $($pr.mergeable)" -ForegroundColor $(if ($pr.mergeable -eq "MERGEABLE") { "Green" } else { "Yellow" })
                    
                    if ($pr.mergeable -eq "MERGEABLE") {
                        $decisions += "MERGE_PR_$($pr.number)"
                    }
                }
            } else {
                Write-Host "  [OK] No open pull requests" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [INFO] Could not check PRs: $_" -ForegroundColor Yellow
        }
    } elseif ($token) {
        try {
            $headers = @{
                "Authorization" = "token $token"
                "Accept" = "application/vnd.github.v3+json"
            }
            $apiUrl = "https://api.github.com/repos/$owner/$repo/pulls?state=open"
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            
            if ($response.Count -gt 0) {
                Write-Host "  [FOUND] $($response.Count) open pull request(s)" -ForegroundColor Yellow
                foreach ($pr in $response) {
                    Write-Host "    PR #$($pr.number): $($pr.title)" -ForegroundColor Cyan
                    if ($pr.mergeable) {
                        $decisions += "MERGE_PR_$($pr.number)"
                    }
                }
            } else {
                Write-Host "  [OK] No open pull requests" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [INFO] Could not check PRs via API" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] Install GitHub CLI or set GITHUB_TOKEN to check PRs" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # ============================================
    # 4. Issues Check
    # ============================================
    Write-Host "[REVIEW 4] Issues" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    if ($ghAvailable) {
        try {
            $issues = gh issue list --repo "$owner/$repo" --state open --json number,title,author,createdAt,labels 2>&1 | ConvertFrom-Json
            
            if ($issues.Count -gt 0) {
                Write-Host "  [FOUND] $($issues.Count) open issue(s):" -ForegroundColor Yellow
                foreach ($issue in $issues) {
                    Write-Host "    Issue #$($issue.number): $($issue.title)" -ForegroundColor Cyan
                    $decisions += "REVIEW_ISSUE_$($issue.number)"
                }
            } else {
                Write-Host "  [OK] No open issues" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [INFO] Could not check issues" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    
    # ============================================
    # 5. Repository Health
    # ============================================
    Write-Host "[REVIEW 5] Repository Health" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $hasGitignore = Test-Path ".gitignore"
    $hasReadme = Test-Path "README.md"
    
    Write-Host "  .gitignore: $(if ($hasGitignore) { '[OK]' } else { '[MISSING]' })" -ForegroundColor $(if ($hasGitignore) { "Green" } else { "Yellow" })
    Write-Host "  README.md: $(if ($hasReadme) { '[OK]' } else { '[MISSING]' })" -ForegroundColor $(if ($hasReadme) { "Green" } else { "Yellow" })
    
    if (-not $hasGitignore) {
        $decisions += "CREATE_GITIGNORE"
    }
    if (-not $hasReadme) {
        $decisions += "CREATE_README"
    }
    Write-Host ""
    
    # ============================================
    # DECISION SUMMARY
    # ============================================
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  DECISION SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($decisions.Count -eq 0) {
        Write-Host "✅ [OK] No actions needed - repository is in good shape!" -ForegroundColor Green
    } else {
        Write-Host "📋 [ACTIONS NEEDED] Found $($decisions.Count) recommended action(s):" -ForegroundColor Yellow
        Write-Host ""
        
        $actionPlan = @()
        
        foreach ($decision in $decisions) {
            switch ($decision) {
                "COMMIT_CHANGES" {
                    Write-Host "  1. [COMMIT] Stage and commit pending changes" -ForegroundColor Cyan
                    $actionPlan += "git add . && git commit -m 'Update: Repository changes' && git push origin main"
                }
                "CLEANUP_MERGED_BRANCHES" {
                    Write-Host "  2. [CLEANUP] Delete $($mergedBranches.Count) merged branch(es)" -ForegroundColor Cyan
                    $actionPlan += "Delete merged branches: $($mergedBranches.Count) branches"
                }
                { $_ -match "^MERGE_PR_" } {
                    $prNum = $_ -replace "MERGE_PR_", ""
                    Write-Host "  3. [MERGE] Merge PR #$prNum" -ForegroundColor Cyan
                    if ($ghAvailable) {
                        $actionPlan += "gh pr merge $prNum --repo $owner/$repo --merge"
                    } else {
                        $actionPlan += "Merge PR #$prNum via GitHub web interface"
                    }
                }
                { $_ -match "^REVIEW_ISSUE_" } {
                    $issueNum = $_ -replace "REVIEW_ISSUE_", ""
                    Write-Host "  4. [REVIEW] Review Issue #$issueNum" -ForegroundColor Cyan
                    $actionPlan += "Review and address Issue #$issueNum"
                }
                "CREATE_GITIGNORE" {
                    Write-Host "  5. [CREATE] Create .gitignore file" -ForegroundColor Cyan
                    $actionPlan += "Create .gitignore file"
                }
                "CREATE_README" {
                    Write-Host "  6. [CREATE] Create README.md file" -ForegroundColor Cyan
                    $actionPlan += "Create README.md file"
                }
            }
        }
        
        Write-Host ""
        Write-Host "Recommended Action Plan:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $actionPlan.Count; $i++) {
            Write-Host "  $($i + 1). $($actionPlan[$i])" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "[ERROR] Could not determine repository info" -ForegroundColor Red
}


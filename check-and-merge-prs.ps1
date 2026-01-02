#Requires -Version 5.1
<#
.SYNOPSIS
    Check and Merge Pull Requests
.DESCRIPTION
    Checks for open pull requests and merges them automatically
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Check and Merge Pull Requests" -ForegroundColor Cyan
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
    
    # Check if GitHub CLI is available
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        Write-Host "[1/3] Checking for pull requests using GitHub CLI..." -ForegroundColor Yellow
        
        try {
            # List open pull requests
            $prs = gh pr list --repo "$owner/$repo" --state open --json number,title,headRefName,baseRefName,author 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $prs) {
                $prList = $prs | ConvertFrom-Json
                
                if ($prList.Count -gt 0) {
                    Write-Host "  Found $($prList.Count) open pull request(s):" -ForegroundColor Cyan
                    Write-Host ""
                    
                    foreach ($pr in $prList) {
                        Write-Host "  PR #$($pr.number): $($pr.title)" -ForegroundColor Yellow
                        Write-Host "    From: $($pr.headRefName) → $($pr.baseRefName)" -ForegroundColor Gray
                        Write-Host "    Author: $($pr.author.login)" -ForegroundColor Gray
                        
                        # Merge the pull request
                        Write-Host "    Merging..." -ForegroundColor Cyan
                        $mergeResult = gh pr merge $pr.number --repo "$owner/$repo" --merge --delete-branch 2>&1
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "    [OK] Successfully merged PR #$($pr.number)" -ForegroundColor Green
                        } else {
                            Write-Host "    [WARNING] Could not merge PR #$($pr.number)" -ForegroundColor Yellow
                            Write-Host "    Error: $mergeResult" -ForegroundColor Yellow
                        }
                        Write-Host ""
                    }
                } else {
                    Write-Host "  [OK] No open pull requests found" -ForegroundColor Green
                }
            } else {
                Write-Host "  [INFO] No open pull requests or error checking PRs" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [ERROR] Failed to check pull requests: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "[1/3] GitHub CLI not available" -ForegroundColor Yellow
        Write-Host "  Install GitHub CLI to check and merge pull requests:" -ForegroundColor Gray
        Write-Host "  winget install --id GitHub.cli" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "[2/3] Attempting to check via GitHub API..." -ForegroundColor Yellow
        
        # Try using GitHub API (requires token)
        $token = $env:GITHUB_TOKEN
        if (-not $token) {
            Write-Host "  [WARNING] GITHUB_TOKEN environment variable not set" -ForegroundColor Yellow
            Write-Host "  Set GITHUB_TOKEN to use GitHub API for PR checks" -ForegroundColor Gray
        } else {
            try {
                $headers = @{
                    "Authorization" = "token $token"
                    "Accept" = "application/vnd.github.v3+json"
                }
                
                $apiUrl = "https://api.github.com/repos/$owner/$repo/pulls?state=open"
                $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
                
                if ($response.Count -gt 0) {
                    Write-Host "  Found $($response.Count) open pull request(s):" -ForegroundColor Cyan
                    Write-Host ""
                    
                    foreach ($pr in $response) {
                        Write-Host "  PR #$($pr.number): $($pr.title)" -ForegroundColor Yellow
                        Write-Host "    From: $($pr.head.ref) → $($pr.base.ref)" -ForegroundColor Gray
                        Write-Host "    Author: $($pr.user.login)" -ForegroundColor Gray
                        
                        # Merge via API
                        Write-Host "    Merging..." -ForegroundColor Cyan
                        $mergeUrl = "https://api.github.com/repos/$owner/$repo/pulls/$($pr.number)/merge"
                        $mergeBody = @{
                            commit_title = "Merge PR #$($pr.number): $($pr.title)"
                            merge_method = "merge"
                        } | ConvertTo-Json
                        
                        try {
                            $mergeResponse = Invoke-RestMethod -Uri $mergeUrl -Headers $headers -Method Put -Body $mergeBody -ContentType "application/json"
                            Write-Host "    [OK] Successfully merged PR #$($pr.number)" -ForegroundColor Green
                        } catch {
                            Write-Host "    [WARNING] Could not merge PR #$($pr.number)" -ForegroundColor Yellow
                            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Yellow
                        }
                        Write-Host ""
                    }
                } else {
                    Write-Host "  [OK] No open pull requests found" -ForegroundColor Green
                }
            } catch {
                Write-Host "  [ERROR] Failed to check pull requests via API: $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "[3/3] Pulling latest changes after PR merges..." -ForegroundColor Yellow
    try {
        git pull origin main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Pulled latest changes" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Pull had issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARNING] Could not pull: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] Could not determine repository owner and name from remote URL" -ForegroundColor Red
    Write-Host "Remote URL: $remoteUrl" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pull Request Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


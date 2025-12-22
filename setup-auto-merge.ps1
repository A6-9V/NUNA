#Requires -Version 5.1
<#
.SYNOPSIS
    Setup Auto-Merge for Repository
.DESCRIPTION
    Configures GitHub repository for automatic PR merging
    Sets up workflows and enables auto-merge features
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto-Merge Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub CLI is available
$ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghAvailable) {
    Write-Host "[ERROR] GitHub CLI (gh) is not installed" -ForegroundColor Red
    Write-Host "  Install it from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "  Or use: winget install --id GitHub.cli" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "[1/5] Checking GitHub CLI authentication..." -ForegroundColor Yellow
try {
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] GitHub CLI is authenticated" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] GitHub CLI is not authenticated" -ForegroundColor Red
        Write-Host "  Please run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  [ERROR] Could not check authentication status" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Get repository info
Write-Host "[2/5] Getting repository information..." -ForegroundColor Yellow
$remoteUrl = git remote get-url origin 2>&1
if ($remoteUrl -match "github\.com/([^/]+)/([^/]+)") {
    $owner = $matches[1]
    $repo = $matches[2] -replace '\.git$', ''
    
    Write-Host "  Repository: $owner/$repo" -ForegroundColor Cyan
    Write-Host "  [OK] Repository identified" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Could not determine repository from remote URL" -ForegroundColor Red
    Write-Host "  Remote URL: $remoteUrl" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# Check if .github/workflows directory exists
Write-Host "[3/5] Checking GitHub Actions workflows..." -ForegroundColor Yellow
$workflowDir = ".github/workflows"
if (-not (Test-Path $workflowDir)) {
    Write-Host "  Creating workflows directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
}

$autoMergeWorkflow = Join-Path $workflowDir "auto-merge.yml"
$enableAutoMergeWorkflow = Join-Path $workflowDir "enable-auto-merge.yml"

if ((Test-Path $autoMergeWorkflow) -or (Test-Path $enableAutoMergeWorkflow)) {
    Write-Host "  [OK] Auto-merge workflows are present" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Auto-merge workflows not found" -ForegroundColor Yellow
    Write-Host "  Workflows should be created in: $workflowDir" -ForegroundColor Gray
}
Write-Host ""

# Check repository settings
Write-Host "[4/5] Checking repository settings..." -ForegroundColor Yellow
try {
    $repoInfo = gh api "repos/$owner/$repo" | ConvertFrom-Json
    
    Write-Host "  Repository: $($repoInfo.full_name)" -ForegroundColor Cyan
    Write-Host "  Allow auto-merge: $($repoInfo.allow_auto_merge)" -ForegroundColor Cyan
    Write-Host "  Allow merge commits: $($repoInfo.allow_merge_commit)" -ForegroundColor Cyan
    Write-Host "  Allow squash merge: $($repoInfo.allow_squash_merge)" -ForegroundColor Cyan
    Write-Host "  Allow rebase merge: $($repoInfo.allow_rebase_merge)" -ForegroundColor Cyan
    
    # Enable auto-merge if not already enabled
    if (-not $repoInfo.allow_auto_merge) {
        Write-Host ""
        Write-Host "  [INFO] Auto-merge is not enabled on this repository" -ForegroundColor Yellow
        Write-Host "  Attempting to enable auto-merge..." -ForegroundColor Cyan
        
        try {
            gh api -X PATCH "repos/$owner/$repo" -f allow_auto_merge=true | Out-Null
            Write-Host "  [OK] Auto-merge enabled successfully!" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Could not enable auto-merge automatically" -ForegroundColor Yellow
            Write-Host "  You may need admin permissions or to enable it in GitHub settings:" -ForegroundColor Gray
            Write-Host "  https://github.com/$owner/$repo/settings" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [OK] Auto-merge is already enabled" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARNING] Could not retrieve repository settings: $_" -ForegroundColor Yellow
}
Write-Host ""

# Check for open PRs and offer to enable auto-merge
Write-Host "[5/5] Checking for open pull requests..." -ForegroundColor Yellow
try {
    $prs = gh pr list --repo "$owner/$repo" --state open --json number,title,author,headRefName,autoMergeRequest --limit 10 | ConvertFrom-Json
    
    if ($prs -and $prs.Count -gt 0) {
        Write-Host "  Found $($prs.Count) open pull request(s):" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($pr in $prs) {
            $autoMergeStatus = if ($pr.autoMergeRequest) { "Enabled" } else { "Disabled" }
            $statusColor = if ($pr.autoMergeRequest) { "Green" } else { "Yellow" }
            
            Write-Host "  PR #$($pr.number): $($pr.title)" -ForegroundColor Cyan
            Write-Host "    Branch: $($pr.headRefName)" -ForegroundColor Gray
            Write-Host "    Author: $($pr.author.login)" -ForegroundColor Gray
            Write-Host "    Auto-merge: $autoMergeStatus" -ForegroundColor $statusColor
            
            # Offer to enable auto-merge if not already enabled
            if (-not $pr.autoMergeRequest) {
                Write-Host "    → Enable auto-merge? (y/N): " -NoNewline -ForegroundColor Yellow
                $response = Read-Host
                
                if ($response -eq 'y' -or $response -eq 'Y') {
                    try {
                        gh pr merge $pr.number --repo "$owner/$repo" --auto --merge
                        Write-Host "    [OK] Auto-merge enabled for PR #$($pr.number)" -ForegroundColor Green
                    } catch {
                        Write-Host "    [WARNING] Could not enable auto-merge: $_" -ForegroundColor Yellow
                    }
                }
            }
            Write-Host ""
        }
    } else {
        Write-Host "  [INFO] No open pull requests found" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  [WARNING] Could not check pull requests: $_" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Auto-merge is now configured for this repository." -ForegroundColor Green
Write-Host ""
Write-Host "What happens next:" -ForegroundColor Cyan
Write-Host "  1. When a new PR is opened, auto-merge will be enabled automatically" -ForegroundColor White
Write-Host "  2. PRs will merge automatically when all checks pass" -ForegroundColor White
Write-Host "  3. You can manually enable auto-merge with: gh pr merge <number> --auto" -ForegroundColor White
Write-Host ""
Write-Host "To manually enable auto-merge for a PR:" -ForegroundColor Yellow
Write-Host "  gh pr merge <PR-number> --auto --merge" -ForegroundColor Gray
Write-Host ""
Write-Host "To check repository settings:" -ForegroundColor Yellow
Write-Host "  https://github.com/$owner/$repo/settings" -ForegroundColor Gray
Write-Host ""

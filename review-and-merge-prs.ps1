# PR Review and Merge Helper Script
# Purpose: Assist with reviewing and merging open pull requests

param(
    [ValidateSet("list", "review", "merge", "close")]
    [string]$Action = "list",
    
    [int]$PRNumber,
    
    [switch]$Force = $false
)

Write-Host "`n=== Pull Request Management ===" -ForegroundColor Cyan
Write-Host "Repository: A6-9V/my-drive-projects`n" -ForegroundColor Cyan

# PR Database
# NOTE: This is a static snapshot from 2025-12-22
# For real-time data, use: gh pr list --json number,title,state
$prs = @{
    3 = @{
        Title = "Trading system heartbeat"
        Branch = "cursor/trading-system-heartbeat-d401"
        Status = "Open"
        Priority = "High"
        Risk = "Low"
        Changes = "Adds heartbeat monitoring service"
        Recommendation = "MERGE - Valuable monitoring feature"
        ReviewComments = 0
    }
    4 = @{
        Title = "Agent review process (Security)"
        Branch = "cursor/agent-review-process-652c"
        Status = "Open"
        Priority = "Critical"
        Risk = "Low"
        Changes = "Security hardening for auto-git-push.ps1"
        Recommendation = "MERGE - Critical security improvement"
        ReviewComments = 0
    }
    12 = @{
        Title = "Scheduled file cleanup process"
        Branch = "Cursor/A6-9V/scheduled-file-cleanup-process-82e6"
        Status = "Open"
        Priority = "Medium"
        Risk = "Medium"
        Changes = "Adds scheduled cleanup system with approval gate"
        Recommendation = "REVIEW REQUIRED - Address 59 comments first"
        ReviewComments = 59
    }
    26 = @{
        Title = "PR review documentation"
        Branch = "copilot/review-and-merge-pull-requests"
        Status = "Open (Draft)"
        Priority = "Low"
        Risk = "None"
        Changes = "Documentation for reviewing other PRs"
        Recommendation = "CLOSE - Purpose fulfilled, meta-documentation"
        ReviewComments = 0
    }
    27 = @{
        Title = "GitHub Secrets setup"
        Branch = "copilot/set-github-secrets"
        Status = "Open (Draft)"
        Priority = "Medium"
        Risk = "Medium"
        Changes = "GitHub secrets automation scripts"
        Recommendation = "REVIEW - Check for security issues, credentials in PR"
        ReviewComments = 0
    }
    28 = @{
        Title = "Branch cleanup (Current)"
        Branch = "copilot/cleanup-commit-and-merge"
        Status = "Open (Draft)"
        Priority = "Low"
        Risk = "None"
        Changes = "0 changes - tracking PR"
        Recommendation = "CLOSE AFTER CLEANUP - No code changes"
        ReviewComments = 0
    }
}

function Show-PRList {
    Write-Host "=== Open Pull Requests ===" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($prNum in ($prs.Keys | Sort-Object)) {
        $pr = $prs[$prNum]
        
        $color = switch ($pr.Priority) {
            "Critical" { "Red" }
            "High" { "Yellow" }
            "Medium" { "Cyan" }
            "Low" { "Gray" }
            default { "White" }
        }
        
        Write-Host "PR #$prNum" -ForegroundColor $color -NoNewline
        Write-Host " - $($pr.Title)" -ForegroundColor White
        Write-Host "  Priority: $($pr.Priority) | Risk: $($pr.Risk) | Comments: $($pr.ReviewComments)" -ForegroundColor DarkGray
        Write-Host "  Recommendation: $($pr.Recommendation)" -ForegroundColor $(
            if ($pr.Recommendation -match "MERGE") { "Green" }
            elseif ($pr.Recommendation -match "REVIEW") { "Yellow" }
            else { "Gray" }
        )
        Write-Host ""
    }
    
    Write-Host "=== Merge Priority Order ===" -ForegroundColor Cyan
    Write-Host "  1. PR #4 (Security - Critical)" -ForegroundColor Red
    Write-Host "  2. PR #3 (Monitoring - High)" -ForegroundColor Yellow
    Write-Host "  3. PR #12 (Cleanup - After review)" -ForegroundColor Cyan
    Write-Host "  4. PR #27 (Secrets - After review)" -ForegroundColor Cyan
    Write-Host "  5. PR #26, #28 (Close)" -ForegroundColor Gray
}

function Show-PRReview {
    param([int]$Number)
    
    if (-not $prs.ContainsKey($Number)) {
        Write-Host "  ✗ PR #$Number not found" -ForegroundColor Red
        return
    }
    
    $pr = $prs[$Number]
    
    Write-Host "`n=== PR #$Number Review ===" -ForegroundColor Cyan
    Write-Host "  Title: $($pr.Title)" -ForegroundColor White
    Write-Host "  Branch: $($pr.Branch)" -ForegroundColor Gray
    Write-Host "  Status: $($pr.Status)" -ForegroundColor Yellow
    Write-Host "  Priority: $($pr.Priority)" -ForegroundColor Yellow
    Write-Host "  Risk Level: $($pr.Risk)" -ForegroundColor $(if ($pr.Risk -eq "Low") { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "  Changes:" -ForegroundColor Cyan
    Write-Host "    $($pr.Changes)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Recommendation:" -ForegroundColor Cyan
    Write-Host "    $($pr.Recommendation)" -ForegroundColor $(
        if ($pr.Recommendation -match "MERGE") { "Green" }
        elseif ($pr.Recommendation -match "REVIEW") { "Yellow" }
        else { "Gray" }
    )
    
    if ($pr.ReviewComments -gt 0) {
        Write-Host ""
        Write-Host "  ⚠ WARNING: $($pr.ReviewComments) review comments need to be addressed" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  View PR online:" -ForegroundColor Cyan
    Write-Host "    https://github.com/A6-9V/my-drive-projects/pull/$Number" -ForegroundColor Blue
    
    Write-Host ""
    Write-Host "  To merge this PR:" -ForegroundColor Cyan
    Write-Host "    .\review-and-merge-prs.ps1 -Action merge -PRNumber $Number" -ForegroundColor White
}

function Merge-PR {
    param([int]$Number)
    
    if (-not $prs.ContainsKey($Number)) {
        Write-Host "  ✗ PR #$Number not found" -ForegroundColor Red
        return
    }
    
    $pr = $prs[$Number]
    
    Write-Host "`n=== Merging PR #$Number ===" -ForegroundColor Yellow
    Write-Host "  Title: $($pr.Title)" -ForegroundColor White
    Write-Host "  Branch: $($pr.Branch)" -ForegroundColor Gray
    
    # Check if review is recommended
    if ($pr.Recommendation -notmatch "MERGE" -and -not $Force) {
        Write-Host ""
        Write-Host "  ⚠ WARNING: This PR is not recommended for immediate merge" -ForegroundColor Red
        Write-Host "  Recommendation: $($pr.Recommendation)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Use -Force to merge anyway" -ForegroundColor Gray
        return
    }
    
    if ($pr.ReviewComments -gt 0 -and -not $Force) {
        Write-Host ""
        Write-Host "  ⚠ WARNING: $($pr.ReviewComments) review comments need to be addressed" -ForegroundColor Red
        Write-Host "  Use -Force to merge anyway" -ForegroundColor Gray
        return
    }
    
    Write-Host ""
    Write-Host "  ℹ This script cannot merge PRs directly." -ForegroundColor Cyan
    Write-Host "  PRs must be merged via GitHub web interface or gh CLI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Option 1 - GitHub Web:" -ForegroundColor Yellow
    Write-Host "    1. Open: https://github.com/A6-9V/my-drive-projects/pull/$Number" -ForegroundColor White
    Write-Host "    2. Click 'Merge pull request'" -ForegroundColor White
    Write-Host "    3. Confirm the merge" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option 2 - GitHub CLI:" -ForegroundColor Yellow
    Write-Host "    gh pr merge $Number --repo A6-9V/my-drive-projects --merge" -ForegroundColor White
    Write-Host ""
    Write-Host "  After merge, delete the branch:" -ForegroundColor Yellow
    Write-Host "    git push origin --delete $($pr.Branch)" -ForegroundColor White
}

function Close-PR {
    param([int]$Number)
    
    if (-not $prs.ContainsKey($Number)) {
        Write-Host "  ✗ PR #$Number not found" -ForegroundColor Red
        return
    }
    
    $pr = $prs[$Number]
    
    Write-Host "`n=== Closing PR #$Number ===" -ForegroundColor Yellow
    Write-Host "  Title: $($pr.Title)" -ForegroundColor White
    
    Write-Host ""
    Write-Host "  ℹ This script cannot close PRs directly." -ForegroundColor Cyan
    Write-Host "  PRs must be closed via GitHub web interface or gh CLI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Option 1 - GitHub Web:" -ForegroundColor Yellow
    Write-Host "    1. Open: https://github.com/A6-9V/my-drive-projects/pull/$Number" -ForegroundColor White
    Write-Host "    2. Click 'Close pull request'" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option 2 - GitHub CLI:" -ForegroundColor Yellow
    Write-Host "    gh pr close $Number --repo A6-9V/my-drive-projects" -ForegroundColor White
}

# Main execution
switch ($Action) {
    "list" {
        Show-PRList
    }
    "review" {
        if (-not $PRNumber) {
            Write-Host "  ✗ Please specify -PRNumber" -ForegroundColor Red
            Write-Host "  Example: .\review-and-merge-prs.ps1 -Action review -PRNumber 3" -ForegroundColor Gray
            return
        }
        Show-PRReview -Number $PRNumber
    }
    "merge" {
        if (-not $PRNumber) {
            Write-Host "  ✗ Please specify -PRNumber" -ForegroundColor Red
            Write-Host "  Example: .\review-and-merge-prs.ps1 -Action merge -PRNumber 3" -ForegroundColor Gray
            return
        }
        Merge-PR -Number $PRNumber
    }
    "close" {
        if (-not $PRNumber) {
            Write-Host "  ✗ Please specify -PRNumber" -ForegroundColor Red
            Write-Host "  Example: .\review-and-merge-prs.ps1 -Action close -PRNumber 26" -ForegroundColor Gray
            return
        }
        Close-PR -Number $PRNumber
    }
}

Write-Host ""

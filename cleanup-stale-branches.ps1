# Branch Cleanup Script for my-drive-projects
# Purpose: Clean up stale branches after PR review and merge

param(
    [switch]$DryRun = $true,
    [switch]$Force = $false
)

Write-Host "`n=== Repository Branch Cleanup ===" -ForegroundColor Cyan
Write-Host "Repository: A6-9V/my-drive-projects`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No branches will be deleted" -ForegroundColor Yellow
    Write-Host "Use -DryRun:`$false to actually delete branches`n" -ForegroundColor Yellow
}

# Branches to keep (associated with open PRs or protected)
# NOTE: This list is hardcoded based on analysis from 2025-12-22
# For dynamic updates, consider using: gh pr list --json headRefName
$branchesToKeep = @(
    "main",
    "cursor/agent-review-process-652c",  # PR #4
    "cursor/trading-system-heartbeat-d401",  # PR #3
    "Cursor/A6-9V/scheduled-file-cleanup-process-82e6",  # PR #12
    "copilot/review-and-merge-pull-requests",  # PR #26
    "copilot/set-github-secrets",  # PR #27
    "copilot/cleanup-commit-and-merge"  # PR #28 (current)
)

# Branches marked as stale (likely completed/merged work)
$staleBranches = @(
    "Cursor/A6-9V/automated-agent-request-system-baae",
    "Cursor/A6-9V/battery-maintainer-plugin-device-7eed",
    "Cursor/A6-9V/codebase-error-resolution-836c",
    "Cursor/A6-9V/directory-documentation-admin-owner-812c",
    "Cursor/A6-9V/docker-file-administrator-execution-d3a1",
    "Cursor/A6-9V/document-image-cleanup-794d",
    "Cursor/A6-9V/drive-cleanup-and-deployment-9643",
    "Cursor/A6-9V/exness-deposit-request-d781",
    "Cursor/A6-9V/exness-terminal-profile-launch-86b6",
    "Cursor/A6-9V/finnish-job-link-agent-95c3",
    "Cursor/A6-9V/github-oauth-app-fix-534f",
    "Cursor/A6-9V/github-repo-update-57bd",
    "Cursor/A6-9V/github-review-inbox-session-f02e",
    "Cursor/A6-9V/huawei-router-details-48d9",
    "Cursor/A6-9V/merge-repo-branch-session-6b52",
    "Cursor/A6-9V/mql5-vps-deployment-05ba",
    "Cursor/A6-9V/mql5-vps-deployment-exness-2f56",
    "Cursor/A6-9V/optional-feature-integration-9222",
    "Cursor/A6-9V/pull-request-conflict-resolution-37a5",
    "Cursor/A6-9V/session-cleanup-process-7b02",
    "Cursor/A6-9V/session-management-initialization-cff2",
    "Cursor/A6-9V/sms-configuration-details-8c48",
    "Cursor/A6-9V/task-manager-docker-dark-cb48",
    "Cursor/A6-9V/trading-system-firewall-access-40f6",
    "Cursor/A6-9V/trading-system-setup-and-bot-7ff6",
    "copilot/clean-up-work-space",
    "copilot/merge-pull-requests-to-my-drive"
)

Write-Host "`n=== Protected Branches (Will Not Delete) ===" -ForegroundColor Green
foreach ($branch in $branchesToKeep) {
    Write-Host "  ✓ $branch" -ForegroundColor Green
}

Write-Host "`n=== Stale Branches (Marked for Deletion) ===" -ForegroundColor Yellow
Write-Host "Total: $($staleBranches.Count) branches`n" -ForegroundColor Yellow

$deletedCount = 0
$errorCount = 0
$deletedBranches = @()
$failedBranches = @()

foreach ($branch in $staleBranches) {
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would delete: $branch" -ForegroundColor DarkGray
    } else {
        try {
            Write-Host "  Deleting: $branch..." -NoNewline
            $output = git push origin --delete $branch 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓ Deleted" -ForegroundColor Green
                $deletedCount++
                $deletedBranches += $branch
            } else {
                # Show actual error message for better diagnostics
                $errorMsg = if ($output) { ($output | Out-String).Trim() } else { "Unknown error" }
                Write-Host " ✗ Failed" -ForegroundColor Red
                Write-Host "    Error: $errorMsg" -ForegroundColor DarkRed
                $errorCount++
                $failedBranches += $branch
            }
        } catch {
            Write-Host " ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
            $failedBranches += $branch
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  Mode: DRY RUN (no changes made)" -ForegroundColor Yellow
    Write-Host "  Branches identified for deletion: $($staleBranches.Count)" -ForegroundColor Yellow
    Write-Host "`n  To execute cleanup, run:" -ForegroundColor Yellow
    Write-Host "    .\cleanup-stale-branches.ps1 -DryRun:`$false" -ForegroundColor White
} else {
    Write-Host "  Mode: LIVE EXECUTION" -ForegroundColor Green
    Write-Host "  Branches deleted: $deletedCount" -ForegroundColor Green
    Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  Protected branches: $($branchesToKeep.Count)" -ForegroundColor Cyan
    
    if ($deletedBranches.Count -gt 0) {
        Write-Host "`n  Successfully deleted:" -ForegroundColor Green
        foreach ($branch in $deletedBranches) {
            Write-Host "    - $branch" -ForegroundColor DarkGray
        }
    }
    
    if ($failedBranches.Count -gt 0) {
        Write-Host "`n  Failed to delete (may not exist on remote):" -ForegroundColor Yellow
        foreach ($branch in $failedBranches) {
            Write-Host "    - $branch" -ForegroundColor DarkGray
        }
    }
    
    # Create cleanup log
    $logContent = @"
Branch Cleanup Log
==================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Mode: $( if ($DryRun) { "DRY RUN" } else { "LIVE" } )

Deleted Branches ($deletedCount):
$($deletedBranches -join "`n")

Failed Branches ($errorCount):
$($failedBranches -join "`n")

Protected Branches:
$($branchesToKeep -join "`n")
"@
    
    $logFile = "branch-cleanup-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $logContent | Out-File $logFile -Encoding UTF8
    Write-Host "`n  Log saved to: $logFile" -ForegroundColor Cyan
}

Write-Host "`n=== Important Notes ===" -ForegroundColor Cyan
Write-Host "  • GitHub retains deleted branches for 30 days" -ForegroundColor Gray
Write-Host "  • Branches can be restored from PR pages if needed" -ForegroundColor Gray
Write-Host "  • PR history is preserved even after branch deletion" -ForegroundColor Gray
Write-Host "  • Protected branches are never deleted" -ForegroundColor Gray

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Green

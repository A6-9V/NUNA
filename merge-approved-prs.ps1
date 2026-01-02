# Merge Approved Pull Requests
# This script automates the merging of approved PRs in the recommended order
# Generated: 2025-12-22

param(
    [Parameter()]
    [switch]$DryRun = $false,
    
    [Parameter()]
    [ValidateSet('All', 'Phase1', 'Phase2', 'Phase3')]
    [string]$Phase = 'All',
    
    [Parameter()]
    [switch]$Force = $false
)

# Color output functions
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error-Msg { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# PR merge configuration
$Phase1PRs = @(
    @{ Number = 4; Branch = "cursor/agent-review-process-652c"; Title = "Security: Remove GitHub token from remote URLs"; Priority = "HIGH-SECURITY" }
    @{ Number = 3; Branch = "cursor/trading-system-heartbeat-d401"; Title = "Add trading system heartbeat service"; Priority = "HIGH" }
)

$Phase2PRs = @(
    @{ Number = 26; Branch = "copilot/review-and-merge-pull-requests"; Title = "Add comprehensive PR review documentation"; Priority = "MEDIUM" }
    @{ Number = 28; Branch = "copilot/cleanup-commit-and-merge"; Title = "Add repository cleanup automation tools"; Priority = "MEDIUM" }
    @{ Number = 30; Branch = "copilot/setup-cursor-dashboard-to-light"; Title = "Configure Cursor IDE light theme"; Priority = "MEDIUM" }
)

$Phase3PRs = @(
    @{ Number = 27; Branch = "copilot/set-github-secrets"; Title = "GitHub Secrets setup"; Priority = "LOW-REVIEW-REQUIRED" }
    @{ Number = 29; Branch = "copilot/setup-auto-merge"; Title = "Auto-merge workflows"; Priority = "LOW-FIX-REQUIRED" }
)

# Header
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  PR Merge Automation Script" -ForegroundColor Magenta
Write-Host "  Repository: A6-9V/my-drive-projects" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

if ($DryRun) {
    Write-Warning "DRY RUN MODE - No actual merges will be performed"
}

# Check if gh CLI is available
Write-Info "Checking GitHub CLI availability..."
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Error-Msg "GitHub CLI (gh) is not installed or not in PATH"
    Write-Info "Please install GitHub CLI from: https://cli.github.com/"
    exit 1
}
Write-Success "GitHub CLI found"

# Check authentication
Write-Info "Checking GitHub CLI authentication..."
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error-Msg "GitHub CLI is not authenticated"
    Write-Info "Please run: gh auth login"
    exit 1
}
Write-Success "GitHub CLI is authenticated"

# Function to merge a PR
function Merge-PR {
    param(
        [int]$PRNumber,
        [string]$Title,
        [string]$Branch,
        [string]$Priority,
        [bool]$DryRun
    )
    
    Write-Host "`n----------------------------------------" -ForegroundColor Cyan
    Write-Info "Processing PR #$PRNumber"
    Write-Info "  Title: $Title"
    Write-Info "  Branch: $Branch"
    Write-Info "  Priority: $Priority"
    
    if ($DryRun) {
        Write-Warning "  [DRY RUN] Would merge PR #$PRNumber using: gh pr merge $PRNumber --squash --delete-branch"
        return $true
    }
    
    # Check PR status
    Write-Info "  Checking PR status..."
    $prStatus = gh pr view $PRNumber --json state,mergeable,mergeStateStatus 2>&1 | ConvertFrom-Json
    
    if ($prStatus.state -ne "OPEN") {
        Write-Warning "  PR #$PRNumber is not open (state: $($prStatus.state)). Skipping."
        return $false
    }
    
    if ($prStatus.mergeable -ne "MERGEABLE") {
        Write-Warning "  PR #$PRNumber is not mergeable (mergeable: $($prStatus.mergeable)). Skipping."
        return $false
    }
    
    # Attempt merge
    Write-Info "  Merging PR #$PRNumber..."
    try {
        $mergeResult = gh pr merge $PRNumber --squash --delete-branch --admin 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "  Successfully merged PR #$PRNumber"
            Write-Success "  Branch '$Branch' has been deleted"
            return $true
        } else {
            Write-Error-Msg "  Failed to merge PR #$PRNumber"
            Write-Error-Msg "  Error: $mergeResult"
            return $false
        }
    } catch {
        Write-Error-Msg "  Exception during merge: $($_.Exception.Message)"
        return $false
    }
}

# Function to process a phase
function Process-Phase {
    param(
        [string]$PhaseName,
        [array]$PRs,
        [bool]$DryRun
    )
    
    Write-Host "`n========================================"  -ForegroundColor Magenta
    Write-Host "  $PhaseName" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    
    $successCount = 0
    $skipCount = 0
    $failCount = 0
    
    foreach ($pr in $PRs) {
        $result = Merge-PR -PRNumber $pr.Number -Title $pr.Title -Branch $pr.Branch -Priority $pr.Priority -DryRun $DryRun
        
        if ($result) {
            $successCount++
        } elseif ($result -eq $false) {
            $failCount++
        } else {
            $skipCount++
        }
        
        Start-Sleep -Seconds 2  # Rate limiting
    }
    
    Write-Host "`n$PhaseName Summary:" -ForegroundColor Cyan
    Write-Success "  Merged: $successCount"
    if ($skipCount -gt 0) { Write-Warning "  Skipped: $skipCount" }
    if ($failCount -gt 0) { Write-Error-Msg "  Failed: $failCount" }
    
    return @{
        Success = $successCount
        Skipped = $skipCount
        Failed = $failCount
    }
}

# Execute phases based on parameter
$totalSuccess = 0
$totalSkipped = 0
$totalFailed = 0

if ($Phase -eq 'All' -or $Phase -eq 'Phase1') {
    $result = Process-Phase -PhaseName "Phase 1: High Priority (Security & Core)" -PRs $Phase1PRs -DryRun $DryRun
    $totalSuccess += $result.Success
    $totalSkipped += $result.Skipped
    $totalFailed += $result.Failed
}

if ($Phase -eq 'All' -or $Phase -eq 'Phase2') {
    $result = Process-Phase -PhaseName "Phase 2: Medium Priority (Documentation & Config)" -PRs $Phase2PRs -DryRun $DryRun
    $totalSuccess += $result.Success
    $totalSkipped += $result.Skipped
    $totalFailed += $result.Failed
}

if ($Phase -eq 'All' -or $Phase -eq 'Phase3') {
    Write-Host "`n========================================"  -ForegroundColor Magenta
    Write-Host "  Phase 3: Low Priority (Needs Review)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Warning "Phase 3 PRs require manual review before merging:"
    Write-Warning "  - PR #27: Security review required for credential handling"
    Write-Warning "  - PR #29: 6 review comments need to be addressed"
    Write-Info "`nThese PRs are NOT automatically merged by this script."
    Write-Info "Please review and merge manually after addressing concerns."
}

# Final summary
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  FINAL SUMMARY" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Success "Total PRs Merged: $totalSuccess"
if ($totalSkipped -gt 0) { Write-Warning "Total PRs Skipped: $totalSkipped" }
if ($totalFailed -gt 0) { Write-Error-Msg "Total PRs Failed: $totalFailed" }

if ($DryRun) {
    Write-Host "`n" -NoNewline
    Write-Warning "This was a DRY RUN - no actual merges were performed"
    Write-Info "To perform actual merges, run without -DryRun flag:"
    Write-Info "  .\merge-approved-prs.ps1"
    Write-Info "  .\merge-approved-prs.ps1 -Phase Phase1  # For specific phase"
}

Write-Host "`n========================================`n" -ForegroundColor Magenta

# Exit with appropriate code
if ($totalFailed -gt 0) {
    exit 1
} else {
    exit 0
}

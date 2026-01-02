# Auto Review, Merge PRs, and Inject All Repositories
# This script automates the process of reviewing/merging all open PRs from Mouy-leng and A6-9V repos
# Then injects all repositories into the my-drive-projects repository

param(
    [switch]$DryRun = $false,
    [switch]$SkipMerge = $false,
    [switch]$InjectOnly = $false
)

$ErrorActionPreference = "Continue"
$global:logFile = "repo-automation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$global:reportFile = "repo-automation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

# Color-coded logging function
function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Log to file
    Add-Content -Path $global:logFile -Value $logMessage
    
    # Color output to console
    switch ($Level) {
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }
}

# Initialize report
function Initialize-Report {
    $header = @"
# Repository Automation Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary

"@
    Set-Content -Path $global:reportFile -Value $header
}

function Add-ReportSection {
    param([string]$Title, [string]$Content)
    $section = @"

## $Title

$Content

"@
    Add-Content -Path $global:reportFile -Value $section
}

# Check if gh CLI is installed and authenticated
function Test-GitHubCLI {
    try {
        $ghVersion = gh --version 2>&1
        Write-ColorLog "GitHub CLI detected: $($ghVersion[0])" "SUCCESS"
        
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorLog "GitHub CLI is authenticated" "SUCCESS"
            return $true
        } else {
            Write-ColorLog "GitHub CLI is not authenticated. Please run: gh auth login" "ERROR"
            return $false
        }
    } catch {
        Write-ColorLog "GitHub CLI (gh) is not installed. Please install it from: https://cli.github.com/" "ERROR"
        return $false
    }
}

# Get all open PRs for a repository
function Get-RepositoryPRs {
    param(
        [string]$Owner,
        [string]$Repo
    )
    
    try {
        Write-ColorLog "Fetching open PRs for $Owner/$Repo..." "INFO"
        $prs = gh pr list --repo "$Owner/$Repo" --state open --json number,title,author,url,mergeable,statusCheckRollup --limit 100 | ConvertFrom-Json
        return $prs
    } catch {
        Write-ColorLog "Failed to fetch PRs for $Owner/$Repo: $_" "ERROR"
        return @()
    }
}

# Review and potentially merge a PR
function Process-PullRequest {
    param(
        [string]$Owner,
        [string]$Repo,
        [object]$PR,
        [bool]$DryRun
    )
    
    $prIdentifier = "$Owner/$Repo#$($PR.number)"
    Write-ColorLog "Processing PR: $prIdentifier - $($PR.title)" "INFO"
    
    $prDetails = @{
        Repository = "$Owner/$Repo"
        Number = $PR.number
        Title = $PR.title
        Author = $PR.author.login
        URL = $PR.url
        Mergeable = $PR.mergeable
        Status = "Unknown"
        Action = "None"
    }
    
    # Check if PR is mergeable
    if ($PR.mergeable -eq "CONFLICTING") {
        Write-ColorLog "PR $prIdentifier has conflicts - cannot auto-merge" "WARNING"
        $prDetails.Status = "Has Conflicts"
        $prDetails.Action = "Manual Review Required"
        return $prDetails
    }
    
    # Check CI status
    $hasFailedChecks = $false
    if ($PR.statusCheckRollup) {
        foreach ($check in $PR.statusCheckRollup) {
            if ($check.state -eq "FAILURE" -or $check.conclusion -eq "FAILURE") {
                $hasFailedChecks = $true
                Write-ColorLog "PR $prIdentifier has failed checks: $($check.name)" "WARNING"
            }
        }
    }
    
    if ($hasFailedChecks) {
        $prDetails.Status = "Failed Checks"
        $prDetails.Action = "Manual Review Required"
        return $prDetails
    }
    
    # Attempt to merge
    if ($DryRun) {
        Write-ColorLog "[DRY RUN] Would merge PR $prIdentifier" "INFO"
        $prDetails.Status = "Ready to Merge"
        $prDetails.Action = "Would Merge (Dry Run)"
    } else {
        try {
            Write-ColorLog "Attempting to merge PR $prIdentifier..." "INFO"
            gh pr merge $PR.number --repo "$Owner/$Repo" --merge --auto
            Write-ColorLog "Successfully merged PR $prIdentifier" "SUCCESS"
            $prDetails.Status = "Merged"
            $prDetails.Action = "Merged Successfully"
        } catch {
            Write-ColorLog "Failed to merge PR $prIdentifier: $_" "ERROR"
            $prDetails.Status = "Merge Failed"
            $prDetails.Action = "Failed: $_"
        }
    }
    
    return $prDetails
}

# Get all repositories for a user
function Get-UserRepositories {
    param([string]$Username)
    
    try {
        Write-ColorLog "Fetching repositories for user: $Username..." "INFO"
        $repos = gh repo list $Username --json name,url,isPrivate,updatedAt --limit 100 | ConvertFrom-Json
        Write-ColorLog "Found $($repos.Count) repositories for $Username" "SUCCESS"
        return $repos
    } catch {
        Write-ColorLog "Failed to fetch repositories for $Username: $_" "ERROR"
        return @()
    }
}

# Get all repositories in an organization
function Get-OrgRepositories {
    param([string]$OrgName)
    
    try {
        Write-ColorLog "Fetching repositories for organization: $OrgName..." "INFO"
        $repos = gh repo list $OrgName --json name,url,isPrivate,updatedAt --limit 100 | ConvertFrom-Json
        Write-ColorLog "Found $($repos.Count) repositories for $OrgName" "SUCCESS"
        return $repos
    } catch {
        Write-ColorLog "Failed to fetch repositories for $OrgName: $_" "ERROR"
        return @()
    }
}

# Clone or update a repository
function Sync-Repository {
    param(
        [string]$RepoUrl,
        [string]$TargetDir,
        [bool]$DryRun
    )
    
    if ($DryRun) {
        Write-ColorLog "[DRY RUN] Would sync repository: $RepoUrl to $TargetDir" "INFO"
        return $true
    }
    
    try {
        if (Test-Path $TargetDir) {
            Write-ColorLog "Updating existing repository at $TargetDir..." "INFO"
            Push-Location $TargetDir
            git fetch --all
            git pull origin HEAD
            Pop-Location
        } else {
            Write-ColorLog "Cloning repository to $TargetDir..." "INFO"
            git clone $RepoUrl $TargetDir
        }
        Write-ColorLog "Successfully synced: $RepoUrl" "SUCCESS"
        return $true
    } catch {
        Write-ColorLog "Failed to sync repository $RepoUrl: $_" "ERROR"
        return $false
    }
}

# Inject a repository into my-drive-projects
function Inject-Repository {
    param(
        [string]$SourceDir,
        [string]$RepoName,
        [string]$Category,
        [bool]$DryRun
    )
    
    $targetDir = Join-Path (Get-Location) "injected-repos/$Category/$RepoName"
    
    if ($DryRun) {
        Write-ColorLog "[DRY RUN] Would inject $RepoName into $targetDir" "INFO"
        return @{
            RepoName = $RepoName
            Category = $Category
            Status = "Would Inject (Dry Run)"
            TargetPath = $targetDir
        }
    }
    
    try {
        # Create target directory
        if (!(Test-Path (Split-Path $targetDir))) {
            New-Item -ItemType Directory -Path (Split-Path $targetDir) -Force | Out-Null
        }
        
        # Copy repository contents (excluding .git)
        if (Test-Path $SourceDir) {
            Write-ColorLog "Injecting $RepoName into my-drive-projects..." "INFO"
            
            # Use robocopy for efficient copying (Windows)
            if (Get-Command robocopy -ErrorAction SilentlyContinue) {
                robocopy $SourceDir $targetDir /E /XD .git /NFL /NDL /NJH /NJS /nc /ns /np
            } else {
                # Fallback to Copy-Item
                Copy-Item -Path "$SourceDir/*" -Destination $targetDir -Recurse -Force -Exclude ".git"
            }
            
            Write-ColorLog "Successfully injected: $RepoName" "SUCCESS"
            return @{
                RepoName = $RepoName
                Category = $Category
                Status = "Injected Successfully"
                TargetPath = $targetDir
            }
        } else {
            Write-ColorLog "Source directory not found: $SourceDir" "ERROR"
            return @{
                RepoName = $RepoName
                Category = $Category
                Status = "Source Not Found"
                TargetPath = $targetDir
            }
        }
    } catch {
        Write-ColorLog "Failed to inject $RepoName: $_" "ERROR"
        return @{
            RepoName = $RepoName
            Category = $Category
            Status = "Injection Failed: $_"
            TargetPath = $targetDir
        }
    }
}

# Main execution
function Main {
    Write-ColorLog "========================================" "INFO"
    Write-ColorLog "Repository Automation Script Started" "INFO"
    Write-ColorLog "========================================" "INFO"
    Write-ColorLog "Dry Run: $DryRun" "INFO"
    Write-ColorLog "Skip Merge: $SkipMerge" "INFO"
    Write-ColorLog "Inject Only: $InjectOnly" "INFO"
    Write-ColorLog "========================================" "INFO"
    
    Initialize-Report
    
    # Check prerequisites
    if (!(Test-GitHubCLI)) {
        Write-ColorLog "GitHub CLI is not properly set up. Exiting." "ERROR"
        return
    }
    
    $allPRResults = @()
    $allInjectionResults = @()
    
    # Phase 1: Review and Merge PRs (if not skipped)
    if (!$InjectOnly -and !$SkipMerge) {
        Write-ColorLog "`n========================================" "INFO"
        Write-ColorLog "Phase 1: Reviewing and Merging Pull Requests" "INFO"
        Write-ColorLog "========================================`n" "INFO"
        
        # Process Mouy-leng repositories
        $moulengRepos = Get-UserRepositories -Username "Mouy-leng"
        foreach ($repo in $moulengRepos) {
            $prs = Get-RepositoryPRs -Owner "Mouy-leng" -Repo $repo.name
            
            if ($prs.Count -gt 0) {
                Write-ColorLog "Found $($prs.Count) open PR(s) in Mouy-leng/$($repo.name)" "INFO"
                
                foreach ($pr in $prs) {
                    $result = Process-PullRequest -Owner "Mouy-leng" -Repo $repo.name -PR $pr -DryRun $DryRun
                    $allPRResults += $result
                }
            }
        }
        
        # Process A6-9V organization repositories
        $a69vRepos = Get-OrgRepositories -OrgName "A6-9V"
        foreach ($repo in $a69vRepos) {
            $prs = Get-RepositoryPRs -Owner "A6-9V" -Repo $repo.name
            
            if ($prs.Count -gt 0) {
                Write-ColorLog "Found $($prs.Count) open PR(s) in A6-9V/$($repo.name)" "INFO"
                
                foreach ($pr in $prs) {
                    $result = Process-PullRequest -Owner "A6-9V" -Repo $repo.name -PR $pr -DryRun $DryRun
                    $allPRResults += $result
                }
            }
        }
        
        # Generate PR summary
        $prSummary = @"
### Pull Requests Processed: $($allPRResults.Count)

| Repository | PR# | Title | Author | Status | Action |
|------------|-----|-------|--------|--------|--------|
"@
        foreach ($result in $allPRResults) {
            $prSummary += "`n| $($result.Repository) | #$($result.Number) | $($result.Title) | $($result.Author) | $($result.Status) | $($result.Action) |"
        }
        
        Add-ReportSection -Title "Pull Request Processing" -Content $prSummary
    }
    
    # Phase 2: Clone and Inject Repositories
    Write-ColorLog "`n========================================" "INFO"
    Write-ColorLog "Phase 2: Cloning and Injecting Repositories" "INFO"
    Write-ColorLog "========================================`n" "INFO"
    
    $tempDir = Join-Path $env:TEMP "repo-automation-temp"
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    # Inject Mouy-leng repositories
    $mouyRepos = Get-UserRepositories -Username "Mouy-leng"
    foreach ($repo in $mouyRepos) {
        $repoDir = Join-Path $tempDir "Mouy-leng-$($repo.name)"
        $synced = Sync-Repository -RepoUrl $repo.url -TargetDir $repoDir -DryRun $DryRun
        
        if ($synced) {
            $injectionResult = Inject-Repository -SourceDir $repoDir -RepoName $repo.name -Category "Mouy-leng" -DryRun $DryRun
            $allInjectionResults += $injectionResult
        }
    }
    
    # Inject A6-9V repositories
    $a6Repos = Get-OrgRepositories -OrgName "A6-9V"
    foreach ($repo in $a6Repos) {
        # Skip the my-drive-projects repo itself
        if ($repo.name -eq "my-drive-projects") {
            continue
        }
        
        $repoDir = Join-Path $tempDir "A6-9V-$($repo.name)"
        $synced = Sync-Repository -RepoUrl $repo.url -TargetDir $repoDir -DryRun $DryRun
        
        if ($synced) {
            $injectionResult = Inject-Repository -SourceDir $repoDir -RepoName $repo.name -Category "A6-9V" -DryRun $DryRun
            $allInjectionResults += $injectionResult
        }
    }
    
    # Generate injection summary
    $injectionSummary = @"
### Repositories Injected: $($allInjectionResults.Count)

| Repository | Category | Status | Target Path |
|------------|----------|--------|-------------|
"@
    foreach ($result in $allInjectionResults) {
        $injectionSummary += "`n| $($result.RepoName) | $($result.Category) | $($result.Status) | $($result.TargetPath) |"
    }
    
    Add-ReportSection -Title "Repository Injection" -Content $injectionSummary
    
    # Create index file
    if (!$DryRun) {
        Write-ColorLog "Creating repository index..." "INFO"
        $indexContent = @"
# Injected Repositories Index
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

This directory contains all repositories from Mouy-leng and A6-9V that have been injected into my-drive-projects.

## Structure

- **Mouy-leng/**: Repositories from the Mouy-leng account
- **A6-9V/**: Repositories from the A6-9V organization

## Injected Repositories

$injectionSummary
"@
        Set-Content -Path "injected-repos/README.md" -Value $indexContent
    }
    
    # Final summary
    Write-ColorLog "`n========================================" "SUCCESS"
    Write-ColorLog "Automation Complete!" "SUCCESS"
    Write-ColorLog "========================================" "SUCCESS"
    Write-ColorLog "PRs Processed: $($allPRResults.Count)" "INFO"
    Write-ColorLog "Repositories Injected: $($allInjectionResults.Count)" "INFO"
    Write-ColorLog "Log File: $global:logFile" "INFO"
    Write-ColorLog "Report File: $global:reportFile" "INFO"
    Write-ColorLog "========================================`n" "SUCCESS"
}

# Run main function
Main

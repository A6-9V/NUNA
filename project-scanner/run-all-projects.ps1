# Main Orchestrator Script
# Orchestrates project discovery and execution

param(
    [string]$ConfigPath = "scanner-config.json",
    [string]$ProjectsOutput = "discovered-projects.json",
    [switch]$SkipScan,
    [switch]$SkipExecution,
    [switch]$SkipConfirmation,
    [switch]$Verbose
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Project Discovery & Execution System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Import logger module
$loggerPath = Join-Path $scriptDir "project-logger.ps1"
if (Test-Path $loggerPath) {
    . $loggerPath
    Initialize-Logger -LogName "run-all-projects"
} else {
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
}

# Step 1: Discovery Scan
if (-not $SkipScan) {
    Write-Log "=== Step 1: Project Discovery ===" -Level "INFO"
    Write-Host ""
    
    $scannerPath = Join-Path $scriptDir "project-scanner.ps1"
    if (-not (Test-Path $scannerPath)) {
        Write-Log "Scanner script not found: $scannerPath" -Level "ERROR"
        exit 1
    }
    
    $scannerParams = @{
        ConfigPath = if ($ConfigPath) { $ConfigPath } else { "scanner-config.json" }
        OutputPath = $ProjectsOutput
    }
    
    if ($Verbose) {
        $scannerParams.Verbose = $true
    }
    
    try {
        $discoveredProjects = & $scannerPath @scannerParams
        
        if ($discoveredProjects) {
            Write-Log "Discovery completed. Found $($discoveredProjects.Count) projects." -Level "SUCCESS"
        } else {
            Write-Log "Discovery completed but no projects were found." -Level "WARNING"
        }
    } catch {
        Write-Log "Error during discovery: $($_.Exception.Message)" -Level "ERROR"
        exit 1
    }
    
    Write-Host ""
} else {
    Write-Log "Skipping discovery scan (SkipScan flag set)" -Level "INFO"
}

# Step 2: Display Discovered Projects
$projectsFile = if ([System.IO.Path]::IsPathRooted($ProjectsOutput)) {
    $ProjectsOutput
} else {
    Join-Path $scriptDir $ProjectsOutput
}

if (Test-Path $projectsFile) {
    Write-Log "=== Step 2: Discovered Projects Summary ===" -Level "INFO"
    Write-Host ""
    
    $projectsData = Get-Content $projectsFile | ConvertFrom-Json
    $projects = $projectsData.Projects
    
    # Ensure projects is always an array
    if ($projects -isnot [Array]) {
        if ($projects) {
            $projects = @($projects)
        } else {
            $projects = @()
        }
    }
    
    Write-Host "Total Projects Discovered: $($projects.Count)" -ForegroundColor Green
    Write-Host ""
    
    # Group by type
    $projectsByType = $projects | Group-Object -Property Type
    
    Write-Host "Projects by Type:" -ForegroundColor Yellow
    foreach ($group in $projectsByType) {
        Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor White
    }
    Write-Host ""
    
    # Show sample projects
    Write-Host "Sample Projects (first 10):" -ForegroundColor Yellow
    $projects | Select-Object -First 10 | ForEach-Object {
        Write-Host "  [$($_.Type)] $($_.Path)" -ForegroundColor Gray
    }
    
    if ($projects.Count -gt 10) {
        Write-Host "  ... and $($projects.Count - 10) more" -ForegroundColor Gray
    }
    
    Write-Host ""
} else {
    Write-Log "Projects file not found: $projectsFile" -Level "ERROR"
    Write-Log "Cannot proceed with execution without discovery results." -Level "ERROR"
    exit 1
}

# Step 3: Execute Projects
if (-not $SkipExecution) {
    Write-Log "=== Step 3: Project Execution ===" -Level "INFO"
    Write-Host ""
    
    $executorPath = Join-Path $scriptDir "project-executor.ps1"
    if (-not (Test-Path $executorPath)) {
        Write-Log "Executor script not found: $executorPath" -Level "ERROR"
        exit 1
    }
    
    $executorParams = @{
        ProjectsFile = $projectsFile
        ConfigPath = if ($ConfigPath) { $ConfigPath } else { "scanner-config.json" }
    }
    
    if ($SkipConfirmation) {
        $executorParams.SkipConfirmation = $true
    }
    
    if ($Verbose) {
        $executorParams.Verbose = $true
    }
    
    try {
        $executionSummary = & $executorPath @executorParams
        
        Write-Host ""
        Write-Log "Execution phase completed." -Level "SUCCESS"
    } catch {
        Write-Log "Error during execution: $($_.Exception.Message)" -Level "ERROR"
        exit 1
    }
} else {
    Write-Log "Skipping execution (SkipExecution flag set)" -Level "INFO"
}

# Step 4: Generate Summary Report
Write-Log "=== Step 4: Summary Report ===" -Level "INFO"
Write-Host ""

$summaryPath = Join-Path $scriptDir "execution-summary.json"
if (Test-Path $summaryPath) {
    $summary = Get-Content $summaryPath | ConvertFrom-Json
    
    Write-Host "Execution Summary:" -ForegroundColor Cyan
    Write-Host "  Total Projects: $($summary.TotalProjects)" -ForegroundColor White
    Write-Host "  Successfully Started: $($summary.SuccessCount)" -ForegroundColor Green
    Write-Host "  Failed: $($summary.FailedCount)" -ForegroundColor $(if ($summary.FailedCount -gt 0) { "Red" } else { "White" })
    Write-Host "  Skipped: $($summary.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Total Duration: $($summary.TotalDuration) seconds" -ForegroundColor White
    Write-Host ""
}

# Export log summary if logger is available
if (Test-Path $loggerPath) {
    $logSummaryPath = Join-Path $scriptDir "log-summary.txt"
    Export-LogSummary -OutputPath $logSummaryPath
}

Write-Log "=== Process Complete ===" -Level "SUCCESS"
Write-Host ""
Write-Host "Output Files:" -ForegroundColor Cyan
Write-Host "  - Discovered Projects: $projectsFile" -ForegroundColor White
Write-Host "  - Execution Summary: $summaryPath" -ForegroundColor White
if (Test-Path $logSummaryPath) {
    Write-Host "  - Log Summary: $logSummaryPath" -ForegroundColor White
}
Write-Host ""


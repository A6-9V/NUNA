# Project Executor Script
# Executes discovered projects in the background using PowerShell jobs

param(
    [string]$ProjectsFile = "discovered-projects.json",
    [string]$ConfigPath = "scanner-config.json",
    [switch]$SkipConfirmation,
    [switch]$Verbose
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ProjectsFile -or -not (Test-Path $ProjectsFile)) {
    $ProjectsFile = Join-Path $scriptDir "discovered-projects.json"
}
if (-not (Test-Path $ProjectsFile)) {
    Write-Error "Projects file not found: $ProjectsFile. Please run project-scanner.ps1 first."
    exit 1
}

if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
    $ConfigPath = Join-Path $scriptDir "scanner-config.json"
}
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

# Load configuration and projects
$config = Get-Content $ConfigPath | ConvertFrom-Json
$projectsData = Get-Content $ProjectsFile | ConvertFrom-Json
$projects = $projectsData.Projects

# Ensure projects is always an array (handle case where JSON has single object)
if ($projects -isnot [Array]) {
    if ($projects) {
        $projects = @($projects)
    } else {
        $projects = @()
    }
}

# Import logger module
$loggerPath = Join-Path $scriptDir "project-logger.ps1"
if (Test-Path $loggerPath) {
    . $loggerPath
    Initialize-Logger -LogName "project-executor"
} else {
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
    function Write-ExecutionLog { param($ProjectPath, $ProjectType, $Status, $Message = "", $ProcessId = "") Write-Log "Execution: $Status - $ProjectPath" -Level $Status }
}

Write-Log "Project Executor initialized" -Level "INFO"
Write-Log "Found $($projects.Count) projects to execute" -Level "INFO"

# Confirmation prompt
if (-not $SkipConfirmation -and $config.executionSettings.requireConfirmation) {
    Write-Host "`nWARNING: This will attempt to execute $($projects.Count) projects in the background." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to cancel, or any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host "`n"
}

$runningJobs = @()
$script:successCount = 0
$script:failedCount = 0
$script:skippedCount = 0

function Test-SystemExecutable {
    param([string]$Path)
    
    $systemPaths = @(
        "Windows\System32",
        "Windows\SysWOW64",
        "Windows\WinSxS",
        "Program Files\Windows"
    )
    
    foreach ($sysPath in $systemPaths) {
        if ($Path -like "*\$sysPath\*") {
            return $true
        }
    }
    
    return $false
}

function Execute-Project {
    param(
        [object]$Project,
        [int]$JobId
    )
    
    $projectPath = $Project.Path
    $projectType = $Project.Type
    $workingDir = if ($Project.WorkingDirectory) { $Project.WorkingDirectory } else { $projectPath }
    
    Write-Log "Starting execution of project $JobId : $projectPath ($projectType)" -Level "INFO"
    
    # Skip system executables if configured
    if ($config.executionSettings.skipSystemExecutables -and (Test-SystemExecutable -Path $projectPath)) {
        Write-ExecutionLog -ProjectPath $projectPath -ProjectType $projectType -Status "SKIPPED" -Message "System executable excluded"
        $script:skippedCount++
        return
    }
    
    # Determine execution command
    $command = $null
    
    if ($projectType -eq "script") {
        $command = $Project.ExecutionCommand
    } elseif ($Project.ExecutionCommand) {
        $command = $Project.ExecutionCommand
    } elseif ($Project.FallbackCommand) {
        $command = $Project.FallbackCommand
    } else {
        Write-ExecutionLog -ProjectPath $projectPath -ProjectType $projectType -Status "SKIPPED" -Message "No execution command available"
        $script:skippedCount++
        return
    }
    
    # Verify working directory exists
    if (-not (Test-Path $workingDir)) {
        Write-ExecutionLog -ProjectPath $projectPath -ProjectType $projectType -Status "FAILED" -Message "Working directory does not exist: $workingDir"
        $script:failedCount++
        return
    }
    
    try {
        # Create PowerShell job for background execution
        $jobScript = @"
            Set-Location '$workingDir'
            $command
"@
        
        $job = Start-Job -ScriptBlock ([scriptblock]::Create($jobScript)) -Name "Project-$JobId-$projectType"
        
        $runningJobs += @{
            Job = $job
            Project = $Project
            JobId = $JobId
            StartTime = Get-Date
        }
        
        Write-ExecutionLog -ProjectPath $projectPath -ProjectType $projectType -Status "STARTED" -Message "Job started" -ProcessId $job.Id.ToString()
        Write-Log "Job $JobId started for $projectPath (Job ID: $($job.Id))" -Level "SUCCESS"
        
    } catch {
        Write-ExecutionLog -ProjectPath $projectPath -ProjectType $projectType -Status "FAILED" -Message $_.Exception.Message
        Write-Log "Failed to start job for $projectPath : $($_.Exception.Message)" -Level "ERROR"
        $script:failedCount++
    }
}

# Execute projects with rate limiting
$maxConcurrent = $config.executionSettings.maxConcurrentJobs
$timeoutSeconds = $config.executionSettings.executionTimeoutSeconds
$startTime = Get-Date

Write-Log "Starting execution of $($projects.Count) projects (max concurrent: $maxConcurrent)..." -Level "INFO"

for ($i = 0; $i -lt $projects.Count; $i++) {
    # Wait if we've reached max concurrent jobs
    while ($runningJobs.Count -ge $maxConcurrent) {
        Start-Sleep -Milliseconds 500
        
        # Check for completed jobs
        $completedJobs = $runningJobs | Where-Object { $_.Job.State -eq "Completed" -or $_.Job.State -eq "Failed" }
        
        foreach ($completedJob in $completedJobs) {
            $job = $completedJob.Job
            $project = $completedJob.Project
            $duration = (Get-Date) - $completedJob.StartTime
            
            if ($job.State -eq "Completed") {
                $script:successCount++
                Write-ExecutionLog -ProjectPath $project.Path -ProjectType $project.Type -Status "SUCCESS" -Message "Completed in $([math]::Round($duration.TotalSeconds, 2))s" -ProcessId $job.Id.ToString()
                Write-Log "Job $($completedJob.JobId) completed successfully: $($project.Path)" -Level "SUCCESS"
            } else {
                $script:failedCount++
                $errorOutput = Receive-Job -Job $job -ErrorAction SilentlyContinue
                Write-ExecutionLog -ProjectPath $project.Path -ProjectType $project.Type -Status "FAILED" -Message "Job failed: $errorOutput" -ProcessId $job.Id.ToString()
                Write-Log "Job $($completedJob.JobId) failed: $($project.Path)" -Level "ERROR"
            }
            
            Remove-Job -Job $job -Force
            $runningJobs = $runningJobs | Where-Object { $_.JobId -ne $completedJob.JobId }
        }
        
        # Check for timed out jobs
        $timedOutJobs = $runningJobs | Where-Object { ((Get-Date) - $_.StartTime).TotalSeconds -gt $timeoutSeconds }
        
        foreach ($timedOutJob in $timedOutJobs) {
            $job = $timedOutJob.Job
            $project = $timedOutJob.Project
            
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force
            
            $script:failedCount++
            Write-ExecutionLog -ProjectPath $project.Path -ProjectType $project.Type -Status "FAILED" -Message "Execution timeout after $timeoutSeconds seconds" -ProcessId $job.Id.ToString()
            Write-Log "Job $($timedOutJob.JobId) timed out: $($project.Path)" -Level "WARNING"
            
            $runningJobs = $runningJobs | Where-Object { $_.JobId -ne $timedOutJob.JobId }
        }
    }
    
    # Execute next project
    Execute-Project -Project $projects[$i] -JobId ($i + 1)
    
    # Small delay between job starts
    Start-Sleep -Milliseconds 100
}

# Wait for remaining jobs to complete
Write-Log "Waiting for remaining $($runningJobs.Count) jobs to complete..." -Level "INFO"

while ($runningJobs.Count -gt 0) {
    Start-Sleep -Seconds 2
    
    $completedJobs = $runningJobs | Where-Object { $_.Job.State -eq "Completed" -or $_.Job.State -eq "Failed" }
    
    foreach ($completedJob in $completedJobs) {
        $job = $completedJob.Job
        $project = $completedJob.Project
        $duration = (Get-Date) - $completedJob.StartTime
        
        if ($job.State -eq "Completed") {
            $script:successCount++
            Write-ExecutionLog -ProjectPath $project.Path -ProjectType $project.Type -Status "SUCCESS" -Message "Completed in $([math]::Round($duration.TotalSeconds, 2))s" -ProcessId $job.Id.ToString()
        } else {
            $script:failedCount++
            $errorOutput = Receive-Job -Job $job -ErrorAction SilentlyContinue
            Write-ExecutionLog -ProjectPath $project.Path -ProjectType $project.Type -Status "FAILED" -Message "Job failed: $errorOutput" -ProcessId $job.Id.ToString()
        }
        
        Remove-Job -Job $job -Force
        $runningJobs = $runningJobs | Where-Object { $_.JobId -ne $completedJob.JobId }
    }
    
    # Check for timed out jobs
    $timedOutJobs = $runningJobs | Where-Object { ((Get-Date) - $_.StartTime).TotalSeconds -gt $timeoutSeconds }
    
    foreach ($timedOutJob in $timedOutJobs) {
        $job = $timedOutJob.Job
        $project = $timedOutJob.Project
        
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force
        
        $script:failedCount++
        Write-ExecutionLog -ProjectPath $project.Path -ProjectType $project.Type -Status "FAILED" -Message "Execution timeout" -ProcessId $job.Id.ToString()
        
        $runningJobs = $runningJobs | Where-Object { $_.JobId -ne $timedOutJob.JobId }
    }
}

$endTime = Get-Date
$totalDuration = $endTime - $startTime

# Summary
Write-Log "`n=== Execution Summary ===" -Level "INFO"
Write-Log "Total projects: $($projects.Count)" -Level "INFO"
Write-Log "Successfully started: $script:successCount" -Level "SUCCESS"
Write-Log "Failed: $script:failedCount" -Level "ERROR"
Write-Log "Skipped: $script:skippedCount" -Level "WARNING"
Write-Log "Total execution time: $([math]::Round($totalDuration.TotalSeconds, 2)) seconds" -Level "INFO"

# Export execution summary
$summaryPath = Join-Path $scriptDir "execution-summary.json"
$summary = @{
    ExecutionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalDuration = [math]::Round($totalDuration.TotalSeconds, 2)
    TotalProjects = $projects.Count
    SuccessCount = $script:successCount
    FailedCount = $script:failedCount
    SkippedCount = $script:skippedCount
    RunningJobs = $runningJobs.Count
}

$summary | ConvertTo-Json | Set-Content -Path $summaryPath
Write-Log "Execution summary exported to: $summaryPath" -Level "SUCCESS"

return $summary


<#
.SYNOPSIS
    AI Agent Activity Logger
.DESCRIPTION
    Logs all AI agent activities to a permanent log file with timestamps and categorization.
    This script can be sourced by other scripts to enable logging.
#>

$ErrorActionPreference = "Continue"

# Setup logging paths
$workspaceRoot = "C:\Users\USER\OneDrive"
$logsDir = Join-Path $workspaceRoot "logs"
$agentLogFile = Join-Path $logsDir "ai-agent-activity.log"

# Create logs directory if it doesn't exist
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Function to write to agent log
function Write-AgentLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG", "TASK_START", "TASK_END")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [string]$ScriptName = $MyInvocation.ScriptName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskName = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $scriptNameOnly = Split-Path -Leaf $ScriptName
    
    # Format log entry
    if ($TaskName) {
        $logEntry = "[$timestamp] [$Level] [$scriptNameOnly] [$TaskName] $Message"
    } else {
        $logEntry = "[$timestamp] [$Level] [$scriptNameOnly] $Message"
    }
    
    # Write to log file
    try {
        Add-Content -Path $agentLogFile -Value $logEntry -Force -ErrorAction SilentlyContinue
    } catch {
        # If logging fails, try to create the file
        try {
            New-Item -ItemType File -Path $agentLogFile -Force | Out-Null
            Add-Content -Path $agentLogFile -Value $logEntry -Force
        } catch {
            # If we still can't log, just continue silently
        }
    }
    
    # Also output to console with appropriate color
    switch ($Level) {
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "TASK_START" { Write-Host $Message -ForegroundColor Cyan }
        "TASK_END" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

# Function to log task start
function Start-AgentTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )
    
    $message = "=== TASK START: $TaskName ==="
    if ($Description) {
        $message += " - $Description"
    }
    Write-AgentLog -Message $message -Level "TASK_START" -TaskName $TaskName
}

# Function to log task end
function Stop-AgentTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("SUCCESS", "FAILED", "WARNING")]
        [string]$Status = "SUCCESS",
        
        [Parameter(Mandatory=$false)]
        [string]$Message = ""
    )
    
    $statusMessage = "=== TASK END: $TaskName - Status: $Status ==="
    if ($Message) {
        $statusMessage += " - $Message"
    }
    
    $level = switch ($Status) {
        "SUCCESS" { "TASK_END" }
        "FAILED" { "ERROR" }
        "WARNING" { "WARNING" }
        default { "TASK_END" }
    }
    
    Write-AgentLog -Message $statusMessage -Level $level -TaskName $TaskName
}

# Export functions for use in other scripts
Export-ModuleMember -Function Write-AgentLog, Start-AgentTask, Stop-AgentTask

# Log that the logger is loaded
Write-AgentLog "Agent logger module loaded" "INFO"






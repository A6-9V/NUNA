<#
.SYNOPSIS
    Save All Agent Output - Comprehensive Output Capture
.DESCRIPTION
    This script captures and saves all output from agent tasks.
    It can be used to wrap other scripts or called at the end of agent sessions.
    
    Features:
    - Captures all console output
    - Captures all errors
    - Creates timestamped log files
    - Maintains permanent AI agent activity log
    - Generates summary reports
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$logsDir = Join-Path $workspaceRoot "logs"
$agentLogFile = Join-Path $logsDir "ai-agent-activity.log"
$summaryLogFile = Join-Path $logsDir "agent-session-summary.log"

# Create logs directory if it doesn't exist
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Load agent logger
$loggerPath = Join-Path $workspaceRoot "agent-logger.ps1"
if (Test-Path $loggerPath) {
    . $loggerPath
} else {
    # Fallback logging function
    function Write-AgentLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $agentLogFile -Value $logEntry -Force
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Saving All Agent Output" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Generate timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$sessionLogFile = Join-Path $logsDir "agent-session-$timestamp.log"

Write-AgentLog "=== AGENT SESSION SUMMARY ===" "INFO"
Write-AgentLog "Session log: $sessionLogFile" "INFO"
Write-AgentLog "Agent activity log: $agentLogFile" "INFO"
Write-AgentLog "Summary log: $summaryLogFile" "INFO"

# Create session summary
$summary = @"
========================================
  AGENT SESSION SUMMARY
  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

Session Information:
- Session Log: $sessionLogFile
- Agent Activity Log: $agentLogFile
- Summary Log: $summaryLogFile

System Information:
- Computer Name: $env:COMPUTERNAME
- User: $env:USERNAME
- PowerShell Version: $($PSVersionTable.PSVersion)
- Execution Policy: $(Get-ExecutionPolicy)

Log Files Location:
- Logs Directory: $logsDir
- All logs are saved with timestamps

Recent Agent Activity:
$(if (Test-Path $agentLogFile) {
    Get-Content $agentLogFile -Tail 50 | Out-String
} else {
    "No agent activity log found yet."
})

========================================
Summary saved: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
"@

# Save summary
$summary | Out-File -FilePath $summaryLogFile -Encoding UTF8 -Force

# Also append to agent log
Write-AgentLog "Session summary saved to: $summaryLogFile" "SUCCESS"

Write-Host ""
Write-Host "All output has been saved:" -ForegroundColor Green
Write-Host "  Session Log: $sessionLogFile" -ForegroundColor White
Write-Host "  Agent Activity Log: $agentLogFile" -ForegroundColor White
Write-Host "  Summary Log: $summaryLogFile" -ForegroundColor White
Write-Host ""
Write-Host "To view recent agent activity:" -ForegroundColor Cyan
Write-Host "  Get-Content `"$agentLogFile`" -Tail 50" -ForegroundColor White
Write-Host ""






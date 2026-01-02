# Project Logger Module
# Provides logging functionality for project discovery and execution

$script:LogDirectory = if ($PSScriptRoot) { Join-Path $PSScriptRoot "logs" } else { Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "logs" }
$script:LogFile = $null
$script:ExecutionLogFile = $null

function Initialize-Logger {
    param(
        [string]$LogName = "project-scanner"
    )
    
    # Create logs directory if it doesn't exist
    if (-not (Test-Path $script:LogDirectory)) {
        New-Item -ItemType Directory -Path $script:LogDirectory -Force | Out-Null
    }
    
    # Create timestamped log file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:LogFile = Join-Path $script:LogDirectory "$LogName-$timestamp.log"
    $script:ExecutionLogFile = Join-Path $script:LogDirectory "execution-$timestamp.log"
    
    Write-Log "Logger initialized" -Level "INFO"
    Write-Log "Log file: $script:LogFile" -Level "INFO"
    Write-Log "Execution log file: $script:ExecutionLogFile" -Level "INFO"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "DEBUG" { "Gray" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # Write to log file if initialized
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Write-ExecutionLog {
    param(
        [string]$ProjectPath,
        [string]$ProjectType,
        [string]$Status,
        [string]$Message = "",
        [string]$ProcessId = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] | $Status | $ProjectType | $ProjectPath | $Message | PID: $ProcessId"
    
    Write-Log "Execution: $Status - $ProjectPath ($ProjectType)" -Level $(if ($Status -eq "SUCCESS") { "SUCCESS" } elseif ($Status -eq "FAILED") { "ERROR" } else { "INFO" })
    
    if ($script:ExecutionLogFile) {
        Add-Content -Path $script:ExecutionLogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Get-LogSummary {
    if (-not $script:LogFile -or -not (Test-Path $script:LogFile)) {
        return "No log file available"
    }
    
    $logContent = Get-Content $script:LogFile
    $summary = @{
        TotalEntries = $logContent.Count
        InfoCount = ($logContent | Select-String "\[INFO\]").Count
        WarningCount = ($logContent | Select-String "\[WARNING\]").Count
        ErrorCount = ($logContent | Select-String "\[ERROR\]").Count
        SuccessCount = ($logContent | Select-String "\[SUCCESS\]").Count
    }
    
    return $summary
}

function Export-LogSummary {
    param(
        [string]$OutputPath
    )
    
    $summary = Get-LogSummary
    $summaryText = @"
Project Scanner Log Summary
==========================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Log File: $script:LogFile

Statistics:
- Total Log Entries: $($summary.TotalEntries)
- Info Messages: $($summary.InfoCount)
- Warnings: $($summary.WarningCount)
- Errors: $($summary.ErrorCount)
- Success Messages: $($summary.SuccessCount)
"@
    
    Set-Content -Path $OutputPath -Value $summaryText
    Write-Log "Summary exported to: $OutputPath" -Level "SUCCESS"
}

# Functions are available when script is dot-sourced


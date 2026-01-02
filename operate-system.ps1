# Operate System with Error Handling and Reporting
# Starts the OS Application Support system with comprehensive error handling

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Restart,
    [switch]$Status,
    [switch]$Report,
    [switch]$FixErrors
)

$ErrorActionPreference = "Continue"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"
$logDir = Join-Path $script:RepoPath "logs"
$errorLog = Join-Path $logDir "errors.log"
$systemLog = Join-Path $logDir "system.log"

# Ensure log directory exists
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $systemLog -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor Cyan }
    }
}

function Write-Error {
    param([string]$Source, [string]$Message, [bool]$Critical = $false)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $severity = if ($Critical) { "CRITICAL" } else { "ERROR" }
    $logEntry = "[$timestamp] [$severity] [$Source] $Message"
    Add-Content -Path $errorLog -Value $logEntry -ErrorAction SilentlyContinue
    Write-Host $logEntry -ForegroundColor $(if ($Critical) { "Red" } else { "Yellow" })
}

function Start-SystemServices {
    Write-Log "Starting OS Application Support system..." "INFO"
    
    $errors = @()
    $servicesStarted = 0
    
    # Start monitoring
    try {
        $monitorScript = Join-Path $script:RepoPath "monitoring\master-monitor.ps1"
        if (Test-Path $monitorScript) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$monitorScript`" -StartAll" -WindowStyle Hidden -ErrorAction Stop
            Write-Log "Monitoring service started" "SUCCESS"
            $servicesStarted++
        } else {
            $errors += "Monitoring script not found: $monitorScript"
            Write-Error "Start-System" "Monitoring script not found" $false
        }
    } catch {
        $errors += "Failed to start monitoring: $_"
        Write-Error "Start-System" "Failed to start monitoring: $_" $false
    }
    
    # Start trading system
    try {
        $tradingScript = Join-Path $script:RepoPath "trading-system\trading-manager.ps1"
        if (Test-Path $tradingScript) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tradingScript`" start" -WindowStyle Hidden -ErrorAction Stop
            Write-Log "Trading system started" "SUCCESS"
            $servicesStarted++
        } else {
            $errors += "Trading system script not found: $tradingScript"
            Write-Error "Start-System" "Trading system script not found" $false
        }
    } catch {
        $errors += "Failed to start trading system: $_"
        Write-Error "Start-System" "Failed to start trading system: $_" $false
    }
    
    # Start security monitoring
    try {
        $securityScript = Join-Path $script:RepoPath "security\security-monitor.ps1"
        if (Test-Path $securityScript) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$securityScript`" -Continuous" -WindowStyle Hidden -ErrorAction Stop
            Write-Log "Security monitoring started" "SUCCESS"
            $servicesStarted++
        } else {
            $errors += "Security script not found: $securityScript"
            Write-Error "Start-System" "Security script not found" $false
        }
    } catch {
        $errors += "Failed to start security monitoring: $_"
        Write-Error "Start-System" "Failed to start security monitoring: $_" $false
    }
    
    Write-Log "Started $servicesStarted service(s)" "SUCCESS"
    if ($errors.Count -gt 0) {
        Write-Log "$($errors.Count) error(s) occurred during startup" "WARNING"
    }
    
    return @{
        Success = $servicesStarted
        Errors = $errors
    }
}

function Stop-SystemServices {
    Write-Log "Stopping OS Application Support system..." "INFO"
    
    try {
        $processes = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -like "*OS-application-support*" -or
            $_.CommandLine -like "*monitor*" -or
            $_.CommandLine -like "*trading*" -or
            $_.CommandLine -like "*security*"
        }
        
        if ($processes) {
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Log "Stopped $($processes.Count) process(es)" "SUCCESS"
        } else {
            Write-Log "No processes found to stop" "INFO"
        }
    } catch {
        Write-Error "Stop-System" "Failed to stop services: $_" $false
    }
}

function Get-SystemStatus {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "OS Application Support - System Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check repository
    if (Test-Path $script:RepoPath) {
        Write-Host "Repository: [OK]" -ForegroundColor Green
    } else {
        Write-Host "Repository: [MISSING]" -ForegroundColor Red
    }
    
    # Check processes
    $processes = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*OS-application-support*"
    }
    Write-Host "Active Processes: $($processes.Count)" -ForegroundColor $(if ($processes.Count -gt 0) { "Green" } else { "Yellow" })
    
    # Check scheduled task
    try {
        $task = Get-ScheduledTask -TaskName "OS-Application-Support-Startup" -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host "Auto-Startup: [OK] ($($task.State))" -ForegroundColor Green
        } else {
            Write-Host "Auto-Startup: [NOT CONFIGURED]" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Auto-Startup: [CHECK FAILED]" -ForegroundColor Yellow
    }
    
    # Check for recent errors
    if (Test-Path $errorLog) {
        $recentErrors = Get-Content $errorLog -Tail 5 -ErrorAction SilentlyContinue
        if ($recentErrors) {
            Write-Host ""
            Write-Host "Recent Errors:" -ForegroundColor Yellow
            $recentErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
    
    Write-Host ""
}

function Generate-Report {
    Write-Log "Generating system report..." "INFO"
    $reporter = Join-Path $script:RepoPath "scripts\system-reporter.ps1"
    if (Test-Path $reporter) {
        & $reporter -IncludeErrors
    } else {
        Write-Error "Report" "Reporter script not found" $false
    }
}

function Fix-CommonErrors {
    Write-Log "Attempting to fix common errors..." "INFO"
    
    # Fix 1: Ensure directories exist
    $directories = @("logs", "config", "reports")
    foreach ($dir in $directories) {
        $dirPath = Join-Path $script:RepoPath $dir
        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            Write-Log "Created directory: $dir" "SUCCESS"
        }
    }
    
    # Fix 2: Check Git repository
    Set-Location $script:RepoPath
    if (-not (Test-Path ".git")) {
        git init | Out-Null
        Write-Log "Initialized Git repository" "SUCCESS"
    }
    
    Write-Log "Error fixing complete" "SUCCESS"
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OS Application Support - System Operator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($Status) {
    Get-SystemStatus
} elseif ($Report) {
    Generate-Report
} elseif ($FixErrors) {
    Fix-CommonErrors
} elseif ($Stop) {
    Stop-SystemServices
} elseif ($Restart) {
    Stop-SystemServices
    Start-Sleep -Seconds 2
    Start-SystemServices
} elseif ($Start) {
    $result = Start-SystemServices
    Write-Host ""
    Write-Host "Startup Summary:" -ForegroundColor Cyan
    Write-Host "  Services Started: $($result.Success)" -ForegroundColor Green
    if ($result.Errors.Count -gt 0) {
        Write-Host "  Errors: $($result.Errors.Count)" -ForegroundColor Yellow
    }
} else {
    # Default: Start system
    $result = Start-SystemServices
    Start-Sleep -Seconds 2
    Get-SystemStatus
    Write-Host ""
    Write-Host "Use -Report to generate detailed report" -ForegroundColor Yellow
    Write-Host "Use -Status to check current status" -ForegroundColor Yellow
}

Write-Host ""

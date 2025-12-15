# Setup Startup Disk Monitor with Status Logging
# This version writes status to a file we can read

param(
    [string]$RebootTime = "03:00"
)

$logFile = Join-Path $env:TEMP "disk-monitor-setup.log"
$scriptPath = Join-Path $env:USERPROFILE "OneDrive\disk-health-monitor.ps1"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $Message -ForegroundColor $Color
}

Write-Log "========================================" "Cyan"
Write-Log "  Startup Disk Monitor Setup" "Cyan"
Write-Log "========================================" "Cyan"
Write-Log ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "ERROR: This script requires administrator privileges." "Red"
    Write-Log "Please run PowerShell as Administrator and try again." "Yellow"
    exit 1
}

Write-Log "Running with administrator privileges" "Green"

# Verify script exists
if (-not (Test-Path $scriptPath)) {
    Write-Log "ERROR: Disk health monitor script not found: $scriptPath" "Red"
    exit 1
}

Write-Log "Found disk-health-monitor.ps1 script" "Green"

$taskName = "StartupDiskHealthMonitor"
$taskPath = "\SystemMaintenance\"
$fullTaskName = "$taskPath$taskName"

# Remove existing task if it exists
Write-Log "Removing existing task if present..." "Yellow"
schtasks /delete /tn "$fullTaskName" /f 2>&1 | Out-Null

# Create task using schtasks.exe
Write-Log "Creating startup disk monitor task..." "Yellow"
$action = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -ExportReport"

$createTaskCmd = @"
schtasks /create /tn "$fullTaskName" /tr "$action" /sc onstart /ru SYSTEM /rl HIGHEST /f
"@

$result = cmd /c $createTaskCmd 2>&1
$taskExitCode = $LASTEXITCODE

if ($taskExitCode -eq 0) {
    Write-Log "SUCCESS: Startup disk monitor task created" "Green"
    Write-Log "  Task Name: $fullTaskName" "White"
    Write-Log "  Script: $scriptPath" "White"
} else {
    Write-Log "ERROR: Failed to create scheduled task" "Red"
    Write-Log "  Error output: $result" "Red"
    exit 1
}

# Setup daily reboot schedule
Write-Log ""
Write-Log "Setting up daily reboot schedule..." "Yellow"

$rebootTaskName = "DailySystemReboot"
$rebootMessage = "Scheduled daily reboot - System will restart in 60 seconds"

# Remove existing reboot task if it exists
try {
    $existingRebootTask = Get-ScheduledTask -TaskName $rebootTaskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if ($existingRebootTask) {
        Unregister-ScheduledTask -TaskName $rebootTaskName -TaskPath $taskPath -Confirm:$false -ErrorAction SilentlyContinue
    }
} catch {
    # Task doesn't exist, continue
}

try {
    # Create task action
    $rebootAction = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 60 /c `"$rebootMessage`""
    
    # Create trigger (daily at specified time)
    $rebootTrigger = New-ScheduledTaskTrigger -Daily -At $RebootTime
    
    # Create task settings
    $rebootSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
    
    # Create task principal (run as SYSTEM)
    $rebootPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask -TaskName $rebootTaskName -TaskPath $taskPath -Action $rebootAction -Trigger $rebootTrigger -Settings $rebootSettings -Principal $rebootPrincipal -Description "Daily system reboot for maintenance" | Out-Null
    
    Write-Log "SUCCESS: Daily reboot schedule created" "Green"
    Write-Log "  Reboot Time: $RebootTime (Daily)" "White"
} catch {
    Write-Log "WARNING: Failed to create reboot schedule" "Yellow"
    Write-Log "  Error: $_" "Yellow"
}

Write-Log ""
Write-Log "========================================" "Cyan"
Write-Log "  Setup Complete" "Cyan"
Write-Log "========================================" "Cyan"
Write-Log "STATUS: SUCCESS" "Green"



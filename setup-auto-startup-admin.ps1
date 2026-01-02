# Auto-Startup Setup (Administrator)
# Sets up automatic startup for all services as administrator

param(
    [switch]$Remove,
    [switch]$Check
)

$ErrorActionPreference = "Continue"

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[WARNING] Not running as administrator. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Wait
    exit
}

$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"
$startupScript = Join-Path $script:RepoPath "startup-all.ps1"
$taskName = "OS-Application-Support-Startup"
$taskDescription = "Starts OS Application Support system automatically on boot"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto-Startup Setup (Administrator)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($Check) {
    Write-Host "[INFO] Checking scheduled task..." -ForegroundColor Yellow
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "    [OK] Task exists: $taskName" -ForegroundColor Green
        Write-Host "    State: $($task.State)" -ForegroundColor Yellow
    } else {
        Write-Host "    [WARNING] Task not found" -ForegroundColor Yellow
    }
    exit
}

if ($Remove) {
    Write-Host "[INFO] Removing scheduled task..." -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "    [OK] Task removed" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Task may not exist: $_" -ForegroundColor Yellow
    }
    exit
}

# Create startup script if it doesn't exist
if (-not (Test-Path $startupScript)) {
    Write-Host "[INFO] Creating startup script..." -ForegroundColor Yellow
    $startupContent = @'
# Auto-Startup Script
# Starts all OS Application Support services

$ErrorActionPreference = "Continue"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"

Write-Host "Starting OS Application Support System..." -ForegroundColor Cyan

# Start monitoring
$monitorScript = Join-Path $script:RepoPath "monitoring\master-monitor.ps1"
if (Test-Path $monitorScript) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$monitorScript`" -StartAll" -WindowStyle Hidden
    Write-Host "[OK] Monitoring started" -ForegroundColor Green
}

# Start trading system
$tradingScript = Join-Path $script:RepoPath "trading-system\trading-manager.ps1"
if (Test-Path $tradingScript) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tradingScript`" start" -WindowStyle Hidden
    Write-Host "[OK] Trading system started" -ForegroundColor Green
}

# Start security monitoring
$securityScript = Join-Path $script:RepoPath "security\security-monitor.ps1"
if (Test-Path $securityScript) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$securityScript`" -Continuous" -WindowStyle Hidden
    Write-Host "[OK] Security monitoring started" -ForegroundColor Green
}

Write-Host "[OK] All services started" -ForegroundColor Green
'@
    Set-Content -Path $startupScript -Value $startupContent
    Write-Host "    [OK] Startup script created" -ForegroundColor Green
}

# Create scheduled task
Write-Host "[INFO] Creating scheduled task..." -ForegroundColor Yellow
try {
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$startupScript`"" -WorkingDirectory $script:RepoPath
    
    # Create trigger (on system startup)
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    # Create principal (run as current user with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Register task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $taskDescription | Out-Null
    
    Write-Host "    [OK] Scheduled task created" -ForegroundColor Green
    Write-Host "    Task Name: $taskName" -ForegroundColor Yellow
    Write-Host "    Description: $taskDescription" -ForegroundColor Yellow
    Write-Host "    Trigger: At system startup" -ForegroundColor Yellow
    Write-Host "    Run Level: Highest (Administrator)" -ForegroundColor Yellow
    
} catch {
    Write-Host "    [ERROR] Failed to create scheduled task: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Auto-startup setup complete!" -ForegroundColor Green
Write-Host "[INFO] System will start automatically on boot" -ForegroundColor Cyan

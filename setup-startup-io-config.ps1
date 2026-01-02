#Requires -Version 5.1
<#
.SYNOPSIS
    Setup Startup I/O Configuration
.DESCRIPTION
    Configures system to use E: drive and USB drives for I/O at startup
    Sets up scheduled tasks and environment for I/O redirection
#>

$ErrorActionPreference = "Continue"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires administrator privileges" -ForegroundColor Red
    Write-Host "[INFO] Please run as administrator" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Startup I/O Configuration Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = $PSScriptRoot
$ioSetupScript = Join-Path $scriptPath "setup-io-redirection.ps1"
$protectionScript = Join-Path $scriptPath "protect-cd-drives.ps1"

# ============================================
# STEP 1: Run I/O Redirection Setup
# ============================================
Write-Host "[1/4] Running I/O redirection setup..." -ForegroundColor Yellow

if (Test-Path $ioSetupScript) {
    & $ioSetupScript
    Write-Host ""
} else {
    Write-Host "[WARNING] I/O setup script not found: $ioSetupScript" -ForegroundColor Yellow
}

# ============================================
# STEP 2: Create Startup Task for I/O Setup
# ============================================
Write-Host "[2/4] Creating startup task for I/O configuration..." -ForegroundColor Yellow

$taskName = "SystemMaintenance\StartupIOConfiguration"
$taskDescription = "Configures I/O redirection to E: drive and USB drives at startup. Protects C: and D: drives."

try {
    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "  [INFO] Removed existing task" -ForegroundColor Gray
    }
    
    # Create task action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-File", "`"$ioSetupScript`""
    )
    
    # Create task trigger (at startup)
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Create task principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description $taskDescription `
        -ErrorAction Stop
    
    Write-Host "  [OK] Startup task created successfully" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to create startup task: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# STEP 3: Create Drive Protection Monitor Task
# ============================================
Write-Host "[3/4] Creating drive protection monitor task..." -ForegroundColor Yellow

$protectionTaskName = "SystemMaintenance\DriveProtectionMonitor"
$protectionTaskDescription = "Monitors C: and D: drives for heavy I/O and alerts when protection is needed."

try {
    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $protectionTaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $protectionTaskName -Confirm:$false
        Write-Host "  [INFO] Removed existing task" -ForegroundColor Gray
    }
    
    # Create task action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-File", "`"$protectionScript`""
    )
    
    # Create task trigger (at startup, delayed by 2 minutes)
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $trigger.Delay = "PT2M"  # 2 minutes delay
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Create task principal
    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask `
        -TaskName $protectionTaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description $protectionTaskDescription `
        -ErrorAction Stop
    
    Write-Host "  [OK] Protection monitor task created successfully" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to create protection monitor task: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# STEP 4: Configure System Environment
# ============================================
Write-Host "[4/4] Configuring system environment..." -ForegroundColor Yellow

# Set system-wide environment variables (requires admin)
$envVars = @{
    "IO_WORK_DIR" = "E:\IO-Work"
    "IO_TEMP_DIR" = "E:\IO-Work\Temp"
    "IO_CACHE_DIR" = "E:\IO-Work\Cache"
    "IO_LOGS_DIR" = "E:\IO-Work\Logs"
    "PROTECTED_DRIVES" = "C:,D:"
    "IO_DRIVES" = "E:"
}

foreach ($var in $envVars.GetEnumerator()) {
    try {
        [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "  [OK] Set system variable: $($var.Key)" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Could not set system variable $($var.Key): $_" -ForegroundColor Yellow
        # Fallback to user variable
        [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, [System.EnvironmentVariableTarget]::User)
        Write-Host "  [INFO] Set as user variable instead" -ForegroundColor Gray
    }
}

Write-Host ""

# ============================================
# Final Summary
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tasks Created:" -ForegroundColor Yellow
Write-Host "  - StartupIOConfiguration (runs at startup)" -ForegroundColor Green
Write-Host "  - DriveProtectionMonitor (monitors C: and D:)" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Heavy I/O: E: drive + USB drives" -ForegroundColor Green
Write-Host "  Protected: C: (OS), D:" -ForegroundColor Yellow
Write-Host "  Environment Variables: Set (system-wide)" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your computer to activate startup tasks" -ForegroundColor Cyan
Write-Host "  2. I/O operations will automatically use E: drive" -ForegroundColor Cyan
Write-Host "  3. C: and D: drives will be monitored and protected" -ForegroundColor Cyan
Write-Host ""


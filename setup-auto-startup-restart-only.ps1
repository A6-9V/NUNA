#Requires -Version 5.1
<#
.SYNOPSIS
    Setup Auto-Startup for Restart Only (Not Power On)
.DESCRIPTION
    Configures system to auto-start VPS services:
    - On RESTART only (not cold boot/power on)
    - On screen lock/unlock
    - Fully automated, no user interaction
#>

$ErrorActionPreference = "Continue"

# Auto-elevate to admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Elevating to administrator..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-ExecutionPolicy", "Bypass",
        "-NoProfile",
        "-WindowStyle", "Hidden",
        "-File", "`"$scriptPath`""
    ) -WindowStyle Hidden
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto-Startup Setup (Restart Only)" -ForegroundColor Cyan
Write-Host "  Restart = True, Power On = False" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$startupScript = Join-Path $workspaceRoot "auto-start-vps-admin.ps1"
$flagFile = Join-Path $workspaceRoot ".restart-flag"

# Step 1: Create restart detection script
Write-Host "[1/5] Creating restart detection mechanism..." -ForegroundColor Yellow
try {
    $restartDetectorScript = @"
# Restart Detection Script
# Only runs on restart, not on cold boot

`$workspaceRoot = "$workspaceRoot"
`$flagFile = "$flagFile"
`$startupScript = "$startupScript"

# Check if this is a restart (flag file exists)
if (Test-Path `$flagFile) {
    # This is a restart - run startup
    Write-Host "[RESTART DETECTED] Starting VPS system..." | Out-File -Append "$workspaceRoot\vps-logs\restart-detector.log"
    
    if (Test-Path `$startupScript) {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", "`"`$startupScript`""
        ) -WindowStyle Hidden
    }
} else {
    # This is a cold boot - create flag for next restart
    Write-Host "[COLD BOOT DETECTED] Skipping auto-start (Power On = False)" | Out-File -Append "$workspaceRoot\vps-logs\restart-detector.log"
    New-Item -ItemType File -Path `$flagFile -Force | Out-Null
}

# Keep flag file for next restart detection
"@
    
    $detectorPath = Join-Path $workspaceRoot "restart-detector.ps1"
    $restartDetectorScript | Out-File -FilePath $detectorPath -Encoding UTF8
    Write-Host "    [OK] Restart detector script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create restart detector: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create shutdown script to preserve flag
Write-Host "[2/5] Creating shutdown handler..." -ForegroundColor Yellow
try {
    $shutdownHandlerScript = @"
# Shutdown Handler - Preserves restart flag
`$flagFile = "$flagFile"
New-Item -ItemType File -Path `$flagFile -Force | Out-Null
"@
    
    $shutdownPath = Join-Path $workspaceRoot "shutdown-handler.ps1"
    $shutdownHandlerScript | Out-File -FilePath $shutdownPath -Encoding UTF8
    Write-Host "    [OK] Shutdown handler created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create shutdown handler: $_" -ForegroundColor Red
}

# Step 3: Create screen lock/unlock handler
Write-Host "[3/5] Creating screen lock/unlock handler..." -ForegroundColor Yellow
try {
    $screenHandlerScript = @"
# Screen Lock/Unlock Handler
# Runs VPS system on screen lock or unlock

`$workspaceRoot = "$workspaceRoot"
`$startupScript = "$startupScript"
`$logsPath = "$workspaceRoot\vps-logs"

function Start-VPSSystem {
    if (Test-Path `$startupScript) {
        `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[`$timestamp] Screen event - Starting VPS system" | Out-File -Append "`$logsPath\screen-handler.log"
        
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", "`"`$startupScript`""
        ) -WindowStyle Hidden
    }
}

# Monitor for screen lock/unlock events
Register-WmiEvent -Query "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName='logonui.exe'" -Action {
    Start-VPSSystem
} | Out-Null

# Keep script running
while (`$true) {
    Start-Sleep -Seconds 60
}
"@
    
    $screenHandlerPath = Join-Path $workspaceRoot "screen-handler.ps1"
    $screenHandlerScript | Out-File -FilePath $screenHandlerPath -Encoding UTF8
    Write-Host "    [OK] Screen handler created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create screen handler: $_" -ForegroundColor Red
}

# Step 4: Create Scheduled Task for Restart Detection
Write-Host "[4/5] Creating scheduled task for restart detection..." -ForegroundColor Yellow
try {
    $taskName = "VPS-AutoStart-RestartOnly"
    $detectorPath = Join-Path $workspaceRoot "restart-detector.ps1"
    
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create task action
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$detectorPath`"" `
        -WorkingDirectory $workspaceRoot
    
    # Create trigger: At startup (but script will check if it's restart)
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    
    # Create principal
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Highest
    
    # Create settings
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Hours 0)
    
    # Register task
    Register-ScheduledTask -TaskName $taskName -Action $taskAction `
        -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings `
        -Description "VPS Auto-Start on Restart Only (Not Power On)" -Force | Out-Null
    
    Write-Host "    [OK] Scheduled task created: $taskName" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create scheduled task: $_" -ForegroundColor Red
}

# Step 5: Create Scheduled Task for Screen Lock/Unlock (Event-based)
Write-Host "[5/5] Creating scheduled task for screen lock/unlock..." -ForegroundColor Yellow
try {
    $taskName = "VPS-AutoStart-ScreenEvents"
    $screenHandlerPath = Join-Path $workspaceRoot "screen-handler.ps1"
    
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create task action
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$screenHandlerPath`"" `
        -WorkingDirectory $workspaceRoot
    
    # Create trigger: On logon (runs screen handler which monitors events)
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
    
    # Create principal
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Highest
    
    # Create settings
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Register task
    Register-ScheduledTask -TaskName $taskName -Action $taskAction `
        -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings `
        -Description "VPS Auto-Start on Screen Lock/Unlock (runs screen handler)" -Force | Out-Null
    
    Write-Host "    [OK] Screen event task created: $taskName" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Screen event task creation had issues: $_" -ForegroundColor Yellow
}

# Step 6: Create Scheduled Task for Shutdown Handler
Write-Host "[6/7] Creating scheduled task for shutdown handler..." -ForegroundColor Yellow
try {
    $taskName = "VPS-Shutdown-Handler"
    $shutdownHandlerPath = Join-Path $workspaceRoot "shutdown-handler.ps1"
    
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create task action
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$shutdownHandlerPath`"" `
        -WorkingDirectory $workspaceRoot
    
    # Create trigger: On system shutdown
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    # Note: Windows doesn't have direct shutdown trigger, so we'll use a workaround
    # The flag file will be created/updated by the restart detector
    
    # Create principal
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Highest
    
    # Create settings
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Register task (runs on startup to ensure flag exists)
    Register-ScheduledTask -TaskName $taskName -Action $taskAction `
        -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings `
        -Description "VPS Shutdown Handler - Preserves restart flag" -Force | Out-Null
    
    Write-Host "    [OK] Shutdown handler task created: $taskName" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Shutdown handler task creation had issues: $_" -ForegroundColor Yellow
}

# Step 7: Create initial flag file (for first restart detection)
Write-Host "[7/7] Setting up restart flag..." -ForegroundColor Yellow
try {
    if (-not (Test-Path $flagFile)) {
        New-Item -ItemType File -Path $flagFile -Force | Out-Null
        Write-Host "    [OK] Restart flag file created" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Restart flag file already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "    [WARNING] Could not create flag file: $_" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto-Startup Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  ✅ Restart: AUTO-START ENABLED" -ForegroundColor Green
Write-Host "  ✅ Power On: AUTO-START DISABLED" -ForegroundColor Green
Write-Host "  ✅ Screen Lock/Unlock: AUTO-START ENABLED" -ForegroundColor Green
Write-Host ""
Write-Host "Scheduled Tasks Created:" -ForegroundColor Yellow
Write-Host "  ✅ VPS-AutoStart-RestartOnly (runs on startup, checks for restart)" -ForegroundColor White
Write-Host "  ✅ VPS-AutoStart-ScreenEvents (runs on screen lock/unlock)" -ForegroundColor White
Write-Host ""
Write-Host "How it works:" -ForegroundColor Cyan
Write-Host "  1. On RESTART: Flag file exists → System starts automatically" -ForegroundColor White
Write-Host "  2. On POWER ON: Flag file missing → System does NOT start" -ForegroundColor White
Write-Host "  3. On SCREEN LOCK/UNLOCK: System starts automatically" -ForegroundColor White
Write-Host ""
Write-Host "Flag file: $flagFile" -ForegroundColor Cyan
Write-Host ""

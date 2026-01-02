#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Master Trading System Orchestrator
.DESCRIPTION
    Coordinates all trading system components:
    - Python bridge service
    - MQL5 monitoring
    - VPS sync (if configured)
    - Health monitoring
    - Automatic recovery
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = $PSScriptRoot
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$logsPath = Join-Path $tradingBridgePath "logs"
$vpsServicesPath = Join-Path $workspaceRoot "vps-services"

# Create logs directory
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

$logFile = Join-Path $logsPath "orchestrator_$(Get-Date -Format 'yyyyMMdd').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $logMessage -ForegroundColor $color
}

function Test-DriveHealth {
    param(
        [string]$DriveLetter,
        [int]$MinFreePercent = 10
    )

    try {
        $deviceId = "$DriveLetter:"
        $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$deviceId'" -ErrorAction Stop

        if (-not $drive -or -not $drive.Size -or -not $drive.FreeSpace) {
            Write-Log "Drive $DriveLetter: unable to read size/free space" "WARNING"
            return
        }

        $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)

        if ($freePercent -lt $MinFreePercent) {
            Write-Log "Drive $DriveLetter: LOW free space ($freePercent`%)" "WARNING"
        } else {
            Write-Log "Drive $DriveLetter: healthy free space ($freePercent`%)" "SUCCESS"
        }
    } catch {
        Write-Log "Drive $DriveLetter: health check failed: $_" "WARNING"
    }
}

function Ensure-ProcessRunning {
    param(
        [string]$ProcessName,
        [string[]]$PossiblePaths
    )

    try {
        $existing = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($existing) {
            return
        }
    } catch {
        Write-Log "Error checking process $ProcessName: $_" "WARNING"
        return
    }

    if (-not $PossiblePaths -or $PossiblePaths.Count -eq 0) {
        Write-Log "$ProcessName not running and no start paths configured" "INFO"
        return
    }

    foreach ($path in $PossiblePaths) {
        try {
            if (Test-Path $path) {
                Write-Log "$ProcessName not running - attempting start from $path" "WARNING"
                try {
                    Start-Process -FilePath $path -ErrorAction Stop | Out-Null
                    Write-Log "$ProcessName start requested" "SUCCESS"
                    return
                } catch {
                    Write-Log "Failed to start $ProcessName from $path: $_" "ERROR"
                }
            }
        } catch {
            Write-Log "Error validating path for $ProcessName ($path): $_" "WARNING"
        }
    }
}

Write-Log "========================================"
Write-Log "Master Trading Orchestrator Started" "SUCCESS"
Write-Log "========================================"

# Step 1: Start Python Bridge Service
Write-Log "Step 1: Starting Python Bridge Service..."
$startScript = Join-Path $tradingBridgePath "start-background.ps1"
if (Test-Path $startScript) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $startScript
        ) -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 3
        Write-Log "Python bridge service started" "SUCCESS"
    } catch {
        Write-Log "Failed to start Python bridge service: $_" "ERROR"
    }
} else {
    Write-Log "Python bridge start script not found" "WARNING"
}

# Step 2: Start MQL5 Terminal (if Exness service exists)
Write-Log "Step 2: Checking MQL5 Terminal..."
$exnessService = Join-Path $vpsServicesPath "exness-service.ps1"
if (Test-Path $exnessService) {
    try {
        $exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
        if (-not $exnessProcess) {
            Start-Process powershell.exe -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Hidden",
                "-File", $exnessService
            ) -WindowStyle Hidden | Out-Null
            Write-Log "MQL5 Terminal service started" "SUCCESS"
        } else {
            Write-Log "MQL5 Terminal already running" "SUCCESS"
        }
    } catch {
        Write-Log "Failed to start MQL5 Terminal: $_" "WARNING"
    }
} else {
    Write-Log "Exness service not found (optional)" "WARNING"
}

# Step 3: Start VPS Sync (if configured)
Write-Log "Step 3: Checking VPS Sync..."
$tradingBridgeService = Join-Path $vpsServicesPath "trading-bridge-service.ps1"
if (Test-Path $tradingBridgeService) {
    try {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $tradingBridgeService
        ) -WindowStyle Hidden | Out-Null
        Write-Log "VPS sync service started" "SUCCESS"
    } catch {
        Write-Log "Failed to start VPS sync: $_" "WARNING"
    }
} else {
    Write-Log "VPS sync service not configured (optional)" "WARNING"
}

# Step 4: Health Monitoring Loop
Write-Log "Step 4: Starting health monitoring..."
Write-Log "Orchestrator running - monitoring system health"

# Load disk performance monitoring helper
$ensurePriorityScript = Join-Path $workspaceRoot "ensure-trading-priority.ps1"

function Test-DiskPerformanceForTrading {
    try {
        $counter = Get-Counter "\PhysicalDisk(0 C: D:)\% Disk Time" -ErrorAction SilentlyContinue
        if ($counter) {
            $diskTime = [math]::Round($counter.CounterSamples[0].CookedValue, 1)
            
            if ($diskTime -gt 90) {
                Write-Log "Disk 0 active time is ${diskTime}% - may affect trading" "WARNING"
                
                # Set trading process priorities
                if (Test-Path $ensurePriorityScript) {
                    try {
                        & $ensurePriorityScript -SetPriority -ErrorAction SilentlyContinue | Out-Null
                        Write-Log "Trading process priorities optimized" "SUCCESS"
                    } catch {
                        Write-Log "Could not optimize trading priorities: $_" "WARNING"
                    }
                }
                
                return $false
            }
        }
        return $true
    } catch {
        Write-Log "Error checking disk performance: $_" "WARNING"
        return $true  # Assume OK if check fails
    }
}

$monitoring = $true
while ($monitoring) {
    Start-Sleep -Seconds 60  # Check every minute
    
    # Check disk performance for trading
    Test-DiskPerformanceForTrading
    
    # Check Python service
    $pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*background_service.py*"
    }
    
    if (-not $pythonProcess) {
        Write-Log "Python service not running - attempting restart..." "WARNING"
        if (Test-Path $startScript) {
            try {
                Start-Process powershell.exe -ArgumentList @(
                    "-ExecutionPolicy", "Bypass",
                    "-WindowStyle", "Hidden",
                    "-File", $startScript
                ) -WindowStyle Hidden | Out-Null
                Write-Log "Python service restarted" "SUCCESS"
            } catch {
                Write-Log "Failed to restart Python service: $_" "ERROR"
            }
        }
    }
    
    # Check MQL5 Terminal
    $mt5Process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not $mt5Process -and (Test-Path $exnessService)) {
        Write-Log "MQL5 Terminal not running - attempting restart..." "WARNING"
        try {
            Start-Process powershell.exe -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Hidden",
                "-File", $exnessService
            ) -WindowStyle Hidden | Out-Null
            Write-Log "MQL5 Terminal restarted" "SUCCESS"
        } catch {
            Write-Log "Failed to restart MQL5 Terminal: $_" "WARNING"
        }
    }

    # Check critical drives (C, E, F)
    Test-DriveHealth -DriveLetter "C" -MinFreePercent 10

    foreach ($driveLetter in @("E", "F")) {
        try {
            if (Test-Path "$driveLetter`:") {
                Test-DriveHealth -DriveLetter $driveLetter -MinFreePercent 10
            } else {
                Write-Log "Drive $driveLetter: not present (skipping health check)" "INFO"
            }
        } catch {
            Write-Log "Drive $driveLetter: presence check failed: $_" "WARNING"
        }
    }

    # Check Cursor IDE status (optional, informational only)
    try {
        $cursorProcess = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue
        if ($cursorProcess) {
            Write-Log "Cursor IDE running (PID: $($cursorProcess.Id))"
        } else {
            Write-Log "Cursor IDE not running (not required for trading)" "INFO"
        }
    } catch {
        Write-Log "Cursor IDE process check failed: $_" "WARNING"
    }

    # Check Outlook status (email alerts)
    try {
        $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
        if ($outlookProcess) {
            Write-Log "Outlook running (PID: $($outlookProcess.Id))"
        } else {
            Write-Log "Outlook not running - email alerts may be offline" "INFO"
        }
    } catch {
        Write-Log "Outlook process check failed: $_" "WARNING"
    }

    # Ensure cloud sync services (OneDrive, Google Drive) are running
    $oneDrivePaths = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe"
    )
    Ensure-ProcessRunning -ProcessName "OneDrive" -PossiblePaths $oneDrivePaths

    $googleDrivePaths = @(
        "$env:LOCALAPPDATA\Programs\Google\Drive\googledrivesync.exe",
        "$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe",
        "$env:PROGRAMFILES\Google\Drive\googledrivesync.exe"
    )
    Ensure-ProcessRunning -ProcessName "googledrivesync" -PossiblePaths $googleDrivePaths
}

Write-Log "Orchestrator stopped"


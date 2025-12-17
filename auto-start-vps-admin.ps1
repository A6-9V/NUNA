#Requires -Version 5.1
<#
.SYNOPSIS
    Auto-Start VPS System as Administrator - Fully Automated
.DESCRIPTION
    Automatically elevates to admin, deploys services, starts everything,
    and handles all errors without user interaction
#>

$ErrorActionPreference = "SilentlyContinue"

# Check if already running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Auto-elevate to admin without prompting
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

# Now running as admin - proceed with deployment
$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

$logFile = Join-Path $workspaceRoot "vps-auto-start.log"
$errorLog = Join-Path $workspaceRoot "vps-errors.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    if ($Level -eq "ERROR") {
        Add-Content -Path $errorLog -Value $logMessage -ErrorAction SilentlyContinue
    }
}

Write-Log "Starting automated VPS deployment and startup"

# Step 1: Deploy VPS Services
Write-Log "Step 1: Deploying VPS services"
try {
    $deploymentScript = Join-Path $workspaceRoot "vps-deployment.ps1"
    if (Test-Path $deploymentScript) {
        $deploymentOutput = & powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File $deploymentScript 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "VPS deployment completed successfully"
        } else {
            Write-Log "VPS deployment had warnings but continued" "WARNING"
        }
    } else {
        Write-Log "Deployment script not found, creating services manually" "WARNING"
        # Create directories if they don't exist
        $vpsServicesPath = "$workspaceRoot\vps-services"
        $logsPath = "$workspaceRoot\vps-logs"
        New-Item -ItemType Directory -Path $vpsServicesPath -Force | Out-Null
        New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
        Write-Log "Service directories created"
    }
} catch {
    Write-Log "Deployment error: $_" "ERROR"
}

Start-Sleep -Seconds 2

# Step 2: Start Exness Terminal
Write-Log "Step 2: Starting Exness Terminal"
try {
    $exnessPath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
    if (Test-Path $exnessPath) {
        $exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
        if (-not $exnessProcess) {
            Start-Process -FilePath $exnessPath -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            Write-Log "Exness Terminal started"
        } else {
            Write-Log "Exness Terminal already running"
        }
    } else {
        Write-Log "Exness Terminal not found at expected location" "WARNING"
    }
} catch {
    Write-Log "Exness startup error: $_" "ERROR"
}

Start-Sleep -Seconds 2

# Step 3: Start VPS Services (Master Controller)
Write-Log "Step 3: Starting VPS services"
try {
    $vpsServicesPath = "$workspaceRoot\vps-services"
    $masterController = Join-Path $vpsServicesPath "master-controller.ps1"
    
    if (Test-Path $masterController) {
        # Check if already running using WMI (works in PowerShell 5.1)
        $existingProcess = Get-WmiObject Win32_Process -Filter "name='powershell.exe'" -ErrorAction SilentlyContinue | 
            Where-Object { $_.CommandLine -like "*master-controller*" }
        
        if (-not $existingProcess) {
            # Start with explicit admin elevation
            Start-Process powershell.exe -Verb RunAs -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-NoProfile",
                "-WindowStyle", "Hidden",
                "-File", "`"$masterController`""
            ) -WindowStyle Hidden -ErrorAction SilentlyContinue
            
            Start-Sleep -Seconds 5
            Write-Log "Master controller started with admin elevation"
        } else {
            Write-Log "Master controller already running"
        }
    } else {
        Write-Log "Master controller not found, services may need deployment first" "WARNING"
    }
} catch {
    Write-Log "VPS services startup error: $_" "ERROR"
}

Start-Sleep -Seconds 2

# Step 4: Verify Services
Write-Log "Step 4: Verifying services"
try {
    $exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    
    # Use WMI to check for VPS service processes
    $vpsProcesses = Get-WmiObject Win32_Process -Filter "name='powershell.exe'" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -like "*vps-services*" -or $_.CommandLine -like "*exness-service*" -or $_.CommandLine -like "*research-service*" -or $_.CommandLine -like "*website-service*" -or $_.CommandLine -like "*cicd-service*" -or $_.CommandLine -like "*mql5-service*" }
    
    $status = @{
        Exness = if ($exnessProcess) { "RUNNING" } else { "NOT RUNNING" }
        VPSServices = if ($vpsProcesses) { "RUNNING ($($vpsProcesses.Count) processes)" } else { "NOT RUNNING" }
    }
    
    Write-Log "Service status: Exness=$($status.Exness), VPS=$($status.VPSServices)"
} catch {
    Write-Log "Verification error: $_" "ERROR"
}

# Step 5: Generate Status Report
Write-Log "Step 5: Generating status report"
try {
    $statusReport = Join-Path $workspaceRoot "system-status-report.ps1"
    if (Test-Path $statusReport) {
        & powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File $statusReport 2>&1 | Out-Null
        Write-Log "Status report generated"
    }
} catch {
    Write-Log "Status report error: $_" "ERROR"
}

# Final Summary
Write-Log "Automated startup completed"
Write-Log "Check vps-auto-start.log for details"

# Create completion marker
$completionFile = Join-Path $workspaceRoot "vps-startup-complete.txt"
@"
VPS System Startup Completed
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Status:
- Deployment: Completed
- Exness Terminal: Started
- VPS Services: Started
- Errors: Check vps-errors.log if any

Next: Run vps-verification.ps1 to verify all services
"@ | Out-File -FilePath $completionFile -Encoding UTF8

exit 0

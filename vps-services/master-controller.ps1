#Requires -RunAsAdministrator
# Master Service Controller - Manages all 24/7 services
$ErrorActionPreference = "Continue"
$vpsServicesPath = $PSScriptRoot
$workspaceRoot = Split-Path -Parent $vpsServicesPath
if (-not $workspaceRoot) { $workspaceRoot = "C:\Users\USER\OneDrive" }
$logsPath = Join-Path $workspaceRoot "vps-logs"

# Ensure logs directory exists
try {
    if (-not (Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    }
} catch {}

function Start-VPSService {
    param([string]$ServiceName, [string]$ScriptPath)
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "[$(Get-Date)] WARNING: Service script not found: $ServiceName ($ScriptPath)" | Out-File -Append "$logsPath\master-controller.log"
        return
    }

    $alreadyRunning = $false
    try {
        $procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue
        foreach ($p in ($procs | Where-Object { $_.CommandLine })) {
            if ($p.CommandLine -like "*$ScriptPath*" -or $p.CommandLine -like "*$ServiceName*") {
                $alreadyRunning = $true
                break
            }
        }
    } catch {
        # If CIM query fails, fall back to always attempting start (safe-ish).
        $alreadyRunning = $false
    }

    if (-not $alreadyRunning) {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $ScriptPath
        ) -WindowStyle Hidden
        Write-Host "[$(Get-Date)] Started service: $ServiceName" | Out-File -Append "$logsPath\master-controller.log"
    }
}

# Start all services
Start-VPSService -ServiceName "exness-service" -ScriptPath "$vpsServicesPath\exness-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "research-service" -ScriptPath "$vpsServicesPath\research-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "website-service" -ScriptPath "$vpsServicesPath\website-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "cicd-service" -ScriptPath "$vpsServicesPath\cicd-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "mql5-service" -ScriptPath "$vpsServicesPath\mql5-service.ps1"
Start-Sleep -Seconds 2

# Trading bridge sync/monitor service (optional but recommended)
Start-VPSService -ServiceName "trading-bridge-service" -ScriptPath "$vpsServicesPath\trading-bridge-service.ps1"

Write-Host "[$(Get-Date)] All services started" | Out-File -Append "$logsPath\master-controller.log"

# Monitor services
while ($true) {
    Start-Sleep -Seconds 300  # Check every 5 minutes
    # Restart any stopped services
    Start-VPSService -ServiceName "exness-service" -ScriptPath "$vpsServicesPath\exness-service.ps1"
    Start-VPSService -ServiceName "research-service" -ScriptPath "$vpsServicesPath\research-service.ps1"
    Start-VPSService -ServiceName "website-service" -ScriptPath "$vpsServicesPath\website-service.ps1"
    Start-VPSService -ServiceName "cicd-service" -ScriptPath "$vpsServicesPath\cicd-service.ps1"
    Start-VPSService -ServiceName "mql5-service" -ScriptPath "$vpsServicesPath\mql5-service.ps1"
    Start-VPSService -ServiceName "trading-bridge-service" -ScriptPath "$vpsServicesPath\trading-bridge-service.ps1"
}

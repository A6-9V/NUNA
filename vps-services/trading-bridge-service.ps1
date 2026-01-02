# Trading Bridge VPS Service
# Syncs trading code from laptop and monitors bridge connection
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$logsPath = Join-Path $workspaceRoot "vps-logs"
Set-Location $workspaceRoot

# Create logs directory
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

function Sync-FromGitHub {
    """Sync trading bridge code from GitHub"""
    try {
        Set-Location $tradingBridgePath
        git pull origin main 2>&1 | Out-File -Append "$logsPath\trading-bridge-sync.log"
        Write-Host "[$(Get-Date)] Synced trading bridge from GitHub" | Out-File -Append "$logsPath\trading-bridge-service.log"
    } catch {
        Write-Host "[$(Get-Date)] WARNING: GitHub sync failed: $_" | Out-File -Append "$logsPath\trading-bridge-service.log"
    }
}

# Initial sync
if (Test-Path $tradingBridgePath) {
    Sync-FromGitHub
} else {
    Write-Host "[$(Get-Date)] Trading bridge directory not found" | Out-File -Append "$logsPath\trading-bridge-service.log"
}

# Monitor and sync every 5 minutes
while ($true) {
    Start-Sleep -Seconds 300  # 5 minutes
    
    # Sync from GitHub
    Sync-FromGitHub
    
    # Check if Python service is running
    $pythonProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*background_service.py*"
    }
    
    if (-not $pythonProcess) {
        Write-Host "[$(Get-Date)] Python bridge service not running - restarting..." | Out-File -Append "$logsPath\trading-bridge-service.log"
        
        $startScript = Join-Path $tradingBridgePath "start-background.ps1"
        if (Test-Path $startScript) {
            Start-Process powershell.exe -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Hidden",
                "-File", $startScript
            ) -WindowStyle Hidden
        }
    }
}


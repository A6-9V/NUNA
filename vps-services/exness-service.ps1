# Exness Trading Service - Runs 24/7
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

# Launch Exness Terminal
$exnessPath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
if (Test-Path $exnessPath) {
    $process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not $process) {
        Start-Process -FilePath $exnessPath
        Start-Sleep -Seconds 5
        Write-Host "[$(Get-Date)] Exness Terminal started" | Out-File -Append "C:\Users\USER\OneDrive\vps-logs\exness-service.log"
    }
} else {
    Write-Host "[$(Get-Date)] ERROR: Exness Terminal not found" | Out-File -Append "C:\Users\USER\OneDrive\vps-logs\exness-service.log"
}

# Keep service running
while ($true) {
    $process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not $process) {
        Start-Process -FilePath $exnessPath
        Write-Host "[$(Get-Date)] Restarted Exness Terminal" | Out-File -Append "C:\Users\USER\OneDrive\vps-logs\exness-service.log"
    }
    Start-Sleep -Seconds 300  # Check every 5 minutes
}

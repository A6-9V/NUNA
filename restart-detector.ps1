# Restart Detection Script
# Only runs on restart, not on cold boot

$workspaceRoot = "C:\Users\USER\OneDrive"
$flagFile = "C:\Users\USER\OneDrive\.restart-flag"
$startupScript = "C:\Users\USER\OneDrive\auto-start-vps-admin.ps1"

# Check if this is a restart (flag file exists)
if (Test-Path $flagFile) {
    # This is a restart - run startup
    Write-Host "[RESTART DETECTED] Starting VPS system..." | Out-File -Append "C:\Users\USER\OneDrive\vps-logs\restart-detector.log"
    
    if (Test-Path $startupScript) {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", ""$startupScript""
        ) -WindowStyle Hidden
    }
} else {
    # This is a cold boot - create flag for next restart
    Write-Host "[COLD BOOT DETECTED] Skipping auto-start (Power On = False)" | Out-File -Append "C:\Users\USER\OneDrive\vps-logs\restart-detector.log"
    New-Item -ItemType File -Path $flagFile -Force | Out-Null
}

# Keep flag file for next restart detection

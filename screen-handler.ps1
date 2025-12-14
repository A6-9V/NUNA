# Screen Lock/Unlock Handler
# Runs VPS system on screen lock or unlock

$workspaceRoot = "C:\Users\USER\OneDrive"
$startupScript = "C:\Users\USER\OneDrive\auto-start-vps-admin.ps1"
$logsPath = "C:\Users\USER\OneDrive\vps-logs"

function Start-VPSSystem {
    if (Test-Path $startupScript) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] Screen event - Starting VPS system" | Out-File -Append "$logsPath\screen-handler.log"
        
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", ""$startupScript""
        ) -WindowStyle Hidden
    }
}

# Monitor for screen lock/unlock events
Register-WmiEvent -Query "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName='logonui.exe'" -Action {
    Start-VPSSystem
} | Out-Null

# Keep script running
while ($true) {
    Start-Sleep -Seconds 60
}

# MQL5 Forge Integration Service
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
$logsPath = "C:\Users\USER\OneDrive\vps-logs"
$mql5ForgeUrl = "https://forge.mql5.io/LengKundee/mql5"

# Monitor MQL5 Forge and sync with local
function Sync-MQL5Forge {
    $firefoxPath = Get-Command firefox -ErrorAction SilentlyContinue
    if (-not $firefoxPath) {
        $firefoxPaths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
        foreach ($path in $firefoxPaths) {
            if (Test-Path $path) {
                $firefoxPath = $path
                break
            }
        }
    } else {
        $firefoxPath = $firefoxPath.Source
    }
    
    if ($firefoxPath) {
        Start-Process -FilePath $firefoxPath -ArgumentList $mql5ForgeUrl
        Write-Host "[$(Get-Date)] Opened MQL5 Forge" | Out-File -Append "$logsPath\mql5-service.log"
    }
}

# Run sync every 12 hours
while ($true) {
    Sync-MQL5Forge
    Start-Sleep -Seconds 43200  # Wait 12 hours
}

# Exness Trading Service - Runs 24/7
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

# Launch Exness Terminal
$logPath = "C:\Users\USER\OneDrive\vps-logs\exness-service.log"

function Resolve-ExnessTerminalPath {
    $paths = @(
        "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe",
        "$env:LOCALAPPDATA\Programs\Exness Terminal\terminal64.exe",
        "$env:PROGRAMFILES\Exness Terminal\terminal64.exe",
        "$env:PROGRAMFILES(X86)\Exness Terminal\terminal64.exe",
        "$env:USERPROFILE\AppData\Local\Programs\Exness Terminal\terminal64.exe",
        "$env:USERPROFILE\AppData\Roaming\Exness Terminal\terminal64.exe"
    )

    foreach ($p in $paths) {
        try {
            if ($p -and (Test-Path $p)) { return $p }
        } catch { }
    }

    # Last resort: quick search in common locations (avoid full drive recursion)
    foreach ($root in @($env:PROGRAMFILES, $env:LOCALAPPDATA, $env:USERPROFILE)) {
        try {
            if ($root -and (Test-Path $root)) {
                $found = Get-ChildItem -Path $root -Filter "terminal64.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) { return $found.FullName }
            }
        } catch { }
    }

    return $null
}

$exnessPath = Resolve-ExnessTerminalPath
if ($exnessPath -and (Test-Path $exnessPath)) {
    $process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not $process) {
        Start-Process -FilePath $exnessPath
        Start-Sleep -Seconds 5
        Write-Host "[$(Get-Date)] Exness Terminal started ($exnessPath)" | Out-File -Append $logPath
    }
} else {
    Write-Host "[$(Get-Date)] ERROR: Exness Terminal not found (terminal64.exe)" | Out-File -Append $logPath
}

# Keep service running
while ($true) {
    $process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not $process) {
        $exnessPath = Resolve-ExnessTerminalPath
        if ($exnessPath -and (Test-Path $exnessPath)) {
            Start-Process -FilePath $exnessPath
            Write-Host "[$(Get-Date)] Restarted Exness Terminal ($exnessPath)" | Out-File -Append $logPath
        } else {
            Write-Host "[$(Get-Date)] ERROR: Cannot restart - terminal64.exe not found" | Out-File -Append $logPath
        }
    }
    Start-Sleep -Seconds 300  # Check every 5 minutes
}

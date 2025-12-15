# MQL5 Forge Integration Service - Repository Sync with API Token and USB Support
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
$logsPath = "C:\Users\USER\OneDrive\vps-logs"
$usbSupportScript = Join-Path $workspaceRoot "vps-services\usb-support.ps1"
$mql5RepoUrl = "https://forge.mql5.io/LengKundee/mql5.git"
$mql5RepoPath = Join-Path $workspaceRoot "mql5-repo"
$mql5ConfigFile = Join-Path $workspaceRoot "mql5-config.txt"
$mql5ForgeUrl = "https://forge.mql5.io/LengKundee/mql5"

# USB Support Configuration
$useUSBForMQL5 = $true  # Enable USB support for MQL5 repository
$usbMQL5Path = $null

# Load MQL5 API Token
$mql5ApiToken = $null
if (Test-Path $mql5ConfigFile) {
    $configContent = Get-Content $mql5ConfigFile -ErrorAction SilentlyContinue
    $tokenLine = $configContent | Where-Object { $_ -match "^MQL5_API=" }
    if ($tokenLine) {
        $mql5ApiToken = ($tokenLine -split "=")[1].Trim()
        Write-Host "[$(Get-Date)] MQL5 API token loaded" | Out-File -Append "$logsPath\mql5-service.log"
    }
    else {
        Write-Host "[$(Get-Date)] WARNING: MQL5 API token not found in config" | Out-File -Append "$logsPath\mql5-service.log"
    }
}
else {
    Write-Host "[$(Get-Date)] WARNING: MQL5 config file not found at $mql5ConfigFile" | Out-File -Append "$logsPath\mql5-service.log"
}

# Initialize USB Support
if ($useUSBForMQL5 -and (Test-Path $usbSupportScript)) {
    try {
        . $usbSupportScript
        $usbDrive = Get-PreferredUSBDrive -MinFreeSpaceGB 5
        if ($usbDrive) {
            $usbMQL5Path = Join-Path $usbDrive.Path "MQL5-Support\mql5-repo"
            Initialize-USBForMQL5 -USBDrivePath $usbDrive.Path | Out-Null
            Write-Host "[$(Get-Date)] USB support initialized: $($usbDrive.DriveLetter)" | Out-File -Append "$logsPath\mql5-service.log"
        }
        else {
            Write-Host "[$(Get-Date)] WARNING: No suitable USB drive found for MQL5 support" | Out-File -Append "$logsPath\mql5-service.log"
        }
    }
    catch {
        Write-Host "[$(Get-Date)] WARNING: USB support initialization failed: $_" | Out-File -Append "$logsPath\mql5-service.log"
    }
}

# Function to sync MQL5 Forge repository
function Sync-MQL5Repository {
    try {
        Set-Location $workspaceRoot
        
        if (Test-Path $mql5RepoPath) {
            Write-Host "[$(Get-Date)] Pulling MQL5 repository updates..." | Out-File -Append "$logsPath\mql5-service.log"
            Set-Location $mql5RepoPath
            
            # Configure git with token if available
            if ($mql5ApiToken) {
                $repoUrlWithToken = $mql5RepoUrl -replace "https://", "https://$mql5ApiToken@"
                git remote set-url origin $repoUrlWithToken 2>&1 | Out-Null
            }
            
            $pullOutput = git pull origin main 2>&1
            $pullOutput | Out-File -Append "$logsPath\mql5-service.log"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[$(Get-Date)] MQL5 repository updated successfully" | Out-File -Append "$logsPath\mql5-service.log"
                
                # Check for new MQL5 files and log them
                $newFiles = git diff --name-only HEAD@ { 1 } HEAD 2>&1
                if ($newFiles) {
                    Write-Host "[$(Get-Date)] New/updated files:" | Out-File -Append "$logsPath\mql5-service.log"
                    $newFiles | Out-File -Append "$logsPath\mql5-service.log"
                }
                
                # Sync to USB if available
                if ($useUSBForMQL5 -and $usbMQL5Path -and (Test-Path $mql5RepoPath)) {
                    try {
                        Sync-MQL5ToUSB -SourceRepoPath $mql5RepoPath -USBDestinationPath $usbMQL5Path | Out-Null
                        Write-Host "[$(Get-Date)] MQL5 repository synced to USB" | Out-File -Append "$logsPath\mql5-service.log"
                    }
                    catch {
                        Write-Host "[$(Get-Date)] WARNING: USB sync failed: $_" | Out-File -Append "$logsPath\mql5-service.log"
                    }
                }
            }
            else {
                Write-Host "[$(Get-Date)] WARNING: Could not pull MQL5 updates (exit code: $LASTEXITCODE)" | Out-File -Append "$logsPath\mql5-service.log"
            }
        }
        else {
            Write-Host "[$(Get-Date)] Cloning MQL5 repository..." | Out-File -Append "$logsPath\mql5-service.log"
            Set-Location $workspaceRoot
            
            # Clone with token if available
            if ($mql5ApiToken) {
                $repoUrlWithToken = $mql5RepoUrl -replace "https://", "https://$mql5ApiToken@"
                $cloneOutput = git clone $repoUrlWithToken $mql5RepoPath 2>&1
            }
            else {
                $cloneOutput = git clone $mql5RepoUrl $mql5RepoPath 2>&1
            }
            
            $cloneOutput | Out-File -Append "$logsPath\mql5-service.log"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[$(Get-Date)] MQL5 repository cloned successfully" | Out-File -Append "$logsPath\mql5-service.log"
                
                # Sync to USB if available
                if ($useUSBForMQL5 -and $usbMQL5Path -and (Test-Path $mql5RepoPath)) {
                    try {
                        Sync-MQL5ToUSB -SourceRepoPath $mql5RepoPath -USBDestinationPath $usbMQL5Path | Out-Null
                        Write-Host "[$(Get-Date)] MQL5 repository synced to USB" | Out-File -Append "$logsPath\mql5-service.log"
                    }
                    catch {
                        Write-Host "[$(Get-Date)] WARNING: USB sync failed: $_" | Out-File -Append "$logsPath\mql5-service.log"
                    }
                }
            }
            else {
                Write-Host "[$(Get-Date)] ERROR: Failed to clone MQL5 repository (exit code: $LASTEXITCODE)" | Out-File -Append "$logsPath\mql5-service.log"
            }
        }
    }
    catch {
        Write-Host "[$(Get-Date)] ERROR: MQL5 repository sync failed: $_" | Out-File -Append "$logsPath\mql5-service.log"
    }
}

# Function to open MQL5 Forge in browser (optional)
function Open-MQL5Forge {
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
    }
    else {
        $firefoxPath = $firefoxPath.Source
    }
    
    if ($firefoxPath) {
        Start-Process -FilePath $firefoxPath -ArgumentList $mql5ForgeUrl
        Write-Host "[$(Get-Date)] Opened MQL5 Forge in browser" | Out-File -Append "$logsPath\mql5-service.log"
    }
}

# Initial sync
Write-Host "[$(Get-Date)] Starting MQL5 Forge Integration Service" | Out-File -Append "$logsPath\mql5-service.log"
Sync-MQL5Repository

# Run sync every 6 hours (more frequent updates)
$syncCounter = 0
while ($true) {
    $syncCounter++
    
    # Sync repository every 6 hours
    if ($syncCounter -ge 2) {
        Sync-MQL5Repository
        $syncCounter = 0
    }
    
    Start-Sleep -Seconds 21600  # Wait 6 hours (21600 seconds)
}


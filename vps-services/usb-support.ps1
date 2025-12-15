# USB Support Functions for MQL5 Repository
# Provides USB drive detection and MQL5 repository sync functionality

function Get-USBDrives {
    <#
    .SYNOPSIS
        Detects all available USB/removable drives
    .DESCRIPTION
        Returns an array of USB drive information including drive letter, label, and free space
    #>
    $usbDrives = @()
    
    try {
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } # Removable drives
        
        foreach ($drive in $drives) {
            $usbInfo = @{
                DriveLetter = $drive.DeviceID
                VolumeLabel = $drive.VolumeName
                FileSystem = $drive.FileSystem
                TotalSize = [math]::Round($drive.Size / 1GB, 2)
                FreeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
                UsedSpace = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
                FreePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
                Path = $drive.DeviceID
            }
            $usbDrives += $usbInfo
        }
    } catch {
        Write-Host "[ERROR] Failed to detect USB drives: $_" -ForegroundColor Red
    }
    
    return $usbDrives
}

function Get-PreferredUSBDrive {
    <#
    .SYNOPSIS
        Gets the preferred USB drive for MQL5 support
    .DESCRIPTION
        Returns the best USB drive based on available space and configuration
    #>
    param(
        [string]$PreferredLabel = "MQL5_SUPPORT",
        [int]$MinFreeSpaceGB = 5
    )
    
    $usbDrives = Get-USBDrives
    
    if ($usbDrives.Count -eq 0) {
        return $null
    }
    
    # First, try to find a drive with the preferred label
    $preferredDrive = $usbDrives | Where-Object { $_.VolumeLabel -eq $PreferredLabel }
    if ($preferredDrive -and $preferredDrive.FreeSpace -ge $MinFreeSpaceGB) {
        return $preferredDrive
    }
    
    # Otherwise, find the drive with the most free space
    $bestDrive = $usbDrives | Where-Object { $_.FreeSpace -ge $MinFreeSpaceGB } | 
                 Sort-Object -Property FreeSpace -Descending | Select-Object -First 1
    
    return $bestDrive
}

function Initialize-USBForMQL5 {
    <#
    .SYNOPSIS
        Initializes USB drive for MQL5 repository support
    .DESCRIPTION
        Creates necessary directories on USB drive for MQL5 repository storage
    #>
    param(
        [string]$USBDrivePath,
        [string]$MQL5RepoName = "mql5-repo"
    )
    
    if (-not $USBDrivePath) {
        Write-Host "[ERROR] USB drive path not provided" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $USBDrivePath)) {
        Write-Host "[ERROR] USB drive not found: $USBDrivePath" -ForegroundColor Red
        return $false
    }
    
    try {
        $mql5Path = Join-Path $USBDrivePath "MQL5-Support"
        $repoPath = Join-Path $mql5Path $MQL5RepoName
        $backupPath = Join-Path $mql5Path "Backups"
        $logsPath = Join-Path $mql5Path "Logs"
        
        # Create directory structure
        @($mql5Path, $repoPath, $backupPath, $logsPath) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Host "[OK] Created directory: $_" -ForegroundColor Green
            }
        }
        
        # Create info file
        $infoFile = Join-Path $mql5Path "USB-INFO.txt"
        $infoContent = @"
MQL5 Support USB Drive
=====================
Initialized: $(Get-Date)
USB Drive: $USBDrivePath
Repository: $repoPath
Backups: $backupPath
Logs: $logsPath

This USB drive is configured for MQL5 repository support.
The Exness service will sync MQL5 files to this location.
"@
        $infoContent | Out-File -FilePath $infoFile -Encoding UTF8
        
        return $true
    } catch {
        Write-Host "[ERROR] Failed to initialize USB for MQL5: $_" -ForegroundColor Red
        return $false
    }
}

function Sync-MQL5ToUSB {
    <#
    .SYNOPSIS
        Syncs MQL5 repository to USB drive
    .DESCRIPTION
        Copies MQL5 repository files to USB drive for backup and portability
    #>
    param(
        [string]$SourceRepoPath,
        [string]$USBDestinationPath,
        [switch]$CreateBackup
    )
    
    if (-not (Test-Path $SourceRepoPath)) {
        Write-Host "[WARNING] Source repository not found: $SourceRepoPath" -ForegroundColor Yellow
        return $false
    }
    
    if (-not (Test-Path $USBDestinationPath)) {
        Write-Host "[ERROR] USB destination not found: $USBDestinationPath" -ForegroundColor Red
        return $false
    }
    
    try {
        # Create backup if requested
        if ($CreateBackup) {
            $backupPath = Join-Path (Split-Path $USBDestinationPath) "Backups"
            $backupName = "mql5-backup-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
            $fullBackupPath = Join-Path $backupPath $backupName
            
            if (-not (Test-Path $backupPath)) {
                New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            }
            
            Write-Host "[INFO] Creating backup to: $fullBackupPath" -ForegroundColor Cyan
            Copy-Item -Path $SourceRepoPath -Destination $fullBackupPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Sync files (robocopy for better performance)
        Write-Host "[INFO] Syncing MQL5 repository to USB..." -ForegroundColor Cyan
        $robocopyArgs = @(
            "`"$SourceRepoPath`"",
            "`"$USBDestinationPath`"",
            "/MIR",  # Mirror (delete files in destination that don't exist in source)
            "/R:3",  # Retry 3 times
            "/W:5",  # Wait 5 seconds between retries
            "/NP",   # No progress
            "/NFL",  # No file list
            "/NDL"   # No directory list
        )
        
        $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -le 1) {
            Write-Host "[OK] MQL5 repository synced to USB successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] Robocopy exit code: $($result.ExitCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to sync MQL5 to USB: $_" -ForegroundColor Red
        return $false
    }
}

# Export functions (only if running as module)
# When sourced directly, functions are available in current scope
if ($MyInvocation.MyCommand.ModuleName) {
    Export-ModuleMember -Function Get-USBDrives, Get-PreferredUSBDrive, Initialize-USBForMQL5, Sync-MQL5ToUSB
}


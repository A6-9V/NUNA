# Battery Maintainer - Volume + Adaptability for Plug-in Device
# Creates a portable "BatteryMaintainer" structure on a removable/USB volume and
# stores device-specific profiles so the setup adapts automatically across devices.
#
# Notes:
# - This script is designed for Windows PowerShell 5.1+ (matches project standards).
# - It does NOT repartition disks. "Volume" here means: detect/select a removable volume,
#   optionally apply a consistent volume label, and initialize a folder + config layout.
#
# Usage examples:
#   .\battery-maintainer-plugin-device.ps1
#   .\battery-maintainer-plugin-device.ps1 -DeviceName "A6-9V" -PreferredLabel "BATTERY_MAINTAINER"
#   .\battery-maintainer-plugin-device.ps1 -ForceRelabel -DryRun
#
param(
    [string]$DeviceName = "A6-9V",
    [string]$PreferredLabel = "BATTERY_MAINTAINER",
    [int]$MinFreeSpaceGB = 1,
    [switch]$ForceRelabel,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param(
        [ValidateSet("OK", "INFO", "WARNING", "ERROR")]
        [string]$Level,
        [string]$Message
    )

    $color = switch ($Level) {
        "OK" { "Green" }
        "INFO" { "Cyan" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Get-RemovableVolumes {
    <#
    .SYNOPSIS
        Returns removable volumes (DriveType = 2).
    #>
    try {
        # Win32_LogicalDisk: DriveType 2 = Removable
        return @(Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.Size -gt 0 })
    } catch {
        Write-Status -Level "ERROR" -Message "Failed to enumerate removable volumes: $_"
        return @()
    }
}

function Select-BatteryMaintainerVolume {
    <#
    .SYNOPSIS
        Selects a removable volume suitable for BatteryMaintainer.
    .DESCRIPTION
        Prefers volumes with a matching label; otherwise selects the volume with most free space.
    #>
    param(
        [string]$PreferredLabel,
        [int]$MinFreeSpaceGB
    )

    $volumes = Get-RemovableVolumes
    if (-not $volumes -or $volumes.Count -eq 0) {
        return $null
    }

    $candidates = foreach ($v in $volumes) {
        [pscustomobject]@{
            DriveLetter = $v.DeviceID
            VolumeLabel = $v.VolumeName
            FileSystem  = $v.FileSystem
            TotalGB     = if ($v.Size) { [math]::Round($v.Size / 1GB, 2) } else { 0 }
            FreeGB      = if ($v.FreeSpace) { [math]::Round($v.FreeSpace / 1GB, 2) } else { 0 }
        }
    }

    $preferred = $candidates | Where-Object { $_.VolumeLabel -eq $PreferredLabel -and $_.FreeGB -ge $MinFreeSpaceGB } | Select-Object -First 1
    if ($preferred) {
        return $preferred
    }

    $best = $candidates | Where-Object { $_.FreeGB -ge $MinFreeSpaceGB } | Sort-Object -Property FreeGB -Descending | Select-Object -First 1
    return $best
}

function Try-SetVolumeLabel {
    <#
    .SYNOPSIS
        Attempts to set the volume label using Set-Volume (admin may be required).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$DriveLetter,
        [Parameter(Mandatory=$true)][string]$NewLabel,
        [switch]$DryRun
    )

    $dl = $DriveLetter.TrimEnd(":")
    if ($DryRun) {
        Write-Status -Level "INFO" -Message "DRY RUN: Would set volume label on $DriveLetter to '$NewLabel'"
        return $true
    }

    try {
        Set-Volume -DriveLetter $dl -NewFileSystemLabel $NewLabel -ErrorAction Stop | Out-Null
        Write-Status -Level "OK" -Message "Volume label set on $DriveLetter to '$NewLabel'"
        return $true
    } catch {
        Write-Status -Level "WARNING" -Message "Could not set volume label on $DriveLetter (may need Admin): $($_.Exception.Message)"
        return $false
    }
}

function Initialize-BatteryMaintainerLayout {
    <#
    .SYNOPSIS
        Creates the BatteryMaintainer folder structure and per-device profile.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$DriveLetter,
        [Parameter(Mandatory=$true)][string]$DeviceName,
        [switch]$DryRun
    )

    $root = Join-Path "$DriveLetter\" "BatteryMaintainer"
    $configDir = Join-Path $root "Config"
    $logsDir = Join-Path $root "Logs"
    $profilesDir = Join-Path $root "Profiles"
    $deviceProfileDir = Join-Path $profilesDir $DeviceName

    $paths = @($root, $configDir, $logsDir, $profilesDir, $deviceProfileDir)
    foreach ($p in $paths) {
        if ($DryRun) {
            Write-Status -Level "INFO" -Message "DRY RUN: Would ensure directory exists: $p"
            continue
        }
        try {
            if (-not (Test-Path $p)) {
                New-Item -ItemType Directory -Path $p -Force | Out-Null
                Write-Status -Level "OK" -Message "Created directory: $p"
            }
        } catch {
            Write-Status -Level "ERROR" -Message "Failed to create directory '$p': $($_.Exception.Message)"
            return $false
        }
    }

    # Device profile (adaptability)
    $profilePath = Join-Path $deviceProfileDir "profile.json"
    if (-not $DryRun) {
        try {
            if (-not (Test-Path $profilePath)) {
                $profile = [ordered]@{
                    deviceName = $DeviceName
                    createdAt  = (Get-Date).ToString("o")
                    maintainer = [ordered]@{
                        # Battery maintainer "volume" (tunable thresholds)
                        targetMinPercent = 40
                        targetMaxPercent = 80
                        pollSeconds      = 60
                        # This repo may later integrate ADB or smart-plug control.
                        actions          = [ordered]@{
                            notifyOnly = $true
                            notes      = "No hardware control configured; this profile stores thresholds for monitoring/alerts."
                        }
                    }
                }

                $json = $profile | ConvertTo-Json -Depth 8
                $json | Out-File -FilePath $profilePath -Encoding UTF8
                Write-Status -Level "OK" -Message "Created device profile: $profilePath"
            } else {
                Write-Status -Level "INFO" -Message "Device profile already exists: $profilePath"
            }
        } catch {
            Write-Status -Level "WARNING" -Message "Could not write device profile: $($_.Exception.Message)"
        }
    } else {
        Write-Status -Level "INFO" -Message "DRY RUN: Would ensure device profile exists: $profilePath"
    }

    # Root info file
    $infoPath = Join-Path $root "BATTERY-MAINTAINER-INFO.txt"
    if ($DryRun) {
        Write-Status -Level "INFO" -Message "DRY RUN: Would write info file: $infoPath"
        return $true
    }

    try {
        $info = @"
Battery Maintainer Volume
========================
Initialized: $(Get-Date)
Device Profile: $DeviceName

Layout:
  $root
  - Config\
  - Logs\
  - Profiles\$DeviceName\

This volume is used as a portable configuration + logging target for the
Battery Maintainer "plug-in device" workflow. The per-device profile stores
thresholds and behavior so the system can adapt when different devices are used.
"@
        $info | Out-File -FilePath $infoPath -Encoding UTF8
        Write-Status -Level "OK" -Message "Wrote info file: $infoPath"
        return $true
    } catch {
        Write-Status -Level "WARNING" -Message "Could not write info file: $($_.Exception.Message)"
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Battery Maintainer - Plug-in Device Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Status -Level "INFO" -Message "DeviceName: $DeviceName"
Write-Status -Level "INFO" -Message "PreferredLabel: $PreferredLabel"
Write-Status -Level "INFO" -Message "MinFreeSpaceGB: $MinFreeSpaceGB"
Write-Status -Level "INFO" -Message "ForceRelabel: $ForceRelabel"
Write-Status -Level "INFO" -Message "DryRun: $DryRun"
Write-Host ""

$selected = Select-BatteryMaintainerVolume -PreferredLabel $PreferredLabel -MinFreeSpaceGB $MinFreeSpaceGB
if (-not $selected) {
    Write-Status -Level "ERROR" -Message "No suitable removable volume found (need at least $MinFreeSpaceGB GB free). Plug in the device/USB volume and retry."
    exit 1
}

Write-Status -Level "OK" -Message "Selected volume: $($selected.DriveLetter) (Label='$($selected.VolumeLabel)', Free=$($selected.FreeGB)GB, FS=$($selected.FileSystem))"

if ($ForceRelabel -or ($selected.VolumeLabel -ne $PreferredLabel -and [string]::IsNullOrWhiteSpace($selected.VolumeLabel))) {
    # If ForceRelabel is set, always try to apply. Otherwise, only if unlabeled.
    Try-SetVolumeLabel -DriveLetter $selected.DriveLetter -NewLabel $PreferredLabel -DryRun:$DryRun | Out-Null
} else {
    Write-Status -Level "INFO" -Message "Keeping existing volume label: '$($selected.VolumeLabel)' (use -ForceRelabel to change)"
}

if (Initialize-BatteryMaintainerLayout -DriveLetter $selected.DriveLetter -DeviceName $DeviceName -DryRun:$DryRun) {
    Write-Host ""
    Write-Status -Level "OK" -Message "Battery Maintainer volume initialized successfully."
    exit 0
} else {
    Write-Host ""
    Write-Status -Level "ERROR" -Message "Battery Maintainer volume initialization failed."
    exit 2
}


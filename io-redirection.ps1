#Requires -Version 5.1
<#
.SYNOPSIS
    I/O Redirection Helper Functions
.DESCRIPTION
    Redirects I/O operations to E: drive and USB drives
    Protects C: and D: drives from heavy operations
#>

function Get-IOWorkPath {
    <#
    .SYNOPSIS
        Gets the appropriate I/O work path
    .DESCRIPTION
        Returns E: drive path, or USB drive path if E: is full
    #>
    param(
        [string]$SubPath = "",
        [string]$Type = "Temp"  # Temp, Cache, Logs, Downloads, Backups, Startup, Projects
    )
    
    # Check E: drive first
    $eDrivePath = "E:\IO-Work"
    if (Test-Path $eDrivePath) {
        $targetPath = switch ($Type) {
            "Temp" { "E:\IO-Work\Temp" }
            "Cache" { "E:\IO-Work\Cache" }
            "Logs" { "E:\IO-Work\Logs" }
            "Downloads" { "E:\IO-Work\Downloads" }
            "Backups" { "E:\IO-Work\Backups" }
            "Startup" { "E:\IO-Work\Startup" }
            "Projects" { "E:\IO-Work\Projects" }
            default { "E:\IO-Work\Temp" }
        }
        
        # Check if E: has space (at least 1GB free)
        $eDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "E:" }
        if ($eDrive -and ($eDrive.FreeSpace / 1GB) -gt 1) {
            $fullPath = Join-Path $targetPath $SubPath
            if (-not (Test-Path (Split-Path $fullPath -Parent))) {
                New-Item -ItemType Directory -Path (Split-Path $fullPath -Parent) -Force | Out-Null
            }
            return $fullPath
        }
    }
    
    # Fallback to USB drive
    $usbSupportScript = Join-Path $PSScriptRoot "vps-services\usb-support.ps1"
    if (Test-Path $usbSupportScript) {
        . $usbSupportScript
        $usbDrives = Get-USBDrives
        if ($usbDrives.Count -gt 0) {
            $bestUSB = $usbDrives | Sort-Object -Property FreeSpace -Descending | Select-Object -First 1
            if ($bestUSB -and $bestUSB.FreeSpace -gt 1) {
                $usbPath = Join-Path $bestUSB.Path "IO-Work"
                $targetPath = Join-Path $usbPath $Type
                $fullPath = Join-Path $targetPath $SubPath
                if (-not (Test-Path (Split-Path $fullPath -Parent))) {
                    New-Item -ItemType Directory -Path (Split-Path $fullPath -Parent) -Force | Out-Null
                }
                return $fullPath
            }
        }
    }
    
    # Last resort: use system temp (but log warning)
    Write-Warning "E: and USB drives not available, using system temp"
    return Join-Path $env:TEMP $SubPath
}

function Test-ProtectedDrive {
    <#
    .SYNOPSIS
        Checks if a drive is protected
    .DESCRIPTION
        Returns true if the drive should be protected from heavy I/O
    #>
    param(
        [string]$Path
    )
    
    $protectedDrives = @("C:", "D:")
    $drive = (Get-Item $Path -ErrorAction SilentlyContinue).PSDrive.Name + ":"
    
    return $protectedDrives -contains $drive
}

function Redirect-ToIODrive {
    <#
    .SYNOPSIS
        Redirects a file operation to I/O drive
    .DESCRIPTION
        If the target path is on a protected drive, redirects to E: or USB
    #>
    param(
        [string]$OriginalPath,
        [string]$Type = "Temp"
    )
    
    if (Test-ProtectedDrive -Path $OriginalPath) {
        $fileName = Split-Path $OriginalPath -Leaf
        $newPath = Get-IOWorkPath -SubPath $fileName -Type $Type
        Write-Warning "Redirected I/O from protected drive to: $newPath"
        return $newPath
    }
    
    return $OriginalPath
}

Export-ModuleMember -Function Get-IOWorkPath, Test-ProtectedDrive, Redirect-ToIODrive

#Requires -Version 5.1
<#
.SYNOPSIS
    Setup I/O Redirection for Heavy Operations
.DESCRIPTION
    Configures E: drive and USB drives for heavy I/O operations
    Protects C: (OS) and D: drives from heavy read/write operations
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  I/O Redirection Setup" -ForegroundColor Cyan
Write-Host "  Heavy Operations: E: + USB Drives" -ForegroundColor Cyan
Write-Host "  Protected: C: (OS) and D:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Import USB support
$usbSupportScript = Join-Path $PSScriptRoot "vps-services\usb-support.ps1"
if (Test-Path $usbSupportScript) {
    . $usbSupportScript
}

# ============================================
# STEP 1: Verify E: Drive
# ============================================
Write-Host "[1/6] Verifying E: drive configuration..." -ForegroundColor Yellow

$eDrive = Get-PSDrive -Name E -ErrorAction SilentlyContinue
if (-not $eDrive) {
    Write-Host "[ERROR] E: drive not found!" -ForegroundColor Red
    Write-Host "[INFO] Please ensure E: drive is available" -ForegroundColor Yellow
    exit 1
}

$eDriveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "E:" }
if ($eDriveInfo) {
    $freeSpaceGB = [math]::Round($eDriveInfo.FreeSpace / 1GB, 2)
    $totalSizeGB = [math]::Round($eDriveInfo.Size / 1GB, 2)
    Write-Host "  [OK] E: drive found" -ForegroundColor Green
    Write-Host "    Total: $totalSizeGB GB" -ForegroundColor Gray
    Write-Host "    Free: $freeSpaceGB GB" -ForegroundColor Gray
    
    if ($freeSpaceGB -lt 10) {
        Write-Host "  [WARNING] E: drive has less than 10GB free space" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [ERROR] Could not get E: drive information" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================
# STEP 2: Detect USB Drives
# ============================================
Write-Host "[2/6] Detecting USB drives..." -ForegroundColor Yellow

$usbDrives = Get-USBDrives
if ($usbDrives.Count -gt 0) {
    Write-Host "  [OK] Found $($usbDrives.Count) USB drive(s):" -ForegroundColor Green
    foreach ($usb in $usbDrives) {
        Write-Host "    - $($usb.DriveLetter) ($($usb.VolumeLabel))" -ForegroundColor Cyan
        Write-Host "      Free: $($usb.FreeSpace) GB / Total: $($usb.TotalSize) GB" -ForegroundColor Gray
    }
} else {
    Write-Host "  [WARNING] No USB drives detected" -ForegroundColor Yellow
    Write-Host "  [INFO] USB drives will be used when available" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# STEP 3: Create I/O Directories on E: Drive
# ============================================
Write-Host "[3/6] Creating I/O directories on E: drive..." -ForegroundColor Yellow

$ioDirectories = @(
    "E:\IO-Work",
    "E:\IO-Work\Temp",
    "E:\IO-Work\Cache",
    "E:\IO-Work\Logs",
    "E:\IO-Work\Downloads",
    "E:\IO-Work\Backups",
    "E:\IO-Work\Startup",
    "E:\IO-Work\Projects"
)

foreach ($dir in $ioDirectories) {
    if (-not (Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  [OK] Created: $dir" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Failed to create $dir : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [INFO] Exists: $dir" -ForegroundColor Gray
    }
}

Write-Host ""

# ============================================
# STEP 4: Setup Environment Variables
# ============================================
Write-Host "[4/6] Setting up environment variables..." -ForegroundColor Yellow

$envVars = @{
    "IO_WORK_DIR" = "E:\IO-Work"
    "IO_TEMP_DIR" = "E:\IO-Work\Temp"
    "IO_CACHE_DIR" = "E:\IO-Work\Cache"
    "IO_LOGS_DIR" = "E:\IO-Work\Logs"
    "IO_DOWNLOADS_DIR" = "E:\IO-Work\Downloads"
    "IO_BACKUPS_DIR" = "E:\IO-Work\Backups"
    "IO_STARTUP_DIR" = "E:\IO-Work\Startup"
    "IO_PROJECTS_DIR" = "E:\IO-Work\Projects"
    "PROTECTED_DRIVES" = "C:,D:"
    "IO_DRIVES" = "E:"
}

foreach ($var in $envVars.GetEnumerator()) {
    try {
        [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, [System.EnvironmentVariableTarget]::User)
        Write-Host "  [OK] Set $($var.Key) = $($var.Value)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to set $($var.Key) : $_" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================
# STEP 5: Create I/O Redirection Script
# ============================================
Write-Host "[5/6] Creating I/O redirection helper script..." -ForegroundColor Yellow

$redirectScript = @'
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
'@

$redirectScriptPath = Join-Path $PSScriptRoot "io-redirection.ps1"
$redirectScript | Out-File -FilePath $redirectScriptPath -Encoding UTF8
Write-Host "  [OK] Created: $redirectScriptPath" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 6: Create Protection Monitor
# ============================================
Write-Host "[6/6] Creating drive protection monitor..." -ForegroundColor Yellow

$protectionScript = @'
#Requires -Version 5.1
<#
.SYNOPSIS
    Drive Protection Monitor
.DESCRIPTION
    Monitors I/O operations and protects C: and D: drives
#>

$ErrorActionPreference = "Continue"

$protectedDrives = @("C:", "D:")
$ioDrives = @("E:")

function Monitor-ProtectedDrives {
    Write-Host "Monitoring protected drives: $($protectedDrives -join ', ')" -ForegroundColor Cyan
    Write-Host "I/O drives: $($ioDrives -join ', ')" -ForegroundColor Green
    
    while ($true) {
        foreach ($drive in $protectedDrives) {
            $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $drive }
            if ($disk) {
                $diskTime = Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -ErrorAction SilentlyContinue
                if ($diskTime) {
                    $activeTime = [math]::Round($diskTime.CounterSamples[0].CookedValue, 1)
                    if ($activeTime -gt 80) {
                        Write-Warning "$drive drive active time is ${activeTime}% - Consider redirecting I/O to E: drive"
                    }
                }
            }
        }
        Start-Sleep -Seconds 30
    }
}

# Run monitor
Monitor-ProtectedDrives
'@

$protectionScriptPath = Join-Path $PSScriptRoot "protect-drives.ps1"
$protectionScript | Out-File -FilePath $protectionScriptPath -Encoding UTF8
Write-Host "  [OK] Created: $protectionScriptPath" -ForegroundColor Green
Write-Host ""

# ============================================
# Final Summary
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Heavy I/O Drive: E:\IO-Work" -ForegroundColor Green
Write-Host "  Protected Drives: C:, D:" -ForegroundColor Yellow
Write-Host "  USB Support: Enabled" -ForegroundColor Green
Write-Host ""
Write-Host "Environment Variables Set:" -ForegroundColor Yellow
Write-Host "  IO_WORK_DIR, IO_TEMP_DIR, IO_CACHE_DIR, etc." -ForegroundColor Gray
Write-Host ""
Write-Host "Scripts Created:" -ForegroundColor Yellow
Write-Host "  io-redirection.ps1 - I/O redirection helper" -ForegroundColor Gray
Write-Host "  protect-drives.ps1 - Drive protection monitor" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your session to load environment variables" -ForegroundColor Cyan
Write-Host "  2. Use Get-IOWorkPath in your scripts for I/O operations" -ForegroundColor Cyan
Write-Host "  3. Run protect-drives.ps1 to monitor protected drives" -ForegroundColor Cyan
Write-Host ""


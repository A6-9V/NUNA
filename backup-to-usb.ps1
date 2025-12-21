# Backup to USB with U&I/yy/mm/dd structure
# Creates backup in format: U&I/yy/mm/dd/

param(
    [string]$SourcePath = $PSScriptRoot,
    [string]$UsbDrive = "",
    [switch]$AutoDetect
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  USB Backup Script - U&I/yy/mm/dd" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current date in yy/mm/dd format
$dateFormat = Get-Date -Format "yy/MM/dd"
$year = Get-Date -Format "yy"
$month = Get-Date -Format "MM"
$day = Get-Date -Format "dd"

Write-Host "[INFO] Date format: $dateFormat" -ForegroundColor Yellow

# Auto-detect USB drive if requested
if ($AutoDetect -or [string]::IsNullOrEmpty($UsbDrive)) {
    Write-Host "[INFO] Auto-detecting USB drives..." -ForegroundColor Yellow
    
    $usbDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
        $drive = $_
        $driveType = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive.Name):'").DriveType
        $driveType -eq 2 -and $drive.Used -gt 0  # Removable drive with data
    }
    
    if ($usbDrives.Count -eq 0) {
        Write-Host "[ERROR] No USB drives detected!" -ForegroundColor Red
        Write-Host "[INFO] Please insert a USB drive and try again." -ForegroundColor Yellow
        exit 1
    }
    
    if ($usbDrives.Count -eq 1) {
        $UsbDrive = "$($usbDrives[0].Name):"
        Write-Host "[OK] Found USB drive: $UsbDrive" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Multiple USB drives found:" -ForegroundColor Yellow
        $index = 1
        foreach ($drive in $usbDrives) {
            $size = [math]::Round($drive.Used / 1GB, 2)
            $free = [math]::Round($drive.Free / 1GB, 2)
            Write-Host "  $index. $($drive.Name): - Used: ${size}GB, Free: ${free}GB" -ForegroundColor White
            $index++
        }
        
        $choice = Read-Host "Select USB drive (1-$($usbDrives.Count))"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $usbDrives.Count) {
            $UsbDrive = "$($usbDrives[[int]$choice - 1].Name):"
        } else {
            Write-Host "[ERROR] Invalid selection!" -ForegroundColor Red
            exit 1
        }
    }
}

# Verify USB drive exists
if (-not (Test-Path $UsbDrive)) {
    Write-Host "[ERROR] USB drive $UsbDrive not found!" -ForegroundColor Red
    exit 1
}

# Create backup directory structure: U&I/yy/mm/dd
$backupBase = Join-Path $UsbDrive "U&I"
$backupPath = Join-Path $backupBase $year
$backupPath = Join-Path $backupPath $month
$backupPath = Join-Path $backupPath $day

Write-Host "[INFO] Creating backup directory structure..." -ForegroundColor Yellow
Write-Host "  Base: $backupBase" -ForegroundColor White
Write-Host "  Path: $backupPath" -ForegroundColor White

try {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "[OK] Backup directory created: $backupPath" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create backup directory: $_" -ForegroundColor Red
    exit 1
}

# Get project name from source path
$projectName = Split-Path $SourcePath -Leaf
$destinationPath = Join-Path $backupPath $projectName

Write-Host ""
Write-Host "[INFO] Starting backup..." -ForegroundColor Yellow
Write-Host "  Source: $SourcePath" -ForegroundColor White
Write-Host "  Destination: $destinationPath" -ForegroundColor White
Write-Host ""

# Create backup with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupLog = Join-Path $backupPath "backup-log_$timestamp.txt"

# Start backup log
$logContent = @"
USB Backup Log
==============
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source: $SourcePath
Destination: $destinationPath
Structure: U&I/$dateFormat

"@
$logContent | Out-File -FilePath $backupLog -Encoding UTF8

# Copy files (excluding .git, node_modules, etc.)
$excludeDirs = @('.git', 'node_modules', '__pycache__', '.pytest_cache', '*.pyc', '.venv', 'venv', 'env')
$excludeFiles = @('*.log', '*.tmp', '*.cache', '.DS_Store', 'Thumbs.db')

Write-Host "[INFO] Copying files (excluding git, cache, etc.)..." -ForegroundColor Yellow

$copyCount = 0
$errorCount = 0

# Function to copy directory
function Copy-Directory {
    param(
        [string]$Source,
        [string]$Destination,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFiles
    )
    
    $items = Get-ChildItem -Path $Source -Force -ErrorAction SilentlyContinue
    
    foreach ($item in $items) {
        $itemName = $item.Name
        
        # Skip excluded directories
        $shouldExclude = $false
        foreach ($exclude in $ExcludeDirs) {
            if ($itemName -like $exclude -or $item.PSIsContainer -and $itemName -eq $exclude) {
                $shouldExclude = $true
                break
            }
        }
        
        if ($shouldExclude) {
            continue
        }
        
        $destItem = Join-Path $Destination $itemName
        
        try {
            if ($item.PSIsContainer) {
                # Create directory
                New-Item -ItemType Directory -Path $destItem -Force | Out-Null
                Copy-Directory -Source $item.FullName -Destination $destItem -ExcludeDirs $ExcludeDirs -ExcludeFiles $ExcludeFiles
            } else {
                # Check if file should be excluded
                $fileExcluded = $false
                foreach ($exclude in $ExcludeFiles) {
                    if ($itemName -like $exclude) {
                        $fileExcluded = $true
                        break
                    }
                }
                
                if (-not $fileExcluded) {
                    Copy-Item -Path $item.FullName -Destination $destItem -Force -ErrorAction Stop
                    $script:copyCount++
                    if ($script:copyCount % 100 -eq 0) {
                        Write-Host "  Copied $copyCount files..." -ForegroundColor Gray
                    }
                }
            }
        } catch {
            $script:errorCount++
            $errorMsg = "Error copying $($item.FullName): $_"
            Write-Host "  [WARNING] $errorMsg" -ForegroundColor Yellow
            $errorMsg | Out-File -FilePath $backupLog -Append -Encoding UTF8
        }
    }
}

# Create destination directory
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

# Copy files
Copy-Directory -Source $SourcePath -Destination $destinationPath -ExcludeDirs $excludeDirs -ExcludeFiles $excludeFiles

Write-Host ""
Write-Host "[OK] Backup completed!" -ForegroundColor Green
Write-Host "  Files copied: $copyCount" -ForegroundColor White
if ($errorCount -gt 0) {
    Write-Host "  Errors: $errorCount (see log)" -ForegroundColor Yellow
}

# Create backup info file
$infoFile = Join-Path $backupPath "backup-info.txt"
$infoContent = @"
Backup Information
==================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source: $SourcePath
Destination: $destinationPath
Structure: U&I/$dateFormat
Files Copied: $copyCount
Errors: $errorCount

Backup Location: $backupPath
"@
$infoContent | Out-File -FilePath $infoFile -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Location: $backupPath" -ForegroundColor White
Write-Host "  Files: $copyCount" -ForegroundColor White
Write-Host "  Log: $backupLog" -ForegroundColor White
Write-Host "  Info: $infoFile" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""






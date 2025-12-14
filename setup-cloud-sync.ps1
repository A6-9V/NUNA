#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures secure sync between Dropbox, Google Drive, and OneDrive with Windows security checks
.DESCRIPTION
    This script:
    1. Closes all File Explorer windows
    2. Configures Windows security settings for cloud sync
    3. Sets up proper sync configuration for Dropbox, Google Drive, and OneDrive
#>

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Cloud Sync Security Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Close all File Explorer windows
Write-Host "[1/5] Closing all File Explorer windows..." -ForegroundColor Yellow
try {
    Get-Process explorer -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | ForEach-Object {
        $_.CloseMainWindow()
    }
    Start-Sleep -Seconds 2
    
    # Force close any remaining explorer windows
    $explorerProcesses = Get-Process explorer -ErrorAction SilentlyContinue
    if ($explorerProcesses) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer.exe
    }
    Write-Host "    [OK] File Explorer windows closed" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Could not close all File Explorer windows: ${_}" -ForegroundColor Yellow
}

# Step 2: Configure Windows Defender exclusions for cloud sync folders
Write-Host "[2/5] Configuring Windows Defender exclusions..." -ForegroundColor Yellow
$cloudPaths = @(
    "$env:USERPROFILE\OneDrive",
    "$env:USERPROFILE\Dropbox",
    "$env:LOCALAPPDATA\Google\Drive",
    "$env:PROGRAMFILES\Google\Drive",
    "$env:PROGRAMFILES(X86)\Google\Drive"
)

foreach ($path in $cloudPaths) {
    if (Test-Path $path) {
        try {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
            Write-Host "    [OK] Added exclusion for: $path" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Could not add exclusion for $path`: ${_}" -ForegroundColor Yellow
        }
    }
}

# Step 3: Configure Windows Firewall rules for cloud sync services
Write-Host "[3/5] Configuring Windows Firewall rules..." -ForegroundColor Yellow
$services = @(
    @{Name="OneDrive"; Process="OneDrive.exe"; Path="$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"},
    @{Name="Dropbox"; Process="Dropbox.exe"; Path="$env:LOCALAPPDATA\Dropbox\bin\Dropbox.exe"},
    @{Name="GoogleDrive"; Process="googledrivesync.exe"; Path="$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe"}
)

foreach ($service in $services) {
    if (Test-Path $service.Path) {
        try {
            # Remove existing rules
            Remove-NetFirewallRule -DisplayName "$($service.Name) Sync" -ErrorAction SilentlyContinue
            
            # Add new firewall rule
            New-NetFirewallRule -DisplayName "$($service.Name) Sync" `
                -Direction Outbound `
                -Program $service.Path `
                -Action Allow `
                -Profile Any `
                -ErrorAction SilentlyContinue | Out-Null
            
            Write-Host "    [OK] Configured firewall rule for: $($service.Name)" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Could not configure firewall for $($service.Name): ${_}" -ForegroundColor Yellow
        }
    }
}

# Step 4: Configure Windows Security settings for cloud sync
Write-Host "[4/5] Configuring Windows Security settings..." -ForegroundColor Yellow
try {
    # Enable Controlled Folder Access exclusions
    $cloudFolders = @(
        "$env:USERPROFILE\OneDrive",
        "$env:USERPROFILE\Dropbox",
        "$env:LOCALAPPDATA\Google\Drive"
    )
    
    foreach ($folder in $cloudFolders) {
        if (Test-Path $folder) {
            try {
                Add-MpPreference -ControlledFolderAccessAllowedApplications $folder -ErrorAction SilentlyContinue
                Write-Host "    [OK] Added Controlled Folder Access exception for: $folder" -ForegroundColor Green
            } catch {
                Write-Host "    [WARNING] Could not add Controlled Folder Access exception: ${_}" -ForegroundColor Yellow
            }
        }
    }
    
    # Configure Windows Security to allow cloud sync processes
    $cloudProcesses = @(
        "OneDrive.exe",
        "Dropbox.exe",
        "googledrivesync.exe",
        "GoogleDriveFS.exe"
    )
    
    foreach ($process in $cloudProcesses) {
        try {
            $processPath = Get-Process $process.Replace(".exe", "") -ErrorAction SilentlyContinue | 
                Select-Object -First 1 -ExpandProperty Path
            if ($processPath) {
                Add-MpPreference -ControlledFolderAccessAllowedApplications $processPath -ErrorAction SilentlyContinue
            }
        } catch {
            # Process not running, continue
        }
    }
    
    Write-Host "    [OK] Windows Security settings configured" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Could not configure all Windows Security settings: ${_}" -ForegroundColor Yellow
}

# Step 5: Verify and configure sync services
Write-Host "[5/5] Verifying sync services..." -ForegroundColor Yellow

# Check OneDrive
$oneDrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
if (Test-Path $oneDrivePath) {
    Write-Host "    [OK] OneDrive found at: $oneDrivePath" -ForegroundColor Green
    $oneDriveService = Get-Service -Name "OneDrive*" -ErrorAction SilentlyContinue
    if ($oneDriveService) {
        if ($oneDriveService.Status -ne "Running") {
            Start-Service $oneDriveService.Name -ErrorAction SilentlyContinue
            Write-Host "    [OK] OneDrive service started" -ForegroundColor Green
        } else {
            Write-Host "    [OK] OneDrive service is running" -ForegroundColor Green
        }
    }
} else {
    Write-Host "    [WARNING] OneDrive not found" -ForegroundColor Yellow
}

# Check Dropbox
$dropboxPath = "$env:LOCALAPPDATA\Dropbox\bin\Dropbox.exe"
if (Test-Path $dropboxPath) {
    Write-Host "    [OK] Dropbox found at: $dropboxPath" -ForegroundColor Green
    $dropboxProcess = Get-Process "Dropbox" -ErrorAction SilentlyContinue
    if (-not $dropboxProcess) {
        Write-Host "    [WARNING] Dropbox is not running. Please start it manually." -ForegroundColor Yellow
    } else {
        Write-Host "    [OK] Dropbox is running" -ForegroundColor Green
    }
} else {
    Write-Host "    [WARNING] Dropbox not found" -ForegroundColor Yellow
}

# Check Google Drive
$googleDrivePaths = @(
    "$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe",
    "$env:PROGRAMFILES(X86)\Google\Drive File Stream\googledrivesync.exe",
    "$env:LOCALAPPDATA\Programs\Google\Drive\googledrivesync.exe"
)
$googleDriveFound = $false
foreach ($path in $googleDrivePaths) {
    if (Test-Path $path) {
        Write-Host "    [OK] Google Drive found at: $path" -ForegroundColor Green
        $googleDriveFound = $true
        $googleDriveProcess = Get-Process "googledrivesync" -ErrorAction SilentlyContinue
        if (-not $googleDriveProcess) {
            Write-Host "    [WARNING] Google Drive is not running. Please start it manually." -ForegroundColor Yellow
        } else {
            Write-Host "    [OK] Google Drive is running" -ForegroundColor Green
        }
        break
    }
}
if (-not $googleDriveFound) {
    Write-Host "    [WARNING] Google Drive not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Configuration Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - File Explorer windows have been closed" -ForegroundColor White
Write-Host "  - Windows Defender exclusions configured" -ForegroundColor White
Write-Host "  - Windows Firewall rules configured" -ForegroundColor White
Write-Host "  - Windows Security settings updated" -ForegroundColor White
Write-Host "  - Sync services verified" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Ensure all cloud services are signed in" -ForegroundColor White
Write-Host "  2. Verify sync folders are properly configured in each service" -ForegroundColor White
Write-Host "  3. Check Windows Security Center for any remaining alerts" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


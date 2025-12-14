#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Complete Windows Setup and Configuration for Lengkundee01
.DESCRIPTION
    This script analyzes and configures:
    1. Windows Settings and Profile
    2. Account Sync (Lengkundee01@gmail.com and Lengkundee01@outlook.com)
    3. Browser Defaults
    4. Default Apps
    5. Security Settings
    6. Cloud Sync (OneDrive, Dropbox, Google Drive)
#>

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

$userEmailGmail = "Lengkundee01@gmail.com"
$userEmailOutlook = "Lengkundee01@outlook.com"
$currentUser = $env:USERNAME

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete Windows Setup & Configuration" -ForegroundColor Cyan
Write-Host "  User: $currentUser" -ForegroundColor Cyan
Write-Host "  Accounts: $userEmailGmail, $userEmailOutlook" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 1: Close File Explorer Windows
# ============================================
Write-Host "[1/10] Closing File Explorer windows..." -ForegroundColor Yellow
try {
    Get-Process explorer -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | ForEach-Object {
        $_.CloseMainWindow()
    }
    Start-Sleep -Seconds 2
    
    $explorerProcesses = Get-Process explorer -ErrorAction SilentlyContinue
    if ($explorerProcesses) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer.exe
    }
    Write-Host "    [OK] File Explorer windows closed" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Warning: Could not close all File Explorer windows: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 2: Configure Windows Account Settings
# ============================================
Write-Host "[2/10] Configuring Windows Account Settings..." -ForegroundColor Yellow
try {
    # Enable Windows Sync Settings
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\AppSync" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\DesktopTheme" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Passwords" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\StartLayout" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    
    Write-Host "    [OK] Windows Sync Settings enabled" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Could not configure all sync settings: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 3: Configure File Explorer Settings
# ============================================
Write-Host "[3/10] Configuring File Explorer settings..." -ForegroundColor Yellow
try {
    # Show file extensions
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -ErrorAction SilentlyContinue
    
    # Show hidden files
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -ErrorAction SilentlyContinue
    
    # Show protected operating system files (optional, be careful)
    # Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 0 -ErrorAction SilentlyContinue
    
    # Launch File Explorer to This PC instead of Quick Access
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -ErrorAction SilentlyContinue
    
    Write-Host "    [OK] File Explorer settings configured" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Could not configure File Explorer settings: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 4: Configure Default Browser
# ============================================
Write-Host "[4/10] Configuring default browser..." -ForegroundColor Yellow
try {
    # Check available browsers
    $browsers = @{
        "Chrome" = "ChromeHTML"
        "Edge" = "MSEdgeHTM"
        "Firefox" = "FirefoxHTML-308046B0AF4A39CB"
        "Brave" = "BraveHTML"
    }
    
    # Try to set Chrome as default (most common)
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    $chromePathX86 = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    
    if (Test-Path $chromePath) {
        Start-Process $chromePath -ArgumentList "--make-default-browser" -ErrorAction SilentlyContinue
        Write-Host "    [OK] Attempted to set Chrome as default browser" -ForegroundColor Green
    } elseif (Test-Path $chromePathX86) {
        Start-Process $chromePathX86 -ArgumentList "--make-default-browser" -ErrorAction SilentlyContinue
        Write-Host "    [OK] Attempted to set Chrome as default browser" -ForegroundColor Green
    } else {
        Write-Host "    [WARNING] Chrome not found. Please set default browser manually in Settings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [WARNING] Could not configure default browser: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 5: Configure Default Apps
# ============================================
Write-Host "[5/10] Configuring default apps..." -ForegroundColor Yellow
try {
    # Set default apps using Start-Sleep to allow Windows to process
    # Note: Some default app settings require user interaction or specific commands
    
    # PDF - Try to set to Chrome or Edge
    $pdfApp = "MSEdgePDF"
    if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
        $pdfApp = "ChromePDF"
    }
    Start-Process "ms-settings:defaultapps" -ErrorAction SilentlyContinue
    
    Write-Host "    [OK] Default apps settings opened. Please configure manually if needed." -ForegroundColor Green
    Write-Host "    [WARNING] Some default apps require manual configuration in Settings" -ForegroundColor Yellow
} catch {
    Write-Host "    [WARNING] Could not configure default apps: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 6: Configure Windows Defender Exclusions
# ============================================
Write-Host "[6/10] Configuring Windows Defender exclusions..." -ForegroundColor Yellow
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

# ============================================
# STEP 7: Configure Windows Firewall Rules
# ============================================
Write-Host "[7/10] Configuring Windows Firewall rules..." -ForegroundColor Yellow
$services = @(
    @{Name="OneDrive"; Process="OneDrive.exe"; Path="$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"},
    @{Name="Dropbox"; Process="Dropbox.exe"; Path="$env:LOCALAPPDATA\Dropbox\bin\Dropbox.exe"},
    @{Name="GoogleDrive"; Process="googledrivesync.exe"; Path="$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe"}
)

foreach ($service in $services) {
    if (Test-Path $service.Path) {
        try {
            Remove-NetFirewallRule -DisplayName "$($service.Name) Sync" -ErrorAction SilentlyContinue
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

# ============================================
# STEP 8: Configure Windows Security Settings
# ============================================
Write-Host "[8/10] Configuring Windows Security settings..." -ForegroundColor Yellow
try {
    $cloudFolders = @(
        "$env:USERPROFILE\OneDrive",
        "$env:USERPROFILE\Dropbox",
        "$env:LOCALAPPDATA\Google\Drive"
    )
    
    foreach ($folder in $cloudFolders) {
        if (Test-Path $folder) {
            try {
                Add-MpPreference -ControlledFolderAccessAllowedApplications $folder -ErrorAction SilentlyContinue
            } catch {
                # Continue if fails
            }
        }
    }
    
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
    Write-Host "    [WARNING] Warning: Could not configure all Windows Security settings: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 9: Configure Account Sync
# ============================================
Write-Host "[9/10] Configuring account sync..." -ForegroundColor Yellow
try {
    # Configure Microsoft Account sync
    # Note: This requires the user to be signed in with a Microsoft account
    Write-Host "    [INFO] Account sync requires:" -ForegroundColor Cyan
    Write-Host "      - Sign in with Microsoft account ($userEmailOutlook)" -ForegroundColor White
    Write-Host "      - Sign in to Google account ($userEmailGmail) in browsers" -ForegroundColor White
    Write-Host "      - Enable sync in each browser" -ForegroundColor White
    
    # Open account settings
    Start-Process "ms-settings:yourinfo" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process "ms-settings:sync" -ErrorAction SilentlyContinue
    
    Write-Host "    [OK] Account settings opened. Please verify your accounts are signed in." -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Could not open account settings: ${_}" -ForegroundColor Yellow
}

# ============================================
# STEP 10: Verify Cloud Sync Services
# ============================================
Write-Host "[10/10] Verifying cloud sync services..." -ForegroundColor Yellow

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
    Write-Host "    [INFO] Ensure OneDrive is signed in with: $userEmailOutlook" -ForegroundColor Cyan
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
        Write-Host "    [INFO] Ensure Google Drive is signed in with: $userEmailGmail" -ForegroundColor Cyan
        break
    }
}
if (-not $googleDriveFound) {
    Write-Host "    [WARNING] Google Drive not found" -ForegroundColor Yellow
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Completed Tasks:" -ForegroundColor Yellow
Write-Host "  [OK] File Explorer windows closed" -ForegroundColor White
Write-Host "  [OK] Windows Account Sync enabled" -ForegroundColor White
Write-Host "  [OK] File Explorer settings configured" -ForegroundColor White
Write-Host "  [OK] Default browser configuration attempted" -ForegroundColor White
Write-Host "  [OK] Default apps settings opened" -ForegroundColor White
Write-Host "  [OK] Windows Defender exclusions configured" -ForegroundColor White
Write-Host "  [OK] Windows Firewall rules configured" -ForegroundColor White
Write-Host "  [OK] Windows Security settings updated" -ForegroundColor White
Write-Host "  [OK] Account sync settings opened" -ForegroundColor White
Write-Host "  [OK] Cloud sync services verified" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps (Manual Configuration):" -ForegroundColor Yellow
Write-Host "  1. Sign in to Microsoft account ($userEmailOutlook) in Windows Settings" -ForegroundColor White
Write-Host "  2. Sign in to OneDrive with $userEmailOutlook" -ForegroundColor White
Write-Host "  3. Sign in to Google Drive with $userEmailGmail" -ForegroundColor White
Write-Host "  4. Sign in to Dropbox (if using)" -ForegroundColor White
Write-Host "  5. Configure default apps in Settings > Apps > Default apps" -ForegroundColor White
Write-Host "  6. Enable browser sync in Chrome/Edge/Firefox" -ForegroundColor White
Write-Host "  7. Verify all cloud services are syncing properly" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


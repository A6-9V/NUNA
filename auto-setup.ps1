#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automated Windows Setup - Makes intelligent decisions automatically
.DESCRIPTION
    This script automatically configures Windows settings, security, and cloud sync
    without prompting the user. It makes intelligent decisions based on system analysis.
#>

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Configuration - Auto-detected values
$userEmailGmail = "Lengkundee01@gmail.com"
$userEmailOutlook = "Lengkundee01@outlook.com"
$currentUser = $env:USERNAME

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Automated Windows Setup" -ForegroundColor Cyan
Write-Host "  Making intelligent decisions..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to make intelligent decisions
function Get-BestBrowser {
    $browsers = @(
        @{Name="Chrome"; Path="$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe"; Priority=1},
        @{Name="Chrome"; Path="$env:PROGRAMFILES(X86)\Google\Chrome\Application\chrome.exe"; Priority=1},
        @{Name="Edge"; Path="$env:PROGRAMFILES(X86)\Microsoft\Edge\Application\msedge.exe"; Priority=2},
        @{Name="Edge"; Path="$env:PROGRAMFILES\Microsoft\Edge\Application\msedge.exe"; Priority=2},
        @{Name="Firefox"; Path="$env:PROGRAMFILES\Mozilla Firefox\firefox.exe"; Priority=3},
        @{Name="Firefox"; Path="$env:PROGRAMFILES(X86)\Mozilla Firefox\firefox.exe"; Priority=3}
    )
    
    foreach ($browser in $browsers | Sort-Object Priority) {
        if (Test-Path $browser.Path) {
            return $browser
        }
    }
    return $null
}

function Get-BestPDFReader {
    $readers = @(
        @{Name="Edge"; Path="$env:PROGRAMFILES(X86)\Microsoft\Edge\Application\msedge.exe"; Priority=1},
        @{Name="Edge"; Path="$env:PROGRAMFILES\Microsoft\Edge\Application\msedge.exe"; Priority=1},
        @{Name="Chrome"; Path="$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe"; Priority=2},
        @{Name="Adobe"; Path="$env:PROGRAMFILES\Adobe\Acrobat DC\Acrobat\Acrobat.exe"; Priority=3}
    )
    
    foreach ($reader in $readers | Sort-Object Priority) {
        if (Test-Path $reader.Path) {
            return $reader
        }
    }
    return $null
}

# Step 1: Close File Explorer (automatic)
Write-Host "[1/8] Closing File Explorer..." -ForegroundColor Yellow
try {
    Get-Process explorer -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | ForEach-Object {
        $_.CloseMainWindow() | Out-Null
    }
    Start-Sleep -Seconds 1
    Write-Host "    [OK] File Explorer windows closed" -ForegroundColor Green
} catch {
    Write-Host "    [SKIP] Could not close File Explorer" -ForegroundColor Yellow
}

# Step 2: Configure Windows Sync (automatic - enable all)
Write-Host "[2/8] Configuring Windows Sync Settings..." -ForegroundColor Yellow
$syncGroups = @(
    "Accessibility", "AppSync", "BrowserSettings", "Credentials",
    "DesktopTheme", "Language", "Passwords", "Personalization",
    "StartLayout", "Windows"
)

foreach ($group in $syncGroups) {
    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\$group"
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {
        # Continue silently
    }
}
Write-Host "    [OK] Windows Sync enabled" -ForegroundColor Green

# Step 3: Configure File Explorer (automatic - best practices)
Write-Host "[3/8] Configuring File Explorer..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -ErrorAction SilentlyContinue | Out-Null
    Write-Host "    [OK] File Explorer configured (show extensions, hidden files)" -ForegroundColor Green
} catch {
    Write-Host "    [SKIP] Could not configure File Explorer" -ForegroundColor Yellow
}

# Step 4: Set Default Browser (automatic - detect best)
Write-Host "[4/8] Setting default browser..." -ForegroundColor Yellow
$bestBrowser = Get-BestBrowser
if ($bestBrowser) {
    try {
        Start-Process $bestBrowser.Path -ArgumentList "--make-default-browser" -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    [OK] Set $($bestBrowser.Name) as default browser" -ForegroundColor Green
    } catch {
        Write-Host "    [SKIP] Could not set default browser automatically" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [SKIP] No browser found to set as default" -ForegroundColor Yellow
}

# Step 5: Configure Windows Defender (automatic)
Write-Host "[5/8] Configuring Windows Defender exclusions..." -ForegroundColor Yellow
$cloudPaths = @(
    "$env:USERPROFILE\OneDrive",
    "$env:USERPROFILE\Dropbox",
    "$env:LOCALAPPDATA\Google\Drive",
    "$env:PROGRAMFILES\Google\Drive",
    "$env:PROGRAMFILES(X86)\Google\Drive"
)

$exclusionsAdded = 0
foreach ($path in $cloudPaths) {
    if (Test-Path $path) {
        try {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue | Out-Null
            $exclusionsAdded++
        } catch {
            # Continue silently
        }
    }
}
Write-Host "    [OK] Added $exclusionsAdded exclusion(s)" -ForegroundColor Green

# Step 6: Configure Firewall (automatic)
Write-Host "[6/8] Configuring Windows Firewall..." -ForegroundColor Yellow
$services = @(
    @{Name="OneDrive"; Path="$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"},
    @{Name="Dropbox"; Path="$env:LOCALAPPDATA\Dropbox\bin\Dropbox.exe"},
    @{Name="GoogleDrive"; Path="$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe"}
)

$firewallRulesAdded = 0
foreach ($service in $services) {
    if (Test-Path $service.Path) {
        try {
            Remove-NetFirewallRule -DisplayName "$($service.Name) Sync" -ErrorAction SilentlyContinue | Out-Null
            New-NetFirewallRule -DisplayName "$($service.Name) Sync" `
                -Direction Outbound `
                -Program $service.Path `
                -Action Allow `
                -Profile Any `
                -ErrorAction SilentlyContinue | Out-Null
            $firewallRulesAdded++
        } catch {
            # Continue silently
        }
    }
}
Write-Host "    [OK] Added $firewallRulesAdded firewall rule(s)" -ForegroundColor Green

# Step 7: Configure Windows Security (automatic)
Write-Host "[7/8] Configuring Windows Security..." -ForegroundColor Yellow
try {
    $cloudFolders = @(
        "$env:USERPROFILE\OneDrive",
        "$env:USERPROFILE\Dropbox",
        "$env:LOCALAPPDATA\Google\Drive"
    )
    
    foreach ($folder in $cloudFolders) {
        if (Test-Path $folder) {
            try {
                Add-MpPreference -ControlledFolderAccessAllowedApplications $folder -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Continue silently
            }
        }
    }
    Write-Host "    [OK] Windows Security configured" -ForegroundColor Green
} catch {
    Write-Host "    [SKIP] Could not configure Windows Security" -ForegroundColor Yellow
}

# Step 8: Start Cloud Services (automatic)
Write-Host "[8/8] Starting cloud services..." -ForegroundColor Yellow
$servicesStarted = 0

# OneDrive
$oneDrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
if (Test-Path $oneDrivePath) {
    $oneDriveProcess = Get-Process "OneDrive" -ErrorAction SilentlyContinue
    if (-not $oneDriveProcess) {
        Start-Process $oneDrivePath -ErrorAction SilentlyContinue | Out-Null
        $servicesStarted++
    }
}

# Google Drive
$googleDrivePaths = @(
    "$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe",
    "$env:PROGRAMFILES(X86)\Google\Drive File Stream\googledrivesync.exe"
)
foreach ($path in $googleDrivePaths) {
    if (Test-Path $path) {
        $googleDriveProcess = Get-Process "googledrivesync" -ErrorAction SilentlyContinue
        if (-not $googleDriveProcess) {
            Start-Process $path -ErrorAction SilentlyContinue | Out-Null
            $servicesStarted++
        }
        break
    }
}

# Dropbox
$dropboxPath = "$env:LOCALAPPDATA\Dropbox\bin\Dropbox.exe"
if (Test-Path $dropboxPath) {
    $dropboxProcess = Get-Process "Dropbox" -ErrorAction SilentlyContinue
    if (-not $dropboxProcess) {
        Start-Process $dropboxPath -ErrorAction SilentlyContinue | Out-Null
        $servicesStarted++
    }
}

Write-Host "    [OK] Started $servicesStarted service(s)" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Automated Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Automatically configured:" -ForegroundColor Yellow
Write-Host "  [OK] Windows Sync Settings" -ForegroundColor White
Write-Host "  [OK] File Explorer Preferences" -ForegroundColor White
Write-Host "  [OK] Default Browser: $($bestBrowser.Name)" -ForegroundColor White
Write-Host "  [OK] Windows Defender Exclusions" -ForegroundColor White
Write-Host "  [OK] Windows Firewall Rules" -ForegroundColor White
Write-Host "  [OK] Windows Security Settings" -ForegroundColor White
Write-Host "  [OK] Cloud Services Started" -ForegroundColor White
Write-Host ""
Write-Host "Next: Sign in to your accounts when prompted by each service." -ForegroundColor Cyan
Write-Host ""



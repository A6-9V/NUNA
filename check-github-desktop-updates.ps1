# Check GitHub Desktop Release Notes and Updates
# This script checks for GitHub Desktop updates and reviews release notes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Desktop Release Notes Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub Desktop is installed
$desktopPaths = @(
    "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe",
    "$env:PROGRAMFILES\GitHub Desktop\GitHubDesktop.exe"
)
# Add ProgramFiles(x86) path if it exists (for 32-bit systems)
try {
    $programFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value
    if ($programFilesX86) {
        $desktopPaths += "$programFilesX86\GitHub Desktop\GitHubDesktop.exe"
    }
}
catch {
    # ProgramFiles(x86) may not exist on 64-bit only systems
}

$desktopInstalled = $false
$desktopVersion = $null

foreach ($path in $desktopPaths) {
    if (Test-Path $path) {
        $desktopInstalled = $true
        # Get version information
        try {
            $versionInfo = (Get-Item $path).VersionInfo
            $desktopVersion = $versionInfo.FileVersion
            Write-Host "[OK] GitHub Desktop found" -ForegroundColor Green
            Write-Host "     Path: $path" -ForegroundColor White
            Write-Host "     Version: $desktopVersion" -ForegroundColor White
            
            # Check if version is older than 3.3.0
            if ($desktopVersion) {
                $parts = $desktopVersion -split '\.'
                if ($parts.Count -ge 2) {
                    $major = [int]$parts[0]
                    $minor = [int]$parts[1]
                    if (($major -lt 3) -or ($major -eq 3 -and $minor -lt 3)) {
                        Write-Host "[WARNING] GitHub Desktop version ($desktopVersion) is older than 3.3.0. Consider updating." -ForegroundColor Yellow
                    }
                }
            }
        } catch {
            Write-Host "[OK] GitHub Desktop found at: $path" -ForegroundColor Green
        }
        break
    }
}

if (-not $desktopInstalled) {
    Write-Host "[INFO] GitHub Desktop not installed" -ForegroundColor Yellow
    Write-Host "[INFO] Download from: https://desktop.github.com/" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Release Notes Information:" -ForegroundColor Yellow
Write-Host "  URL: https://desktop.github.com/release-notes/" -ForegroundColor Cyan
Write-Host ""

# Check for update mechanism
Write-Host "Update Check:" -ForegroundColor Yellow
if ($desktopInstalled) {
    Write-Host "  [INFO] GitHub Desktop checks for updates automatically" -ForegroundColor Cyan
    Write-Host "  [INFO] Updates are downloaded and installed automatically" -ForegroundColor Cyan
    Write-Host "  [INFO] You can check for updates manually:" -ForegroundColor Cyan
    Write-Host "    Help > About GitHub Desktop" -ForegroundColor White
    Write-Host ""
    
    # Check settings for update preferences
    $settingsPath = "$env:APPDATA\GitHub Desktop\settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            if ($settings.updateStore) {
                Write-Host "  [OK] Update store configured: $($settings.updateStore)" -ForegroundColor Green
            }
        } catch {
            # Settings may not be readable or in different format
        }
    }
} else {
    Write-Host "  [INFO] Install GitHub Desktop to enable automatic updates" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Release Notes Review:" -ForegroundColor Yellow
Write-Host "  [INFO] Review release notes regularly for:" -ForegroundColor Cyan
Write-Host "    - New features and improvements" -ForegroundColor White
Write-Host "    - Bug fixes and security updates" -ForegroundColor White
Write-Host "    - Breaking changes (if any)" -ForegroundColor White
Write-Host "    - Compatibility updates" -ForegroundColor White
Write-Host ""

# Open release notes in browser
Write-Host "Would you like to open the release notes page? (Y/N)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq "Y" -or $response -eq "y") {
    Write-Host "  [INFO] Opening release notes..." -ForegroundColor Cyan
    Start-Process "https://desktop.github.com/release-notes/"
    Write-Host "  [OK] Release notes opened in browser" -ForegroundColor Green
}

Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  - Release Notes: https://desktop.github.com/release-notes/" -ForegroundColor Cyan
Write-Host "  - Download: https://desktop.github.com/" -ForegroundColor Cyan
Write-Host "  - Rules Document: GITHUB-DESKTOP-RULES.md" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Release Notes Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


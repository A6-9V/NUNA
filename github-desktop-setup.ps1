# GitHub Desktop Setup and Configuration
# This script installs and configures GitHub Desktop with automation rules

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Desktop Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub Desktop is installed
$desktopPaths = @(
    "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe",
    "$env:PROGRAMFILES\GitHub Desktop\GitHubDesktop.exe",
    "$env:PROGRAMFILES(X86)\GitHub Desktop\GitHubDesktop.exe"
)

$desktopInstalled = $false
$desktopPath = $null

foreach ($path in $desktopPaths) {
    if (Test-Path $path) {
        $desktopInstalled = $true
        $desktopPath = $path
        Write-Host "[OK] GitHub Desktop found at: $path" -ForegroundColor Green
        break
    }
}

if (-not $desktopInstalled) {
    Write-Host "[INFO] GitHub Desktop not found" -ForegroundColor Yellow
    Write-Host "[INFO] Download from: https://desktop.github.com/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Would you like to open the download page? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "https://desktop.github.com/"
    }
    exit
}

# Configure GitHub Desktop settings
Write-Host ""
Write-Host "Configuring GitHub Desktop..." -ForegroundColor Yellow

# GitHub Desktop settings are stored in:
# %APPDATA%\GitHub Desktop\settings.json

$settingsPath = "$env:APPDATA\GitHub Desktop\settings.json"

if (Test-Path $settingsPath) {
    Write-Host "[OK] Settings file found" -ForegroundColor Green
    
    # Read current settings
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        # Configure automation-friendly settings
        Write-Host "[1] Configuring settings..." -ForegroundColor Yellow
        
        # Enable automatic updates
        $settings | Add-Member -MemberType NoteProperty -Name "updateStore" -Value "GitHubDesktop" -Force -ErrorAction SilentlyContinue
        
        # Configure git settings
        if (-not $settings.git) {
            $settings | Add-Member -MemberType NoteProperty -Name "git" -Value @{} -Force
        }
        
        # Set git user (if not set)
        if (-not $settings.git.userName) {
            $settings.git.userName = "Mouy-leng"
        }
        if (-not $settings.git.userEmail) {
            $settings.git.userEmail = "Mouy-leng@users.noreply.github.com"
        }
        
        # Enable shell integration
        $settings | Add-Member -MemberType NoteProperty -Name "shell" -Value "PowerShell" -Force -ErrorAction SilentlyContinue
        
        # Save settings
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "    [OK] Settings configured" -ForegroundColor Green
        
    } catch {
        Write-Host "    [WARNING] Could not modify settings: ${_}" -ForegroundColor Yellow
        Write-Host "    [INFO] You may need to configure settings manually in GitHub Desktop" -ForegroundColor Cyan
    }
} else {
    Write-Host "[INFO] Settings file not found (will be created on first launch)" -ForegroundColor Yellow
}

# Configure repository association
Write-Host "[2] Configuring repository..." -ForegroundColor Yellow
$repoPath = "C:\Users\USER\OneDrive"
if (Test-Path (Join-Path $repoPath ".git")) {
    Write-Host "    [OK] Git repository found at: $repoPath" -ForegroundColor Green
    Write-Host "    [INFO] Open GitHub Desktop and add this repository:" -ForegroundColor Cyan
    Write-Host "      File > Add Local Repository > $repoPath" -ForegroundColor White
} else {
    Write-Host "    [INFO] No git repository found in current directory" -ForegroundColor Yellow
}

# Check for updates
Write-Host "[3] Checking for updates..." -ForegroundColor Yellow
Write-Host "    [INFO] GitHub Desktop checks for updates automatically" -ForegroundColor Cyan
Write-Host "    [INFO] Release notes: https://desktop.github.com/release-notes/" -ForegroundColor Cyan

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Desktop Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Launch GitHub Desktop" -ForegroundColor White
Write-Host "  2. Sign in with your GitHub account" -ForegroundColor White
Write-Host "  3. Add local repository: $repoPath" -ForegroundColor White
Write-Host "  4. Configure preferences in GitHub Desktop" -ForegroundColor White
Write-Host ""


# Check status of cloud sync services
# This script checks if OneDrive, Google Drive, and Dropbox are installed and running

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cloud Services Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check OneDrive
Write-Host "Checking OneDrive..." -ForegroundColor Yellow
$oneDrivePaths = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
    "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe",
    "$env:PROGRAMFILES(X86)\Microsoft OneDrive\OneDrive.exe"
)

$oneDriveFound = $false
foreach ($path in $oneDrivePaths) {
    if (Test-Path $path) {
        Write-Host "  [OK] OneDrive found at: $path" -ForegroundColor Green
        $oneDriveFound = $true
        
        $oneDriveProcess = Get-Process "OneDrive" -ErrorAction SilentlyContinue
        if ($oneDriveProcess) {
            Write-Host "  [OK] OneDrive is running" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] OneDrive is not running" -ForegroundColor Yellow
            Write-Host "  [INFO] Starting OneDrive..." -ForegroundColor Cyan
            Start-Process $path -ErrorAction SilentlyContinue
        }
        break
    }
}

if (-not $oneDriveFound) {
    Write-Host "  [WARNING] OneDrive not found" -ForegroundColor Yellow
    Write-Host "  [INFO] Download from: https://www.microsoft.com/microsoft-365/onedrive/download" -ForegroundColor Cyan
}

Write-Host ""

# Check Google Drive
Write-Host "Checking Google Drive..." -ForegroundColor Yellow
$googleDrivePaths = @(
    "$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe",
    "$env:PROGRAMFILES(X86)\Google\Drive File Stream\googledrivesync.exe",
    "$env:LOCALAPPDATA\Programs\Google\Drive\googledrivesync.exe",
    "$env:PROGRAMFILES\Google\Drive\googledrivesync.exe"
)

$googleDriveFound = $false
foreach ($path in $googleDrivePaths) {
    if (Test-Path $path) {
        Write-Host "  [OK] Google Drive found at: $path" -ForegroundColor Green
        $googleDriveFound = $true
        
        $googleDriveProcess = Get-Process "googledrivesync" -ErrorAction SilentlyContinue
        if ($googleDriveProcess) {
            Write-Host "  [OK] Google Drive is running" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Google Drive is not running" -ForegroundColor Yellow
            Write-Host "  [INFO] Starting Google Drive..." -ForegroundColor Cyan
            Start-Process $path -ErrorAction SilentlyContinue
        }
        break
    }
}

if (-not $googleDriveFound) {
    Write-Host "  [WARNING] Google Drive not found" -ForegroundColor Yellow
    Write-Host "  [INFO] Download from: https://www.google.com/drive/download/" -ForegroundColor Cyan
}

Write-Host ""

# Check Dropbox
Write-Host "Checking Dropbox..." -ForegroundColor Yellow
$dropboxPaths = @(
    "$env:LOCALAPPDATA\Dropbox\bin\Dropbox.exe",
    "$env:APPDATA\Dropbox\bin\Dropbox.exe",
    "$env:PROGRAMFILES\Dropbox\Client\Dropbox.exe",
    "$env:PROGRAMFILES(X86)\Dropbox\Client\Dropbox.exe"
)

$dropboxFound = $false
foreach ($path in $dropboxPaths) {
    if (Test-Path $path) {
        Write-Host "  [OK] Dropbox found at: $path" -ForegroundColor Green
        $dropboxFound = $true
        
        $dropboxProcess = Get-Process "Dropbox" -ErrorAction SilentlyContinue
        if ($dropboxProcess) {
            Write-Host "  [OK] Dropbox is running" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Dropbox is not running" -ForegroundColor Yellow
            Write-Host "  [INFO] Starting Dropbox..." -ForegroundColor Cyan
            Start-Process $path -ErrorAction SilentlyContinue
        }
        break
    }
}

if (-not $dropboxFound) {
    Write-Host "  [WARNING] Dropbox not found" -ForegroundColor Yellow
    Write-Host "  [INFO] Download from: https://www.dropbox.com/downloading" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($oneDriveFound) {
    Write-Host "  OneDrive: [OK] Installed" -ForegroundColor Green
} else {
    Write-Host "  OneDrive: [MISSING] Needs installation" -ForegroundColor Yellow
}

if ($googleDriveFound) {
    Write-Host "  Google Drive: [OK] Installed" -ForegroundColor Green
} else {
    Write-Host "  Google Drive: [MISSING] Needs installation" -ForegroundColor Yellow
}

if ($dropboxFound) {
    Write-Host "  Dropbox: [OK] Installed" -ForegroundColor Green
} else {
    Write-Host "  Dropbox: [MISSING] Needs installation" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Sign in to each service with your accounts:" -ForegroundColor White
Write-Host "     - OneDrive: Lengkundee01@outlook.com" -ForegroundColor White
Write-Host "     - Google Drive: Lengkundee01@gmail.com" -ForegroundColor White
Write-Host "  2. Verify sync is working by checking system tray icons" -ForegroundColor White
Write-Host "  3. Create test files in each cloud folder to verify sync" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



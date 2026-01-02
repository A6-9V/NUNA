# Uninstall Dropbox Completely
# This script removes Dropbox and all its components from the system

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dropbox Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires administrator privileges." -ForegroundColor Red
    Write-Host "[INFO] Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Step 1: Stop Dropbox processes
Write-Host "[1/5] Stopping Dropbox processes..." -ForegroundColor Yellow
$dropboxProcesses = Get-Process | Where-Object { $_.ProcessName -like "*Dropbox*" }
if ($dropboxProcesses) {
    foreach ($process in $dropboxProcesses) {
        Write-Host "  [INFO] Stopping process: $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Cyan
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    Write-Host "  [OK] All Dropbox processes stopped" -ForegroundColor Green
} else {
    Write-Host "  [OK] No Dropbox processes running" -ForegroundColor Green
}

# Step 2: Uninstall Dropbox using official uninstaller
Write-Host ""
Write-Host "[2/5] Uninstalling Dropbox..." -ForegroundColor Yellow

$uninstallPaths = @(
    "C:\Program Files (x86)\Dropbox\Client\DropboxUninstaller.exe",
    "$env:PROGRAMFILES\Dropbox\Client\DropboxUninstaller.exe",
    "$env:PROGRAMFILES(X86)\Dropbox\Client\DropboxUninstaller.exe"
)

$uninstallerFound = $false
foreach ($uninstallPath in $uninstallPaths) {
    if (Test-Path $uninstallPath) {
        Write-Host "  [INFO] Found uninstaller at: $uninstallPath" -ForegroundColor Cyan
        Write-Host "  [INFO] Running uninstaller (this may take a moment)..." -ForegroundColor Cyan
        
        try {
            $process = Start-Process -FilePath $uninstallPath -ArgumentList "/InstallType:MACHINE" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-Host "  [OK] Dropbox uninstalled successfully" -ForegroundColor Green
            } else {
                Write-Host "  [WARNING] Uninstaller exited with code: $($process.ExitCode)" -ForegroundColor Yellow
            }
            $uninstallerFound = $true
            break
        } catch {
            Write-Host "  [WARNING] Failed to run uninstaller: $_" -ForegroundColor Yellow
        }
    }
}

if (-not $uninstallerFound) {
    Write-Host "  [WARNING] Official uninstaller not found, will remove files manually" -ForegroundColor Yellow
}

# Step 3: Remove Dropbox Update Helper
Write-Host ""
Write-Host "[3/5] Removing Dropbox Update Helper..." -ForegroundColor Yellow
try {
    $updateHelper = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*Dropbox Update Helper*" }
    if ($updateHelper) {
        Write-Host "  [INFO] Found Dropbox Update Helper, uninstalling..." -ForegroundColor Cyan
        $uninstallString = $updateHelper.UninstallString
        if ($uninstallString) {
            # MSI uninstall
            $productCode = $uninstallString -replace '.*\{([^}]+)\}.*', '$1'
            Start-Process "msiexec.exe" -ArgumentList "/x{$productCode}", "/quiet", "/norestart" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            Write-Host "  [OK] Dropbox Update Helper removed" -ForegroundColor Green
        }
    } else {
        Write-Host "  [OK] Dropbox Update Helper not found" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARNING] Could not remove Update Helper: $_" -ForegroundColor Yellow
}

# Step 4: Remove Dropbox folders
Write-Host ""
Write-Host "[4/5] Removing Dropbox folders..." -ForegroundColor Yellow

$dropboxFolders = @(
    "$env:LOCALAPPDATA\Dropbox",
    "$env:APPDATA\Dropbox",
    "$env:USERPROFILE\Dropbox",
    "C:\Program Files\Dropbox",
    "C:\Program Files (x86)\Dropbox"
)

foreach ($folder in $dropboxFolders) {
    if (Test-Path $folder) {
        Write-Host "  [INFO] Removing: $folder" -ForegroundColor Cyan
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Removed: $folder" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Could not remove $folder : $_" -ForegroundColor Yellow
            # Try again after a short delay
            Start-Sleep -Seconds 1
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Step 5: Clean up registry entries
Write-Host ""
Write-Host "[5/5] Cleaning up registry entries..." -ForegroundColor Yellow

$registryPaths = @(
    "HKLM:\Software\Dropbox",
    "HKLM:\Software\Wow6432Node\Dropbox",
    "HKCU:\Software\Dropbox"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        Write-Host "  [INFO] Removing registry key: $regPath" -ForegroundColor Cyan
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Removed registry key: $regPath" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Could not remove registry key $regPath : $_" -ForegroundColor Yellow
        }
    }
}

# Final verification
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uninstall Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify removal
$stillInstalled = $false
$remainingPaths = @(
    "$env:LOCALAPPDATA\Dropbox",
    "$env:APPDATA\Dropbox",
    "$env:USERPROFILE\Dropbox",
    "C:\Program Files\Dropbox",
    "C:\Program Files (x86)\Dropbox"
)

Write-Host "Verifying removal..." -ForegroundColor Yellow
foreach ($path in $remainingPaths) {
    if (Test-Path $path) {
        Write-Host "  [WARNING] Still exists: $path" -ForegroundColor Yellow
        $stillInstalled = $true
    }
}

$dropboxProcesses = Get-Process | Where-Object { $_.ProcessName -like "*Dropbox*" } -ErrorAction SilentlyContinue
if ($dropboxProcesses) {
    Write-Host "  [WARNING] Dropbox processes still running" -ForegroundColor Yellow
    $stillInstalled = $true
}

if (-not $stillInstalled) {
    Write-Host "  [OK] Dropbox has been completely removed from the system" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Some Dropbox components may still remain" -ForegroundColor Yellow
    Write-Host "  [INFO] You may need to manually remove remaining files" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

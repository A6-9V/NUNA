# Cleanup Dropbox After Reboot
# Run this script after restarting your computer to remove remaining Dropbox folders

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dropbox Cleanup (Post-Reboot)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires administrator privileges." -ForegroundColor Red
    Write-Host "[INFO] Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

$foldersToRemove = @(
    "$env:USERPROFILE\Dropbox",
    "C:\Program Files\Dropbox",
    "C:\Program Files (x86)\Dropbox"
)

Write-Host "Removing remaining Dropbox folders..." -ForegroundColor Yellow
Write-Host ""

foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        Write-Host "Removing: $folder" -ForegroundColor Cyan
        
        # Take ownership
        Write-Host "  Taking ownership..." -ForegroundColor Gray
        takeown /F $folder /R /D Y 2>&1 | Out-Null
        
        # Grant full permissions
        Write-Host "  Setting permissions..." -ForegroundColor Gray
        icacls $folder /grant "$env:USERNAME`:F" /T 2>&1 | Out-Null
        icacls $folder /grant "Administrators:F" /T 2>&1 | Out-Null
        
        # Remove folder
        Write-Host "  Deleting folder..." -ForegroundColor Gray
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Removed successfully" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Could not remove: $_" -ForegroundColor Yellow
        }
        Write-Host ""
    } else {
        Write-Host "[OK] Already removed: $folder" -ForegroundColor Green
    }
}

# Final verification
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allPaths = @(
    "$env:LOCALAPPDATA\Dropbox",
    "$env:APPDATA\Dropbox",
    "$env:USERPROFILE\Dropbox",
    "C:\Program Files\Dropbox",
    "C:\Program Files (x86)\Dropbox"
)

$remaining = @()
foreach ($path in $allPaths) {
    if (Test-Path $path) {
        $remaining += $path
    }
}

if ($remaining.Count -eq 0) {
    Write-Host "[SUCCESS] All Dropbox folders have been completely removed!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] The following folders still remain:" -ForegroundColor Yellow
    foreach ($path in $remaining) {
        Write-Host "  - $path" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "[INFO] These folders may be locked by another process." -ForegroundColor Cyan
    Write-Host "[INFO] Try closing all applications and running this script again." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Run VSCode as Administrator with Copilot
# This script launches VSCode with administrator privileges

$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:PROGRAMFILES\Microsoft VS Code\Code.exe",
    "$env:PROGRAMFILES(X86)\Microsoft VS Code\Code.exe",
    "$env:APPDATA\Local\Programs\Microsoft VS Code\Code.exe"
)

$vscodeFound = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) {
        Write-Host "Found VSCode at: $path" -ForegroundColor Green
        Write-Host "Launching VSCode as Administrator..." -ForegroundColor Yellow
        Start-Process $path -Verb RunAs
        $vscodeFound = $true
        break
    }
}

if (-not $vscodeFound) {
    Write-Host "VSCode not found in standard locations." -ForegroundColor Yellow
    Write-Host "Please provide the path to Code.exe:" -ForegroundColor Cyan
    $customPath = Read-Host "Path"
    if (Test-Path $customPath) {
        Start-Process $customPath -Verb RunAs
    } else {
        Write-Host "Invalid path. Exiting." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "VSCode should now be running with administrator privileges." -ForegroundColor Green
Write-Host "GitHub Copilot should be available if installed." -ForegroundColor Green
Write-Host ""
Write-Host "To enable Copilot:" -ForegroundColor Yellow
Write-Host "  1. Install GitHub Copilot extension" -ForegroundColor White
Write-Host "  2. Sign in with your GitHub account" -ForegroundColor White
Write-Host "  3. Start using Copilot features" -ForegroundColor White



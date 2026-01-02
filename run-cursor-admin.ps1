# Run Cursor as Administrator with Copilot
# This script launches Cursor with administrator privileges

$cursorPaths = @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:PROGRAMFILES\Cursor\Cursor.exe",
    "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe",
    "$env:APPDATA\Local\Programs\Cursor\Cursor.exe"
)

$cursorFound = $false
foreach ($path in $cursorPaths) {
    if (Test-Path $path) {
        Write-Host "Found Cursor at: $path" -ForegroundColor Green
        Write-Host "Launching Cursor as Administrator..." -ForegroundColor Yellow
        Start-Process $path -Verb RunAs
        $cursorFound = $true
        break
    }
}

if (-not $cursorFound) {
    Write-Host "Cursor not found in standard locations." -ForegroundColor Yellow
    Write-Host "Please provide the path to Cursor.exe:" -ForegroundColor Cyan
    $customPath = Read-Host "Path"
    if (Test-Path $customPath) {
        Start-Process $customPath -Verb RunAs
    } else {
        Write-Host "Invalid path. Exiting." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Cursor should now be running with administrator privileges." -ForegroundColor Green
Write-Host "Copilot features should be available." -ForegroundColor Green



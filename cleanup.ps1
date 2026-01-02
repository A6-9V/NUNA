# Cleanup and Git Status Script
# Verifies commits are pushed and cleans up temporary files

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git Status and Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check git status
Write-Host "Checking git status..." -ForegroundColor Yellow
$status = git status --short
if ($status) {
    Write-Host "Uncommitted changes found:" -ForegroundColor Yellow
    Write-Host $status
    Write-Host ""
    Write-Host "Would you like to commit and push these changes? (y/n)" -ForegroundColor Yellow
    $commit = Read-Host
    if ($commit -eq "y" -or $commit -eq "Y") {
        git add -A
        git commit -m "Update: cleanup and finalize setup"
        git push origin main
        Write-Host "Changes committed and pushed!" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Working directory is clean" -ForegroundColor Green
}

Write-Host ""
Write-Host "Checking remote status..." -ForegroundColor Yellow
$remoteStatus = git status -sb
Write-Host $remoteStatus

Write-Host ""
Write-Host "Recent commits:" -ForegroundColor Yellow
git log --oneline -5

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Operations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Clean up Python cache files
Write-Host "Cleaning Python cache files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include __pycache__,*.pyc,*.pyo -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Write-Host "[OK] Python cache cleaned" -ForegroundColor Green

# Clean up .venv if it exists (optional - commented out to preserve it)
# Write-Host "Note: .venv directory preserved (contains Python packages)" -ForegroundColor Gray

# Check for temporary files
Write-Host ""
Write-Host "Checking for temporary files..." -ForegroundColor Yellow
$tempFiles = Get-ChildItem -Path . -Include *.tmp,*.log,*.bak -Recurse -ErrorAction SilentlyContinue
if ($tempFiles) {
    Write-Host "Found temporary files:" -ForegroundColor Yellow
    $tempFiles | ForEach-Object { Write-Host "  $($_.FullName)" }
    Write-Host ""
    Write-Host "Remove temporary files? (y/n)" -ForegroundColor Yellow
    $remove = Read-Host
    if ($remove -eq "y" -or $remove -eq "Y") {
        $tempFiles | Remove-Item -Force
        Write-Host "[OK] Temporary files removed" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] No temporary files found" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

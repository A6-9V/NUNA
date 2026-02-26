# Commit and Push EXNESS Docker Restructure Changes
# Run this script to commit all restructure changes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EXNESS Docker - Commit Changes" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Initialize git if needed
if (-not (Test-Path ".git")) {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
}

# Check git status
Write-Host "Checking git status..." -ForegroundColor Yellow
git status --short

# Add all files (respecting .gitignore)
Write-Host ""
Write-Host "Adding files to staging..." -ForegroundColor Yellow
git add -A

# Show what will be committed
Write-Host ""
Write-Host "Files to be committed:" -ForegroundColor Yellow
git status --short

# Commit message
$commitMessage = @"
Complete EXNESS Docker Project Restructure

Security & Environment:
- Enhanced env.template with all configuration variables and 23+ symbols
- Removed hardcoded credentials from scripts and documentation
- Updated docker-compose.yml to use environment variables only
- Fixed duplicate entries and missing postgres image

Documentation:
- Created comprehensive MIGRATION-GUIDE.md
- Removed hardcoded credentials from all docs
- Updated README.md with new structure

Scripts:
- Updated setup-env.ps1 to handle env.template
- Removed credentials from START-NOW.bat
- All scripts reference correct paths

Configuration:
- Support for 30+ trading symbols
- Hybrid symbols loading (env var + JSON)
- Environment-based configuration throughout
"@

# Commit
Write-Host ""
Write-Host "Committing changes..." -ForegroundColor Yellow
git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Commit successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To push to remote:" -ForegroundColor Yellow
    Write-Host "  git remote add origin <your-repo-url>" -ForegroundColor White
    Write-Host "  git push -u origin main" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "⚠ Commit failed or no changes to commit" -ForegroundColor Yellow
    Write-Host "  Check git status for details" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan


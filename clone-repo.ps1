# Clone repository using GitHub CLI
# This script uses 'gh' CLI to clone the repository

Write-Host "Cloning repository using GitHub CLI..." -ForegroundColor Cyan
Write-Host ""

# Check if gh CLI is installed
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghInstalled) {
    Write-Host "[WARNING] GitHub CLI (gh) is not installed." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installing GitHub CLI..." -ForegroundColor Yellow
    Write-Host "Please run this command manually:" -ForegroundColor Cyan
    Write-Host "  winget install --id GitHub.cli" -ForegroundColor White
    Write-Host ""
    Write-Host "Or download from: https://cli.github.com/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Alternatively, using git clone..." -ForegroundColor Yellow
    
    # Fallback to git clone
    $clonePath = Read-Host "Enter path to clone repository (or press Enter for current directory)"
    if ([string]::IsNullOrWhiteSpace($clonePath)) {
        $clonePath = $PWD
    }
    
    Write-Host "Cloning with git (HTTPS)..." -ForegroundColor Yellow
    git clone https://github.com/Mouy-leng/Window-setup.git "$clonePath\Window-setup"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Repository cloned successfully!" -ForegroundColor Green
        Write-Host "Location: $clonePath\Window-setup" -ForegroundColor Cyan
    } else {
        Write-Host "[ERROR] Failed to clone repository." -ForegroundColor Red
        Write-Host "Authentication notes:" -ForegroundColor Yellow
        Write-Host "  - GitHub no longer supports account passwords for git over HTTPS." -ForegroundColor White
        Write-Host "  - Recommended: use GitHub CLI OAuth login: gh auth login" -ForegroundColor White
        Write-Host "  - Alternative: use Git Credential Manager or a fine-grained token (PAT) if required." -ForegroundColor White
    }
} else {
    Write-Host "[OK] GitHub CLI found!" -ForegroundColor Green
    Write-Host ""
    
    # Check if authenticated
    Write-Host "Checking GitHub authentication..." -ForegroundColor Yellow
    $authStatus = gh auth status 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Not authenticated with GitHub CLI." -ForegroundColor Yellow
        Write-Host "Please authenticate (OAuth):" -ForegroundColor Cyan
        Write-Host "  gh auth login -h github.com -p https --web" -ForegroundColor White
        Write-Host "  # or: gh auth login -h github.com -p https --device" -ForegroundColor White
        Write-Host ""
        Write-Host "Falling back to git clone..." -ForegroundColor Yellow
        
        $clonePath = Read-Host "Enter path to clone repository (or press Enter for current directory)"
        if ([string]::IsNullOrWhiteSpace($clonePath)) {
            $clonePath = $PWD
        }
        
        git clone https://github.com/Mouy-leng/Window-setup.git "$clonePath\Window-setup"
    } else {
        Write-Host "[OK] Authenticated with GitHub!" -ForegroundColor Green
        Write-Host ""
        
        $clonePath = Read-Host "Enter path to clone repository (or press Enter for current directory)"
        if ([string]::IsNullOrWhiteSpace($clonePath)) {
            $clonePath = $PWD
        }
        
        Write-Host "Cloning repository..." -ForegroundColor Yellow
        gh repo clone Mouy-leng/Window-setup "$clonePath\Window-setup"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Repository cloned successfully!" -ForegroundColor Green
            Write-Host "Location: $clonePath\Window-setup" -ForegroundColor Cyan
        } else {
            Write-Host "[ERROR] Failed to clone repository." -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


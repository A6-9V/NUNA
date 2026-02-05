# ================================================================
# Sync Script: Push to forge.mql5.io (PowerShell)
# ================================================================
# This script synchronizes the local repository with forge.mql5.io
# 
# Usage:
#   .\scripts\sync-forge.ps1 [-Branch <branch>] [-All]
#   
# Examples:
#   .\scripts\sync-forge.ps1                    # Sync current branch
#   .\scripts\sync-forge.ps1 -Branch main       # Sync main branch
#   .\scripts\sync-forge.ps1 -All               # Sync all branches
# ================================================================

param(
    [string]$Branch,
    [switch]$All
)

# Colors
$ColorRed = "Red"
$ColorGreen = "Green"
$ColorYellow = "Yellow"
$ColorBlue = "Cyan"

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorBlue
Write-Host "     NUNA - Forge MQL5 Sync Script" -ForegroundColor $ColorBlue
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorBlue
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Change to project directory
Set-Location $ProjectDir

# Check if forge remote exists
$forgeRemote = git remote | Where-Object { $_ -eq "forge" }
if (-not $forgeRemote) {
    Write-Host "⚠️  Forge remote not found. Adding it now..." -ForegroundColor $ColorYellow
    git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git
    Write-Host "✓ Forge remote added" -ForegroundColor $ColorGreen
}

# Get current branch if no parameter provided
if (-not $Branch) {
    $Branch = git branch --show-current
}

if ($All) {
    Write-Host "Syncing all branches to forge..." -ForegroundColor $ColorBlue
    Write-Host ""
    
    # Push all branches
    Write-Host "→ Pushing all branches..." -ForegroundColor $ColorYellow
    $result = git push forge --all 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All branches pushed successfully" -ForegroundColor $ColorGreen
    } else {
        Write-Host "✗ Failed to push all branches" -ForegroundColor $ColorRed
        Write-Host $result -ForegroundColor $ColorRed
        exit 1
    }
    
    # Push all tags
    Write-Host "→ Pushing all tags..." -ForegroundColor $ColorYellow
    $result = git push forge --tags 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All tags pushed successfully" -ForegroundColor $ColorGreen
    } else {
        Write-Host "✗ Failed to push tags" -ForegroundColor $ColorRed
        Write-Host $result -ForegroundColor $ColorRed
        exit 1
    }
} else {
    Write-Host "Syncing branch: $Branch" -ForegroundColor $ColorBlue
    Write-Host ""
    
    # Fetch latest from forge
    Write-Host "→ Fetching latest from forge..." -ForegroundColor $ColorYellow
    $result = git fetch forge 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Fetched successfully" -ForegroundColor $ColorGreen
    } else {
        Write-Host "✗ Fetch failed" -ForegroundColor $ColorRed
        Write-Host $result -ForegroundColor $ColorRed
        exit 1
    }
    
    # Push to forge
    Write-Host "→ Pushing to forge..." -ForegroundColor $ColorYellow
    $result = git push forge $Branch 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Pushed successfully" -ForegroundColor $ColorGreen
    } else {
        Write-Host "⚠️  Push failed. You may need to force push." -ForegroundColor $ColorYellow
        Write-Host "   Run: git push forge $Branch --force" -ForegroundColor $ColorYellow
        exit 1
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorBlue
Write-Host "✓ Sync completed successfully!" -ForegroundColor $ColorGreen
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorBlue
Write-Host ""
Write-Host "Repository URLs:"
Write-Host "  GitHub:     https://github.com/A6-9V/NUNA" -ForegroundColor $ColorBlue
Write-Host "  Forge MQL5: https://forge.mql5.io/LengKundee/NUNA" -ForegroundColor $ColorBlue
Write-Host ""

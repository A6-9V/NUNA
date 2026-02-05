# ================================================================
# Cleanup Script: Reset forge.mql5.io to Clean State (PowerShell)
# ================================================================
# This script resets the forge.mql5.io repository to a clean state
# by force-pushing the current main branch.
#
# Usage:
#   .\scripts\cleanup-forge.ps1 [-Force]
#
# WARNING: This will overwrite the forge.mql5.io repository history!
# ================================================================

param(
    [switch]$Force
)

# Colors
$ColorRed = "Red"
$ColorGreen = "Green"
$ColorYellow = "Yellow"
$ColorBlue = "Cyan"

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorRed
Write-Host "     NUNA - Forge MQL5 Cleanup Script" -ForegroundColor $ColorRed
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorRed
Write-Host ""
Write-Host "⚠️  WARNING: This will reset forge.mql5.io to a clean state!" -ForegroundColor $ColorYellow
Write-Host "⚠️  All history on forge will be overwritten with the current state." -ForegroundColor $ColorYellow
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Change to project directory
Set-Location $ProjectDir

# Confirm unless -Force flag is provided
if (-not $Force) {
    $response = Read-Host "Are you sure you want to continue? (yes/no)"
    if ($response -notmatch "^[Yy][Ee][Ss]$") {
        Write-Host "Cleanup cancelled." -ForegroundColor $ColorBlue
        exit 0
    }
}

# Check if forge remote exists
$forgeRemote = git remote | Where-Object { $_ -eq "forge" }
if (-not $forgeRemote) {
    Write-Host "⚠️  Forge remote not found. Adding it now..." -ForegroundColor $ColorYellow
    git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git
    Write-Host "✓ Forge remote added" -ForegroundColor $ColorGreen
}

Write-Host ""
Write-Host "Starting cleanup process..." -ForegroundColor $ColorBlue
Write-Host ""

# Step 1: Verify we're on a clean state
Write-Host "→ Step 1: Checking repository state..." -ForegroundColor $ColorYellow
$status = git status --porcelain
if ($status) {
    Write-Host "✗ Repository has uncommitted changes" -ForegroundColor $ColorRed
    Write-Host "  Please commit or stash your changes first." -ForegroundColor $ColorYellow
    exit 1
}
Write-Host "✓ Repository is clean" -ForegroundColor $ColorGreen

# Step 2: Fetch latest from origin
Write-Host "→ Step 2: Fetching latest from GitHub..." -ForegroundColor $ColorYellow
$result = git fetch origin 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Fetched successfully" -ForegroundColor $ColorGreen
} else {
    Write-Host "✗ Failed to fetch from GitHub" -ForegroundColor $ColorRed
    Write-Host $result -ForegroundColor $ColorRed
    exit 1
}

# Step 3: Ensure we're on main branch
Write-Host "→ Step 3: Switching to main branch..." -ForegroundColor $ColorYellow
$result = git checkout main 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ On main branch" -ForegroundColor $ColorGreen
} else {
    Write-Host "✗ Failed to checkout main branch" -ForegroundColor $ColorRed
    Write-Host $result -ForegroundColor $ColorRed
    exit 1
}

# Step 4: Pull latest from origin
Write-Host "→ Step 4: Pulling latest changes..." -ForegroundColor $ColorYellow
$result = git pull origin main 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Updated to latest version" -ForegroundColor $ColorGreen
} else {
    Write-Host "✗ Failed to pull latest changes" -ForegroundColor $ColorRed
    Write-Host $result -ForegroundColor $ColorRed
    exit 1
}

# Step 5: Force push to forge (clean state)
Write-Host "→ Step 5: Force pushing to forge.mql5.io..." -ForegroundColor $ColorYellow
Write-Host "   This will overwrite the forge repository!" -ForegroundColor $ColorRed
$result = git push forge main --force 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Successfully reset forge to clean state" -ForegroundColor $ColorGreen
} else {
    Write-Host "✗ Failed to push to forge" -ForegroundColor $ColorRed
    Write-Host $result -ForegroundColor $ColorRed
    exit 1
}

# Step 6: Push all branches (optional)
Write-Host ""
$response = Read-Host "Do you want to push all other branches as well? (yes/no)"
if ($response -match "^[Yy][Ee][Ss]$") {
    Write-Host "→ Pushing all branches..." -ForegroundColor $ColorYellow
    $result = git push forge --all --force 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All branches pushed" -ForegroundColor $ColorGreen
    } else {
        Write-Host "⚠️  Some branches failed to push" -ForegroundColor $ColorYellow
        Write-Host $result -ForegroundColor $ColorYellow
    }
    
    Write-Host "→ Pushing all tags..." -ForegroundColor $ColorYellow
    $result = git push forge --tags --force 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All tags pushed" -ForegroundColor $ColorGreen
    } else {
        Write-Host "⚠️  Some tags failed to push" -ForegroundColor $ColorYellow
        Write-Host $result -ForegroundColor $ColorYellow
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorBlue
Write-Host "✓ Forge cleanup completed successfully!" -ForegroundColor $ColorGreen
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $ColorBlue
Write-Host ""
Write-Host "The forge.mql5.io repository has been reset to match GitHub."
Write-Host ""
Write-Host "Repository URLs:"
Write-Host "  GitHub:     https://github.com/A6-9V/NUNA" -ForegroundColor $ColorBlue
Write-Host "  Forge MQL5: https://forge.mql5.io/LengKundee/NUNA" -ForegroundColor $ColorBlue
Write-Host ""

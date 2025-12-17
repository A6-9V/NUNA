#Requires -Version 5.1
<#
.SYNOPSIS
    Master Setup: Network Mapping + Code Cleanup
.DESCRIPTION
    Runs network mapping setup and code cleanup in sequence
    Fully automated - no user interaction required
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Network Mapping + Code Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"

# Step 1: Network Mapping
Write-Host "[1/2] Setting up network mappings..." -ForegroundColor Yellow
Write-Host ""

$networkScript = Join-Path $workspaceRoot "setup-network-mapping.ps1"
if (Test-Path $networkScript) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $networkScript
        Write-Host ""
        Write-Host "[OK] Network mapping complete" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Network mapping had issues: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARNING] Network mapping script not found" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Code Cleanup
Write-Host "[2/2] Running code cleanup..." -ForegroundColor Yellow
Write-Host ""

$cleanupScript = Join-Path $workspaceRoot "cleanup-code.ps1"
if (Test-Path $cleanupScript) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $cleanupScript
        Write-Host ""
        Write-Host "[OK] Code cleanup complete" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Code cleanup had issues: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARNING] Cleanup script not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


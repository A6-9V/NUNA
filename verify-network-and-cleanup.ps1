#Requires -Version 5.1
<#
.SYNOPSIS
    Verify Network Mapping and Cleanup Status
.DESCRIPTION
    Verifies network mappings are working and cleanup was successful
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Network & Cleanup Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"

# Check network configuration
Write-Host "[1/4] Checking network configuration..." -ForegroundColor Yellow
$networkConfig = Join-Path $workspaceRoot "network-config.json"
if (Test-Path $networkConfig) {
    Write-Host "    [OK] Network configuration exists" -ForegroundColor Green
    try {
        $config = Get-Content $networkConfig -Raw | ConvertFrom-Json
        Write-Host "    [INFO] Mappings configured: $($config.mappings.Count)" -ForegroundColor Cyan
        Write-Host "    [INFO] UNC paths configured: $($config.unc_paths.Count)" -ForegroundColor Cyan
    } catch {
        Write-Host "    [WARNING] Could not parse network config" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [WARNING] Network configuration not found" -ForegroundColor Yellow
}

# Check mapped drives
Write-Host "[2/4] Checking mapped network drives..." -ForegroundColor Yellow
$mappedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*" }
if ($mappedDrives) {
    Write-Host "    [OK] Found $($mappedDrives.Count) mapped network drive(s):" -ForegroundColor Green
    foreach ($drive in $mappedDrives) {
        Write-Host "      $($drive.Name): $($drive.DisplayRoot)" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] No network drives currently mapped" -ForegroundColor Cyan
}

# Check cleanup results
Write-Host "[3/4] Checking cleanup status..." -ForegroundColor Yellow
$cleanupLog = Get-ChildItem -Path $workspaceRoot -Filter "cleanup-log_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($cleanupLog) {
    Write-Host "    [OK] Latest cleanup log: $($cleanupLog.Name)" -ForegroundColor Green
    $logContent = Get-Content $cleanupLog.FullName -Tail 10
    Write-Host "    Last cleanup actions:" -ForegroundColor Cyan
    $logContent | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
} else {
    Write-Host "    [INFO] No cleanup logs found" -ForegroundColor Cyan
}

# Check documentation organization
Write-Host "[4/4] Checking documentation organization..." -ForegroundColor Yellow
$docsDir = Join-Path $workspaceRoot "Documentation\Reports"
if (Test-Path $docsDir) {
    $docCount = (Get-ChildItem -Path $docsDir -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "    [OK] Documentation folder exists with $docCount file(s)" -ForegroundColor Green
} else {
    Write-Host "    [INFO] Documentation folder not created yet" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


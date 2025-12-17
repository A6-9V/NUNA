#Requires -Version 5.1
<#
.SYNOPSIS
    Quick Network Drive Mapping
.DESCRIPTION
    Maps network drives based on network-config.json
    Can be run standalone or as part of setup
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$networkConfigPath = Join-Path $workspaceRoot "network-config.json"

if (-not (Test-Path $networkConfigPath)) {
    Write-Host "[ERROR] Network configuration not found: $networkConfigPath" -ForegroundColor Red
    Write-Host "Run setup-network-mapping.ps1 first" -ForegroundColor Yellow
    exit 1
}

$config = Get-Content $networkConfigPath -Raw | ConvertFrom-Json

Write-Host "Mapping network drives..." -ForegroundColor Cyan

foreach ($mapping in $config.mappings) {
    $driveLetter = $mapping.drive_letter
    $uncPath = $mapping.unc_path
    $persistent = if ($mapping.persistent -ne $null) { $mapping.persistent } else { $true }
    
    # Check if already mapped
    $existing = Get-PSDrive -Name $driveLetter.TrimEnd(':') -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  [INFO] $driveLetter already mapped" -ForegroundColor Yellow
        continue
    }
    
    # Test connection
    if (-not (Test-Path $uncPath)) {
        Write-Host "  [WARNING] Cannot access $uncPath - check network connection" -ForegroundColor Yellow
        continue
    }
    
    # Map drive
    try {
        New-PSDrive -Name $driveLetter.TrimEnd(':') -PSProvider FileSystem -Root $uncPath -Persist:$persistent | Out-Null
        Write-Host "  [OK] Mapped $driveLetter to $uncPath" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to map $driveLetter: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Network drive mapping complete" -ForegroundColor Green


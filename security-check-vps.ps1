#Requires -Version 5.1
<#
.SYNOPSIS
    VPS Security Check - Comprehensive security verification
.DESCRIPTION
    Checks security settings, credentials, and system integrity
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VPS Security Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$securityIssues = @()
$securityWarnings = @()
$securityOK = @()

# 1. Check Windows Defender
Write-Host "[1/6] Checking Windows Defender..." -ForegroundColor Yellow
try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defenderStatus) {
        if ($defenderStatus.RealTimeProtectionEnabled) {
            $securityOK += "Windows Defender Real-Time Protection: ENABLED"
            Write-Host "    [OK] Windows Defender Real-Time Protection enabled" -ForegroundColor Green
        } else {
            $securityWarnings += "Windows Defender Real-Time Protection: DISABLED"
            Write-Host "    [WARNING] Windows Defender Real-Time Protection disabled" -ForegroundColor Yellow
        }
    } else {
        $securityWarnings += "Windows Defender status: UNKNOWN"
        Write-Host "    [WARNING] Could not check Windows Defender status" -ForegroundColor Yellow
    }
} catch {
    $securityWarnings += "Windows Defender check failed: $_"
    Write-Host "    [WARNING] Windows Defender check failed" -ForegroundColor Yellow
}

# 2. Check Firewall
Write-Host "[2/6] Checking Windows Firewall..." -ForegroundColor Yellow
try {
    $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    foreach ($profile in $firewallProfiles) {
        if ($profile.Enabled) {
            $securityOK += "Firewall Profile $($profile.Name): ENABLED"
            Write-Host "    [OK] Firewall $($profile.Name): ENABLED" -ForegroundColor Green
        } else {
            $securityWarnings += "Firewall Profile $($profile.Name): DISABLED"
            Write-Host "    [WARNING] Firewall $($profile.Name): DISABLED" -ForegroundColor Yellow
        }
    }
} catch {
    $securityWarnings += "Firewall check failed: $_"
    Write-Host "    [WARNING] Firewall check failed" -ForegroundColor Yellow
}

# 3. Check Credential Files
Write-Host "[3/6] Checking credential security..." -ForegroundColor Yellow
$workspaceRoot = "C:\Users\USER\OneDrive"
$credFiles = @(
    "git-credentials.txt",
    ".github-token",
    "*credentials*",
    "*.token",
    "*.secret"
)

$foundCreds = @()
foreach ($pattern in $credFiles) {
    $files = Get-ChildItem -Path $workspaceRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        if ($file.FullName -notlike "*\.git\*") {
            $foundCreds += $file.FullName
        }
    }
}

if ($foundCreds.Count -eq 0) {
    $securityOK += "No credential files found in workspace (good - they should be gitignored)"
    Write-Host "    [OK] No credential files found in workspace" -ForegroundColor Green
} else {
    $securityWarnings += "Found $($foundCreds.Count) potential credential file(s) - ensure they are gitignored"
    Write-Host "    [WARNING] Found $($foundCreds.Count) potential credential file(s)" -ForegroundColor Yellow
    foreach ($cred in $foundCreds) {
        Write-Host "        - $cred" -ForegroundColor Yellow
    }
}

# 4. Check .gitignore
Write-Host "[4/6] Checking .gitignore..." -ForegroundColor Yellow
$gitignorePath = Join-Path $workspaceRoot ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    $requiredExclusions = @("*credentials*", "*.token", "*.secret", "git-credentials.txt")
    $missingExclusions = @()
    
    foreach ($exclusion in $requiredExclusions) {
        if ($gitignoreContent -notmatch [regex]::Escape($exclusion)) {
            $missingExclusions += $exclusion
        }
    }
    
    if ($missingExclusions.Count -eq 0) {
        $securityOK += ".gitignore properly configured"
        Write-Host "    [OK] .gitignore properly configured" -ForegroundColor Green
    } else {
        $securityWarnings += ".gitignore missing exclusions: $($missingExclusions -join ', ')"
        Write-Host "    [WARNING] .gitignore missing some exclusions" -ForegroundColor Yellow
    }
} else {
    $securityIssues += ".gitignore file not found"
    Write-Host "    [ERROR] .gitignore file not found" -ForegroundColor Red
}

# 5. Check Execution Policy
Write-Host "[5/6] Checking PowerShell execution policy..." -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -in @("RemoteSigned", "Unrestricted")) {
    $securityOK += "PowerShell execution policy: $executionPolicy (appropriate for scripts)"
    Write-Host "    [OK] Execution policy: $executionPolicy" -ForegroundColor Green
} else {
    $securityWarnings += "PowerShell execution policy: $executionPolicy (may need adjustment)"
    Write-Host "    [WARNING] Execution policy: $executionPolicy" -ForegroundColor Yellow
}

# 6. Check Admin Privileges
Write-Host "[6/6] Checking administrator privileges..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    $securityOK += "Running with administrator privileges (required for services)"
    Write-Host "    [OK] Running with administrator privileges" -ForegroundColor Green
} else {
    $securityWarnings += "Not running with administrator privileges (services may not start)"
    Write-Host "    [WARNING] Not running with administrator privileges" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Security Check Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($securityOK.Count -gt 0) {
    Write-Host "[OK] Security Items ($($securityOK.Count)):" -ForegroundColor Green
    foreach ($item in $securityOK) {
        Write-Host "  ✓ $item" -ForegroundColor Green
    }
    Write-Host ""
}

if ($securityWarnings.Count -gt 0) {
    Write-Host "[WARNING] Security Warnings ($($securityWarnings.Count)):" -ForegroundColor Yellow
    foreach ($item in $securityWarnings) {
        Write-Host "  ⚠ $item" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($securityIssues.Count -gt 0) {
    Write-Host "[ERROR] Security Issues ($($securityIssues.Count)):" -ForegroundColor Red
    foreach ($item in $securityIssues) {
        Write-Host "  ✗ $item" -ForegroundColor Red
    }
    Write-Host ""
}

$overallStatus = if ($securityIssues.Count -eq 0 -and $securityWarnings.Count -eq 0) { "SECURE" }
elseif ($securityIssues.Count -eq 0) { "MOSTLY SECURE" }
else { "NEEDS ATTENTION" }

$statusColor = if ($overallStatus -eq "SECURE") { "Green" } elseif ($overallStatus -eq "MOSTLY SECURE") { "Yellow" } else { "Red" }
Write-Host "Overall Security Status: $overallStatus" -ForegroundColor $statusColor
Write-Host ""

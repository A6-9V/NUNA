#Requires -Version 5.1
<#
.SYNOPSIS
    Trading System Security Check
.DESCRIPTION
    Validates trading system security: credentials, API keys, configuration files
    Ensures no sensitive data is committed to git
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Security Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$securityIssues = @()
$securityWarnings = @()
$securityPassed = @()

# Check if trading-bridge exists
if (-not (Test-Path $tradingBridgePath)) {
    Write-Host "[INFO] Trading bridge directory not found. Run setup-trading-drive.ps1 first." -ForegroundColor Yellow
    exit 0
}

# ========================================
# 1. Check Configuration Files in .gitignore
# ========================================
Write-Host "[1/6] Checking Configuration Files Security..." -ForegroundColor Yellow

$gitignorePath = Join-Path $workspaceRoot ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw -ErrorAction SilentlyContinue
    
    $requiredExclusions = @(
        "trading-bridge/config/brokers.json",
        "trading-bridge/config/symbols.json",
        "trading-bridge/config/*.key",
        "trading-bridge/logs/*.log"
    )
    
    foreach ($exclusion in $requiredExclusions) {
        if ($gitignoreContent -match [regex]::Escape($exclusion)) {
            Write-Host "    [OK] $exclusion is in .gitignore" -ForegroundColor Green
            $securityPassed += "$exclusion properly excluded"
        } else {
            Write-Host "    [ERROR] $exclusion is NOT in .gitignore!" -ForegroundColor Red
            $securityIssues += "$exclusion is not in .gitignore"
        }
    }
} else {
    Write-Host "    [ERROR] .gitignore not found!" -ForegroundColor Red
    $securityIssues += ".gitignore file not found"
}

Write-Host ""

# ========================================
# 2. Check if Config Files are Tracked in Git
# ========================================
Write-Host "[2/6] Checking Git Tracking Status..." -ForegroundColor Yellow

$sensitiveFiles = @(
    "trading-bridge\config\brokers.json",
    "trading-bridge\config\symbols.json"
)

foreach ($file in $sensitiveFiles) {
    $fullPath = Join-Path $workspaceRoot $file
    if (Test-Path $fullPath) {
        try {
            $gitStatus = git ls-files $file 2>&1
            if ($gitStatus) {
                Write-Host "    [ERROR] $file is tracked in git repository!" -ForegroundColor Red
                $securityIssues += "$file is tracked in git (CRITICAL SECURITY RISK!)"
            } else {
                Write-Host "    [OK] $file is not tracked in git" -ForegroundColor Green
                $securityPassed += "$file not tracked in git"
            }
        } catch {
            Write-Host "    [WARNING] Could not check git tracking for $file" -ForegroundColor Yellow
            $securityWarnings += "Could not verify git tracking for $file"
        }
    } else {
        Write-Host "    [INFO] $file not found (will be created during setup)" -ForegroundColor Cyan
    }
}

Write-Host ""

# ========================================
# 3. Check for Hardcoded Credentials in Code
# ========================================
Write-Host "[3/6] Scanning for Hardcoded Credentials..." -ForegroundColor Yellow

$pythonFiles = Get-ChildItem -Path $tradingBridgePath -Filter "*.py" -Recurse -ErrorAction SilentlyContinue
$suspiciousPatterns = @(
    "api_key\s*=\s*['""][^'""]+['""]",
    "api_secret\s*=\s*['""][^'""]+['""]",
    "password\s*=\s*['""][^'""]+['""]",
    "token\s*=\s*['""][^'""]+['""]"
)

$foundIssues = $false
foreach ($pyFile in $pythonFiles) {
    $content = Get-Content $pyFile.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        foreach ($pattern in $suspiciousPatterns) {
            if ($content -match $pattern) {
                Write-Host "    [ERROR] Potential hardcoded credential in $($pyFile.Name)" -ForegroundColor Red
                $securityIssues += "Hardcoded credential pattern found in $($pyFile.FullName)"
                $foundIssues = $true
            }
        }
    }
}

if (-not $foundIssues) {
    Write-Host "    [OK] No hardcoded credentials found in Python files" -ForegroundColor Green
    $securityPassed += "No hardcoded credentials in code"
}

Write-Host ""

# ========================================
# 4. Check Credential Manager Usage
# ========================================
Write-Host "[4/6] Checking Credential Manager Implementation..." -ForegroundColor Yellow

$credentialManagerPath = Join-Path $tradingBridgePath "python\security\credential_manager.py"
if (Test-Path $credentialManagerPath) {
    Write-Host "    [OK] CredentialManager exists" -ForegroundColor Green
    $securityPassed += "CredentialManager implemented"
    
    # Check if it's being used in broker code
    $brokerFiles = Get-ChildItem -Path (Join-Path $tradingBridgePath "python\brokers") -Filter "*.py" -ErrorAction SilentlyContinue
    $usesCredentialManager = $false
    foreach ($brokerFile in $brokerFiles) {
        $content = Get-Content $brokerFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match "CredentialManager|credential_manager|get_credential")) {
            $usesCredentialManager = $true
            break
        }
    }
    
    if ($usesCredentialManager) {
        Write-Host "    [OK] Broker code uses CredentialManager" -ForegroundColor Green
        $securityPassed += "Broker code uses CredentialManager"
    } else {
        Write-Host "    [WARNING] Broker code may not be using CredentialManager" -ForegroundColor Yellow
        $securityWarnings += "Broker code should use CredentialManager"
    }
} else {
    Write-Host "    [WARNING] CredentialManager not found" -ForegroundColor Yellow
    $securityWarnings += "CredentialManager not implemented"
}

Write-Host ""

# ========================================
# 5. Check Log Files for Sensitive Data
# ========================================
Write-Host "[5/6] Checking Log Files..." -ForegroundColor Yellow

$logsPath = Join-Path $tradingBridgePath "logs"
if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" -ErrorAction SilentlyContinue
    if ($logFiles) {
        $foundSensitive = $false
        foreach ($logFile in $logFiles) {
            $content = Get-Content $logFile.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                # Check for API keys or secrets in logs
                if ($content -match "api[_-]?key\s*[:=]\s*[a-zA-Z0-9]{20,}" -or 
                    $content -match "api[_-]?secret\s*[:=]\s*[a-zA-Z0-9]{20,}") {
                    Write-Host "    [ERROR] Potential credentials found in log: $($logFile.Name)" -ForegroundColor Red
                    $securityIssues += "Credentials may be logged in $($logFile.Name)"
                    $foundSensitive = $true
                }
            }
        }
        
        if (-not $foundSensitive) {
            Write-Host "    [OK] No sensitive data found in log files" -ForegroundColor Green
            $securityPassed += "Log files sanitized"
        }
    } else {
        Write-Host "    [INFO] No log files found yet" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] Logs directory not created yet" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 6. Check Firewall Rules for Trading Ports
# ========================================
Write-Host "[6/6] Checking Firewall Configuration..." -ForegroundColor Yellow

try {
    # Check if common trading bridge ports are open
    $tradingPorts = @(5555, 5556)  # ZeroMQ default ports
    $firewallRules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*trading*" -or $_.DisplayName -like "*bridge*"
    }
    
    if ($firewallRules) {
        Write-Host "    [INFO] Found firewall rules for trading system" -ForegroundColor Cyan
        $securityPassed += "Firewall rules configured"
    } else {
        Write-Host "    [WARNING] No specific firewall rules found for trading system" -ForegroundColor Yellow
        $securityWarnings += "Consider configuring firewall rules for trading ports"
    }
} catch {
    Write-Host "    [WARNING] Could not check firewall rules (may require admin)" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Summary
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Security Check Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($securityPassed.Count -gt 0) {
    Write-Host "Passed Checks: $($securityPassed.Count)" -ForegroundColor Green
    foreach ($check in $securityPassed) {
        Write-Host "  [OK] $check" -ForegroundColor Green
    }
    Write-Host ""
}

if ($securityWarnings.Count -gt 0) {
    Write-Host "Warnings: $($securityWarnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $securityWarnings) {
        Write-Host "  [WARNING] $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($securityIssues.Count -gt 0) {
    Write-Host "Security Issues: $($securityIssues.Count)" -ForegroundColor Red
    foreach ($issue in $securityIssues) {
        Write-Host "  [ERROR] $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "ACTION REQUIRED: Fix security issues before proceeding!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All security checks passed!" -ForegroundColor Green
    Write-Host ""
    exit 0
}


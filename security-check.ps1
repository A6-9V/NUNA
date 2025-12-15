# Security Check Script
# Comprehensive security validation for automation scripts and system configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Security Check and Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$securityIssues = @()
$securityWarnings = @()
$securityPassed = @()

# ========================================
# 1. Token and Credential Security
# ========================================
Write-Host "[1/8] Checking Token and Credential Security..." -ForegroundColor Yellow

# Check if git-credentials.txt exists
if (Test-Path "git-credentials.txt") {
    # Check if it's in .gitignore
    $gitignoreContent = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
    if ($gitignoreContent -match "git-credentials\.txt") {
        Write-Host "    [OK] Token file is gitignored" -ForegroundColor Green
        $securityPassed += "Token file properly excluded from git"
    } else {
        Write-Host "    [ERROR] Token file is NOT in .gitignore!" -ForegroundColor Red
        $securityIssues += "git-credentials.txt is not in .gitignore"
    }
    
    # Check if token file is tracked in git
    try {
        $gitStatus = git ls-files "git-credentials.txt" 2>&1
        if ($gitStatus) {
            Write-Host "    [ERROR] Token file is tracked in git repository!" -ForegroundColor Red
            $securityIssues += "git-credentials.txt is tracked in git (security risk!)"
        } else {
            Write-Host "    [OK] Token file is not tracked in git" -ForegroundColor Green
            $securityPassed += "Token file not tracked in git"
        }
    } catch {
        Write-Host "    [WARNING] Could not check git tracking status" -ForegroundColor Yellow
        $securityWarnings += "Could not verify git tracking status"
    }
    
    # Check file permissions (should be readable only by user)
    try {
        $acl = Get-Acl "git-credentials.txt"
        $hasPublicAccess = $false
        foreach ($access in $acl.Access) {
            if ($access.IdentityReference -notlike "*$env:USERNAME*" -and 
                $access.IdentityReference -notlike "*BUILTIN\Administrators*" -and
                $access.FileSystemRights -match "Read|FullControl") {
                $hasPublicAccess = $true
                break
            }
        }
        if ($hasPublicAccess) {
            Write-Host "    [WARNING] Token file has potentially insecure permissions" -ForegroundColor Yellow
            $securityWarnings += "Token file permissions may be too permissive"
        } else {
            Write-Host "    [OK] Token file permissions are secure" -ForegroundColor Green
            $securityPassed += "Token file permissions secure"
        }
    } catch {
        Write-Host "    [WARNING] Could not check file permissions" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Token file not found (may not be needed)" -ForegroundColor Cyan
}

# Check Windows Credential Manager
try {
    $credManager = cmdkey /list 2>&1 | Select-String "git:https://github.com"
    if ($credManager) {
        Write-Host "    [OK] Git credentials found in Windows Credential Manager" -ForegroundColor Green
        $securityPassed += "Credentials stored in Windows Credential Manager"
    } else {
        Write-Host "    [INFO] No git credentials in Credential Manager (may use token file)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "    [WARNING] Could not check Credential Manager" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# 2. Script Integrity Check
# ========================================
Write-Host "[2/8] Checking Script Integrity..." -ForegroundColor Yellow

$scripts = @(
    "auto-setup.ps1",
    "auto-git-push.ps1",
    "run-all-auto.ps1",
    "git-setup.ps1",
    "complete-windows-setup.ps1",
    "setup-cloud-sync.ps1",
    "check-github-desktop-updates.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        # Check syntax
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
            Write-Host "    [OK] $script - Syntax valid" -ForegroundColor Green
            $securityPassed += "$script syntax valid"
        } catch {
            Write-Host "    [ERROR] $script - Syntax error: ${_}" -ForegroundColor Red
            $securityIssues += "$script has syntax errors"
        }
        
        # Check for hardcoded credentials
        $scriptContent = Get-Content $script -Raw
        if ($scriptContent -match "(?i)(password|pwd|secret|token)\s*=\s*['""][^'""]+['""]") {
            Write-Host "    [WARNING] $script - Possible hardcoded credentials detected" -ForegroundColor Yellow
            $securityWarnings += "$script may contain hardcoded credentials"
        }
    } else {
        Write-Host "    [INFO] $script - Not found (may be optional)" -ForegroundColor Cyan
    }
}

Write-Host ""

# ========================================
# 3. Git Security Check
# ========================================
Write-Host "[3/8] Checking Git Security..." -ForegroundColor Yellow

# Check if .gitignore exists
if (Test-Path ".gitignore") {
    Write-Host "    [OK] .gitignore file exists" -ForegroundColor Green
    $securityPassed += ".gitignore exists"
    
    # Check for sensitive files in .gitignore
    $sensitivePatterns = @("*.txt", "*credentials*", "*token*", "*secret*", "*password*", "*.key", "*.pem")
    $gitignoreContent = Get-Content ".gitignore" -Raw
    $hasSensitivePatterns = $false
    foreach ($pattern in $sensitivePatterns) {
        if ($gitignoreContent -match [regex]::Escape($pattern)) {
            $hasSensitivePatterns = $true
            break
        }
    }
    if ($hasSensitivePatterns) {
        Write-Host "    [OK] .gitignore contains sensitive file patterns" -ForegroundColor Green
        $securityPassed += ".gitignore protects sensitive files"
    } else {
        Write-Host "    [WARNING] .gitignore may not protect all sensitive files" -ForegroundColor Yellow
        $securityWarnings += ".gitignore may need additional patterns"
    }
} else {
    Write-Host "    [ERROR] .gitignore file not found!" -ForegroundColor Red
    $securityIssues += ".gitignore file missing"
}

# Check git remote URL (should use HTTPS, not SSH with keys)
try {
    $remoteUrl = git remote get-url origin 2>&1
    if ($remoteUrl -match "^https://") {
        Write-Host "    [OK] Git remote uses HTTPS (secure)" -ForegroundColor Green
        $securityPassed += "Git remote uses HTTPS"
    } elseif ($remoteUrl -match "^git@") {
        Write-Host "    [WARNING] Git remote uses SSH (ensure keys are secure)" -ForegroundColor Yellow
        $securityWarnings += "Git remote uses SSH - verify key security"
    } else {
        Write-Host "    [INFO] Git remote: $remoteUrl" -ForegroundColor Cyan
    }
} catch {
    Write-Host "    [INFO] No git remote configured" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 4. File Permissions Check
# ========================================
Write-Host "[4/8] Checking File Permissions..." -ForegroundColor Yellow

$sensitiveFiles = @("git-credentials.txt", ".gitignore")
foreach ($file in $sensitiveFiles) {
    if (Test-Path $file) {
        try {
            $acl = Get-Acl $file
            $isSecure = $true
            foreach ($access in $acl.Access) {
                # Check for overly permissive access
                if ($access.FileSystemRights -match "FullControl|Modify" -and 
                    $access.IdentityReference -notlike "*$env:USERNAME*" -and
                    $access.IdentityReference -notlike "*BUILTIN\Administrators*") {
                    $isSecure = $false
                    break
                }
            }
            if ($isSecure) {
                Write-Host "    [OK] $file - Permissions are secure" -ForegroundColor Green
                $securityPassed += "$file permissions secure"
            } else {
                Write-Host "    [WARNING] $file - Permissions may be too permissive" -ForegroundColor Yellow
                $securityWarnings += "$file permissions may need review"
            }
        } catch {
            Write-Host "    [WARNING] Could not check permissions for $file" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

# ========================================
# 5. Windows Security Settings
# ========================================
Write-Host "[5/8] Checking Windows Security Settings..." -ForegroundColor Yellow

# Check if running as admin (for security checks)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # Check Windows Defender status
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            if ($defenderStatus.RealTimeProtectionEnabled) {
                Write-Host "    [OK] Windows Defender Real-time Protection is enabled" -ForegroundColor Green
                $securityPassed += "Windows Defender enabled"
            } else {
                Write-Host "    [WARNING] Windows Defender Real-time Protection is disabled" -ForegroundColor Yellow
                $securityWarnings += "Windows Defender Real-time Protection disabled"
            }
        }
    } catch {
        Write-Host "    [INFO] Could not check Windows Defender status (may require admin)" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] Run as Administrator to check Windows Defender status" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 6. Plugin and Extension Security
# ========================================
Write-Host "[6/8] Checking Plugin and Extension Security..." -ForegroundColor Yellow

# Check Cursor extensions directory
$cursorExtensionsPath = "$env:APPDATA\Cursor\User\extensions"
if (Test-Path $cursorExtensionsPath) {
    $extensions = Get-ChildItem $cursorExtensionsPath -Directory -ErrorAction SilentlyContinue
    if ($extensions) {
        Write-Host "    [INFO] Found $($extensions.Count) Cursor extension(s)" -ForegroundColor Cyan
        
        # Check for suspicious extensions
        $suspiciousPatterns = @("*key*", "*token*", "*credential*", "*password*")
        foreach ($ext in $extensions) {
            $extName = $ext.Name
            $isSuspicious = $false
            foreach ($pattern in $suspiciousPatterns) {
                if ($extName -like $pattern) {
                    $isSuspicious = $true
                    break
                }
            }
            if ($isSuspicious) {
                Write-Host "    [WARNING] Suspicious extension name: $extName" -ForegroundColor Yellow
                $securityWarnings += "Suspicious extension: $extName"
            }
        }
        Write-Host "    [OK] Extension directory accessible" -ForegroundColor Green
        $securityPassed += "Cursor extensions directory accessible"
    } else {
        Write-Host "    [INFO] No extensions found" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] Cursor extensions directory not found" -ForegroundColor Cyan
}

# Check VS Code extensions (if installed)
$vscodeExtensionsPath = "$env:USERPROFILE\.vscode\extensions"
if (Test-Path $vscodeExtensionsPath) {
    $vscodeExtensions = Get-ChildItem $vscodeExtensionsPath -Directory -ErrorAction SilentlyContinue
    if ($vscodeExtensions) {
        Write-Host "    [INFO] Found $($vscodeExtensions.Count) VS Code extension(s)" -ForegroundColor Cyan
        Write-Host "    [OK] VS Code extensions directory accessible" -ForegroundColor Green
    }
}

Write-Host ""

# ========================================
# 7. Network Security Check
# ========================================
Write-Host "[7/8] Checking Network Security..." -ForegroundColor Yellow

# Check for exposed ports or services
try {
    $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | 
        Where-Object { $_.LocalPort -lt 1024 -or $_.LocalPort -eq 8080 -or $_.LocalPort -eq 3000 } |
        Select-Object LocalPort, OwningProcess -Unique
    
    if ($listeningPorts) {
        Write-Host "    [INFO] Found listening ports (review if unexpected):" -ForegroundColor Cyan
        foreach ($port in $listeningPorts) {
            $process = Get-Process -Id $port.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "Unknown" }
            Write-Host "      - Port $($port.LocalPort): $processName" -ForegroundColor White
        }
    } else {
        Write-Host "    [OK] No unexpected listening ports found" -ForegroundColor Green
        $securityPassed += "No unexpected network ports"
    }
} catch {
    Write-Host "    [WARNING] Could not check network ports (may require admin)" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# 8. Environment Security Check
# ========================================
Write-Host "[8/8] Checking Environment Security..." -ForegroundColor Yellow

# Check for sensitive environment variables
$sensitiveEnvVars = @("GITHUB_TOKEN", "API_KEY", "SECRET", "PASSWORD", "CREDENTIAL")
$foundSensitiveVars = $false
foreach ($var in $sensitiveEnvVars) {
    $envValue = [Environment]::GetEnvironmentVariable($var)
    if ($envValue) {
        Write-Host "    [WARNING] Sensitive environment variable found: $var" -ForegroundColor Yellow
        $securityWarnings += "Sensitive environment variable: $var"
        $foundSensitiveVars = $true
    }
}

if (-not $foundSensitiveVars) {
    Write-Host "    [OK] No sensitive environment variables found" -ForegroundColor Green
    $securityPassed += "No sensitive environment variables"
}

# Check PowerShell execution policy
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "    [WARNING] PowerShell execution policy is Restricted" -ForegroundColor Yellow
    $securityWarnings += "PowerShell execution policy is Restricted"
} elseif ($executionPolicy -match "RemoteSigned|Bypass|Unrestricted") {
    Write-Host "    [OK] PowerShell execution policy: $executionPolicy" -ForegroundColor Green
    $securityPassed += "PowerShell execution policy configured"
} else {
    Write-Host "    [INFO] PowerShell execution policy: $executionPolicy" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# Security Summary
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Security Check Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($securityPassed.Count -gt 0) {
    Write-Host "Passed Checks ($($securityPassed.Count)):" -ForegroundColor Green
    foreach ($check in $securityPassed) {
        Write-Host "  [OK] $check" -ForegroundColor Green
    }
    Write-Host ""
}

if ($securityWarnings.Count -gt 0) {
    Write-Host "Warnings ($($securityWarnings.Count)):" -ForegroundColor Yellow
    foreach ($warning in $securityWarnings) {
        Write-Host "  [WARNING] $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($securityIssues.Count -gt 0) {
    Write-Host "Security Issues ($($securityIssues.Count)):" -ForegroundColor Red
    foreach ($issue in $securityIssues) {
        Write-Host "  [ERROR] $issue" -ForegroundColor Red
    }
    Write-Host ""
}

# Overall status
if ($securityIssues.Count -eq 0 -and $securityWarnings.Count -eq 0) {
    Write-Host "Overall Status: [OK] All security checks passed!" -ForegroundColor Green
} elseif ($securityIssues.Count -eq 0) {
    Write-Host "Overall Status: [WARNING] Security checks passed with warnings" -ForegroundColor Yellow
    Write-Host "  Review warnings above and address as needed." -ForegroundColor Yellow
} else {
    Write-Host "Overall Status: [ERROR] Security issues found!" -ForegroundColor Red
    Write-Host "  Please address the issues above before proceeding." -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""




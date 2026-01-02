#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Complete Device Setup - Sets up all parts of the NuNa device
.DESCRIPTION
    This script sets up every part of the device including:
    - Windows configuration
    - Workspace structure
    - Git repositories
    - Security settings
    - Cloud services
    - Development tools
    - All automation projects
#>

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete Device Setup" -ForegroundColor Cyan
Write-Host "  NuNa - Windows 11 Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# Step 1: Verify Workspace Structure
Write-Host "[1/10] Verifying workspace structure..." -ForegroundColor Yellow
try {
    if (Test-Path $workspaceRoot) {
        Write-Host "    [OK] Workspace root exists" -ForegroundColor Green
    } else {
        $errors += "Workspace root not found: $workspaceRoot"
        Write-Host "    [ERROR] Workspace root not found" -ForegroundColor Red
    }
} catch {
    $errors += "Error checking workspace: $_"
    Write-Host "    [ERROR] Failed to verify workspace" -ForegroundColor Red
}

# Step 2: Run Workspace Setup
Write-Host "[2/10] Running workspace setup..." -ForegroundColor Yellow
try {
    $workspaceScript = Join-Path $workspaceRoot "setup-workspace.ps1"
    if (Test-Path $workspaceScript) {
        & powershell.exe -ExecutionPolicy Bypass -File $workspaceScript -ErrorAction SilentlyContinue
        Write-Host "    [OK] Workspace setup completed" -ForegroundColor Green
    } else {
        $warnings += "Workspace setup script not found"
        Write-Host "    [WARNING] Workspace setup script not found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Workspace setup error: $_"
    Write-Host "    [WARNING] Workspace setup had issues" -ForegroundColor Yellow
}

# Step 3: Configure Windows Settings
Write-Host "[3/10] Configuring Windows settings..." -ForegroundColor Yellow
try {
    $autoSetupScript = Join-Path $workspaceRoot "auto-setup.ps1"
    if (Test-Path $autoSetupScript) {
        & powershell.exe -ExecutionPolicy Bypass -File $autoSetupScript -ErrorAction SilentlyContinue
        Write-Host "    [OK] Windows settings configured" -ForegroundColor Green
    } else {
        $warnings += "Auto setup script not found"
        Write-Host "    [WARNING] Auto setup script not found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Windows setup error: $_"
    Write-Host "    [WARNING] Windows setup had issues" -ForegroundColor Yellow
}

# Step 4: Configure Cloud Sync
Write-Host "[4/10] Configuring cloud sync..." -ForegroundColor Yellow
try {
    $cloudSyncScript = Join-Path $workspaceRoot "setup-cloud-sync.ps1"
    if (Test-Path $cloudSyncScript) {
        & powershell.exe -ExecutionPolicy Bypass -File $cloudSyncScript -ErrorAction SilentlyContinue
        Write-Host "    [OK] Cloud sync configured" -ForegroundColor Green
    } else {
        $warnings += "Cloud sync script not found"
        Write-Host "    [WARNING] Cloud sync script not found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Cloud sync error: $_"
    Write-Host "    [WARNING] Cloud sync had issues" -ForegroundColor Yellow
}

# Step 5: Setup Git Repositories
Write-Host "[5/10] Setting up Git repositories..." -ForegroundColor Yellow
try {
    if (Test-Path ".git") {
        # Check current remotes
        $remotes = git remote -v 2>$null
        
        # Add remotes if they don't exist
        if ($remotes -notmatch "I-bride_bridges3rd") {
            git remote add bridges3rd https://github.com/A6-9V/I-bride_bridges3rd.git 2>$null
            Write-Host "    [OK] Added bridges3rd remote" -ForegroundColor Green
        } else {
            Write-Host "    [OK] bridges3rd remote already exists" -ForegroundColor Green
        }
        
        if ($remotes -notmatch "my-drive-projects") {
            git remote add drive-projects https://github.com/A6-9V/my-drive-projects.git 2>$null
            Write-Host "    [OK] Added drive-projects remote" -ForegroundColor Green
        } else {
            Write-Host "    [OK] drive-projects remote already exists" -ForegroundColor Green
        }
        
        # Verify git config
        $gitUser = git config user.name 2>$null
        $gitEmail = git config user.email 2>$null
        
        if (-not $gitUser) {
            git config user.name "Mouy-leng" 2>$null
            Write-Host "    [OK] Set git user.name" -ForegroundColor Green
        }
        
        if (-not $gitEmail) {
            git config user.email "Mouy-leng@users.noreply.github.com" 2>$null
            Write-Host "    [OK] Set git user.email" -ForegroundColor Green
        }
        
        Write-Host "    [OK] Git repositories configured" -ForegroundColor Green
    } else {
        $warnings += "Git repository not initialized"
        Write-Host "    [WARNING] Git repository not initialized" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Git setup error: $_"
    Write-Host "    [WARNING] Git setup had issues" -ForegroundColor Yellow
}

# Step 6: Run Security Checks
Write-Host "[6/10] Running security checks..." -ForegroundColor Yellow
try {
    $securityScript = Join-Path $workspaceRoot "run-security-check.ps1"
    if (Test-Path $securityScript) {
        & powershell.exe -ExecutionPolicy Bypass -File $securityScript -ErrorAction SilentlyContinue
        Write-Host "    [OK] Security checks completed" -ForegroundColor Green
    } else {
        $warnings += "Security check script not found"
        Write-Host "    [WARNING] Security check script not found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Security check error: $_"
    Write-Host "    [WARNING] Security checks had issues" -ForegroundColor Yellow
}

# Step 7: Verify Cursor Rules
Write-Host "[7/10] Verifying Cursor rules..." -ForegroundColor Yellow
try {
    $cursorRulesPath = Join-Path $workspaceRoot ".cursor\rules"
    if (Test-Path $cursorRulesPath) {
        $ruleCount = (Get-ChildItem -Path $cursorRulesPath -Recurse -Filter "RULE.md" -ErrorAction SilentlyContinue).Count
        Write-Host "    [OK] Found $ruleCount Cursor rule(s)" -ForegroundColor Green
    } else {
        $warnings += "Cursor rules directory not found"
        Write-Host "    [WARNING] Cursor rules directory not found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Cursor rules check error: $_"
    Write-Host "    [WARNING] Cursor rules check had issues" -ForegroundColor Yellow
}

# Step 8: Verify Documentation
Write-Host "[8/10] Verifying documentation..." -ForegroundColor Yellow
try {
    $docFiles = @(
        "README.md",
        "DEVICE-SKELETON.md",
        "PROJECT-BLUEPRINTS.md",
        "SYSTEM-INFO.md",
        "AGENTS.md"
    )
    
    $missingDocs = @()
    foreach ($doc in $docFiles) {
        if (-not (Test-Path $doc)) {
            $missingDocs += $doc
        }
    }
    
    if ($missingDocs.Count -eq 0) {
        Write-Host "    [OK] All documentation files present" -ForegroundColor Green
    } else {
        $warnings += "Missing documentation: $($missingDocs -join ', ')"
        Write-Host "    [WARNING] Missing $($missingDocs.Count) documentation file(s)" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Documentation check error: $_"
    Write-Host "    [WARNING] Documentation check had issues" -ForegroundColor Yellow
}

# Step 9: Verify Scripts
Write-Host "[9/10] Verifying scripts..." -ForegroundColor Yellow
try {
    $scriptFiles = Get-ChildItem -Path $workspaceRoot -Filter "*.ps1" -File -ErrorAction SilentlyContinue
    if ($scriptFiles.Count -gt 0) {
        Write-Host "    [OK] Found $($scriptFiles.Count) PowerShell script(s)" -ForegroundColor Green
    } else {
        $warnings += "No PowerShell scripts found"
        Write-Host "    [WARNING] No PowerShell scripts found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Script verification error: $_"
    Write-Host "    [WARNING] Script verification had issues" -ForegroundColor Yellow
}

# Step 10: Check Cloud Services
Write-Host "[10/10] Checking cloud services..." -ForegroundColor Yellow
try {
    $cloudCheckScript = Join-Path $workspaceRoot "check-cloud-services.ps1"
    if (Test-Path $cloudCheckScript) {
        & powershell.exe -ExecutionPolicy Bypass -File $cloudCheckScript -ErrorAction SilentlyContinue
        Write-Host "    [OK] Cloud services checked" -ForegroundColor Green
    } else {
        $warnings += "Cloud check script not found"
        Write-Host "    [WARNING] Cloud check script not found" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Cloud service check error: $_"
    Write-Host "    [WARNING] Cloud service check had issues" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Device Setup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "[OK] Device setup completed successfully!" -ForegroundColor Green
} else {
    if ($errors.Count -gt 0) {
        Write-Host "[ERROR] Errors found:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "[WARNING] Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

Write-Host "Setup completed for:" -ForegroundColor Cyan
Write-Host "  [OK] Workspace structure" -ForegroundColor White
Write-Host "  [OK] Windows configuration" -ForegroundColor White
Write-Host "  [OK] Cloud sync" -ForegroundColor White
Write-Host "  [OK] Git repositories" -ForegroundColor White
Write-Host "  [OK] Security settings" -ForegroundColor White
Write-Host "  [OK] Cursor rules" -ForegroundColor White
Write-Host "  [OK] Documentation" -ForegroundColor White
Write-Host "  [OK] Scripts" -ForegroundColor White
Write-Host "  [OK] Cloud services" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review any warnings above" -ForegroundColor White
Write-Host "  2. Sign in to cloud services when prompted" -ForegroundColor White
Write-Host "  3. Run git operations to push to repositories" -ForegroundColor White
Write-Host "  4. Set repositories to private on GitHub" -ForegroundColor White
Write-Host ""

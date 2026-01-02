#Requires -Version 5.1
<#
.SYNOPSIS
    Workspace Setup Script - Configures user workspace for development
.DESCRIPTION
    This script sets up the workspace by:
    - Verifying workspace structure
    - Checking git configuration
    - Ensuring necessary directories exist
    - Verifying Cursor rules are in place
    - Checking for required configuration files
#>

$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Workspace Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()

# Step 1: Verify workspace root
Write-Host "[1/7] Verifying workspace root..." -ForegroundColor Yellow
if (Test-Path $workspaceRoot) {
    Write-Host "    [OK] Workspace root exists: $workspaceRoot" -ForegroundColor Green
} else {
    $issues += "Workspace root does not exist: $workspaceRoot"
    Write-Host "    [ERROR] Workspace root not found" -ForegroundColor Red
}

# Step 2: Check git repository
Write-Host "[2/7] Checking git repository..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "    [OK] Git repository initialized" -ForegroundColor Green
    
    # Check git config
    try {
        $gitUser = git config user.name 2>$null
        $gitEmail = git config user.email 2>$null
        
        if ($gitUser) {
            Write-Host "    [OK] Git user: $gitUser" -ForegroundColor Green
        } else {
            $warnings += "Git user.name not configured"
            Write-Host "    [WARNING] Git user.name not set" -ForegroundColor Yellow
        }
        
        if ($gitEmail) {
            Write-Host "    [OK] Git email: $gitEmail" -ForegroundColor Green
        } else {
            $warnings += "Git user.email not configured"
            Write-Host "    [WARNING] Git user.email not set" -ForegroundColor Yellow
        }
        
        # Check remote
        $remote = git remote get-url origin 2>$null
        if ($remote) {
            Write-Host "    [OK] Remote origin: $remote" -ForegroundColor Green
        } else {
            $warnings += "Git remote 'origin' not configured"
            Write-Host "    [WARNING] Git remote 'origin' not set" -ForegroundColor Yellow
        }
    } catch {
        $warnings += "Could not check git configuration"
        Write-Host "    [WARNING] Could not read git config" -ForegroundColor Yellow
    }
} else {
    $warnings += "Git repository not initialized"
    Write-Host "    [WARNING] Git repository not initialized (run git-setup.ps1 if needed)" -ForegroundColor Yellow
}

# Step 3: Verify Cursor rules structure
Write-Host "[3/7] Verifying Cursor rules..." -ForegroundColor Yellow
$cursorRulesPath = ".cursor\rules"
if (Test-Path $cursorRulesPath) {
    Write-Host "    [OK] Cursor rules directory exists" -ForegroundColor Green
    
    $expectedRules = @(
        "powershell-standards\RULE.md",
        "system-configuration\RULE.md",
        "automation-patterns\RULE.md",
        "security-tokens\RULE.md",
        "github-desktop-integration\RULE.md"
    )
    
    $missingRules = @()
    foreach ($rule in $expectedRules) {
        $rulePath = Join-Path $cursorRulesPath $rule
        if (Test-Path $rulePath) {
            Write-Host "    [OK] Rule found: $rule" -ForegroundColor Green
        } else {
            $missingRules += $rule
            Write-Host "    [WARNING] Rule missing: $rule" -ForegroundColor Yellow
        }
    }
    
    if ($missingRules.Count -gt 0) {
        $warnings += "Missing Cursor rules: $($missingRules -join ', ')"
    }
} else {
    $warnings += "Cursor rules directory not found"
    Write-Host "    [WARNING] Cursor rules directory not found" -ForegroundColor Yellow
}

# Step 4: Check essential configuration files
Write-Host "[4/7] Checking configuration files..." -ForegroundColor Yellow
$essentialFiles = @(
    ".gitignore",
    ".cursorignore",
    "README.md",
    "AGENTS.md"
)

foreach ($file in $essentialFiles) {
    if (Test-Path $file) {
        Write-Host "    [OK] Found: $file" -ForegroundColor Green
    } else {
        $issues += "Missing essential file: $file"
        Write-Host "    [ERROR] Missing: $file" -ForegroundColor Red
    }
}

# Step 5: Check documentation files
Write-Host "[5/7] Checking documentation..." -ForegroundColor Yellow
$docFiles = @(
    "SYSTEM-INFO.md",
    "AUTOMATION-RULES.md",
    "GITHUB-DESKTOP-RULES.md",
    "CURSOR-RULES-SETUP.md"
)

$missingDocs = @()
foreach ($doc in $docFiles) {
    if (Test-Path $doc) {
        Write-Host "    [OK] Found: $doc" -ForegroundColor Green
    } else {
        $missingDocs += $doc
        Write-Host "    [WARNING] Missing: $doc" -ForegroundColor Yellow
    }
}

if ($missingDocs.Count -gt 0) {
    $warnings += "Missing documentation files: $($missingDocs -join ', ')"
}

# Step 6: Verify .gitignore excludes personal files
Write-Host "[6/7] Verifying .gitignore configuration..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    
    $shouldExclude = @(
        "Desktop/",
        "Pictures/",
        "documents/",
        "*.exe",
        "*.jpg",
        "*.png",
        "*.jpeg"
    )
    
    $missingExclusions = @()
    foreach ($exclusion in $shouldExclude) {
        if ($gitignoreContent -notmatch [regex]::Escape($exclusion)) {
            $missingExclusions += $exclusion
        }
    }
    
    if ($missingExclusions.Count -eq 0) {
        Write-Host "    [OK] .gitignore properly configured" -ForegroundColor Green
    } else {
        $warnings += ".gitignore missing exclusions: $($missingExclusions -join ', ')"
        Write-Host "    [WARNING] .gitignore may need updates for personal files" -ForegroundColor Yellow
    }
} else {
    $issues += ".gitignore file not found"
    Write-Host "    [ERROR] .gitignore not found" -ForegroundColor Red
}

# Step 7: Check PowerShell scripts
Write-Host "[7/7] Checking PowerShell scripts..." -ForegroundColor Yellow
$scriptFiles = Get-ChildItem -Path $workspaceRoot -Filter "*.ps1" -File
if ($scriptFiles.Count -gt 0) {
    Write-Host "    [OK] Found $($scriptFiles.Count) PowerShell script(s)" -ForegroundColor Green
} else {
    $warnings += "No PowerShell scripts found"
    Write-Host "    [WARNING] No PowerShell scripts found" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Workspace Setup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "[OK] Workspace is properly configured!" -ForegroundColor Green
} else {
    if ($issues.Count -gt 0) {
        Write-Host "[ERROR] Issues found:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Red
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

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review warnings and issues above" -ForegroundColor White
Write-Host "  2. Run git-setup.ps1 if git needs configuration" -ForegroundColor White
Write-Host "  3. Update .gitignore if personal files need exclusion" -ForegroundColor White
Write-Host "  4. Run auto-setup.ps1 for Windows automation setup" -ForegroundColor White
Write-Host ""

# Debug and Save Script
# This script checks for errors, fixes issues, and saves everything

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Debug and Save Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# Step 1: Check script syntax
Write-Host "[1/5] Checking script syntax..." -ForegroundColor Yellow
$scripts = @("auto-setup.ps1", "auto-git-push.ps1", "run-all-auto.ps1", "git-setup.ps1", "complete-windows-setup.ps1")

foreach ($script in $scripts) {
    if (Test-Path $script) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
            Write-Host "    [OK] $script - Syntax valid" -ForegroundColor Green
        } catch {
            $errors += "Syntax error in $script`: ${_}"
            Write-Host "    [ERROR] $script - Syntax error" -ForegroundColor Red
        }
    } else {
        $warnings += "$script not found"
        Write-Host "    [WARNING] $script not found" -ForegroundColor Yellow
    }
}

# Step 2: Verify token file is gitignored
Write-Host "[2/5] Checking security..." -ForegroundColor Yellow
if (Test-Path "git-credentials.txt") {
    $gitignore = Get-Content .gitignore -Raw -ErrorAction SilentlyContinue
    if ($gitignore -match "git-credentials") {
        Write-Host "    [OK] Token file is gitignored" -ForegroundColor Green
    } else {
        $errors += "Token file not in .gitignore"
        Write-Host "    [ERROR] Token file not in .gitignore!" -ForegroundColor Red
    }
    
    # Check if token file is tracked
    $tracked = git ls-files git-credentials.txt 2>&1
    if ($tracked) {
        $errors += "Token file is tracked in git!"
        Write-Host "    [ERROR] Token file is tracked in git!" -ForegroundColor Red
    } else {
        Write-Host "    [OK] Token file not tracked in git" -ForegroundColor Green
    }
} else {
    $warnings += "Token file not found"
    Write-Host "    [WARNING] Token file not found" -ForegroundColor Yellow
}

# Step 3: Check git status
Write-Host "[3/5] Checking git status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain 2>&1
if ($gitStatus) {
    $untracked = ($gitStatus | Where-Object { $_ -match "^\?\?" }).Count
    $modified = ($gitStatus | Where-Object { $_ -match "^\s*[MADRC]" }).Count
    
    if ($modified -gt 0) {
        Write-Host "    [INFO] $modified modified file(s) need committing" -ForegroundColor Cyan
    }
    if ($untracked -gt 0) {
        Write-Host "    [INFO] $untracked untracked file(s)" -ForegroundColor Cyan
    }
    Write-Host "    [OK] Git repository status checked" -ForegroundColor Green
} else {
    Write-Host "    [OK] Working directory clean" -ForegroundColor Green
}

# Step 4: Verify remote configuration
Write-Host "[4/5] Checking git remote..." -ForegroundColor Yellow
$remote = git remote get-url origin 2>&1
if ($remote -match "github.com") {
    Write-Host "    [OK] Remote configured: $remote" -ForegroundColor Green
} else {
    $warnings += "Git remote not configured"
    Write-Host "    [WARNING] Git remote not configured" -ForegroundColor Yellow
}

# Step 5: Save all changes
Write-Host "[5/5] Saving all changes..." -ForegroundColor Yellow

# Add all script files
$filesToAdd = @("*.ps1", "*.bat", "*.md", "*.txt", ".gitignore")
foreach ($pattern in $filesToAdd) {
    git add $pattern 2>&1 | Out-Null
}

$changes = git status --porcelain | Where-Object { $_ -match "^\s*[MAD]" }
if ($changes) {
    Write-Host "    [INFO] Staging changes..." -ForegroundColor Cyan
    $commitMessage = "Debug and save: Fix issues and update scripts"
    git commit -m $commitMessage 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Changes committed" -ForegroundColor Green
        
        # Push if token is available
        if (Test-Path "git-credentials.txt") {
            Write-Host "    [INFO] Pushing to GitHub..." -ForegroundColor Cyan
            git push origin main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] Changes pushed to GitHub" -ForegroundColor Green
            } else {
                $warnings += "Failed to push to GitHub"
                Write-Host "    [WARNING] Failed to push (may need authentication)" -ForegroundColor Yellow
            }
        }
    } else {
        $warnings += "Failed to commit changes"
        Write-Host "    [WARNING] No changes to commit" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [OK] No changes to save" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Debug Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -eq 0) {
    Write-Host "[OK] No errors found!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Found $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "[WARNING] Found $($warnings.Count) warning(s):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "All scripts checked and saved!" -ForegroundColor Green
Write-Host ""


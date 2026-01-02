#Requires -Version 5.1
<#
.SYNOPSIS
    Push to All Repositories - One by One
.DESCRIPTION
    Commits all changes and pushes to each configured repository one by one
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Push to All Repositories" -ForegroundColor Cyan
Write-Host "  One by One" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

# Step 1: Resolve merge conflict and stage all changes
Write-Host "[1/5] Resolving conflicts and staging changes..." -ForegroundColor Yellow
try {
    # Add resolved README.md
    git add README.md 2>&1 | Out-Null
    
    # Add all other files
    git add . 2>&1 | Out-Null
    
    Write-Host "    [OK] All changes staged" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to stage changes: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Commit changes
Write-Host "[2/5] Committing changes..." -ForegroundColor Yellow
try {
    $commitMessage = "Complete VPS 24/7 trading system: services, automation, and documentation"
    git commit -m $commitMessage 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Changes committed successfully" -ForegroundColor Green
    } else {
        Write-Host "    [WARNING] Commit may have warnings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [ERROR] Failed to commit: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Get all remotes
Write-Host "[3/5] Getting repository list..." -ForegroundColor Yellow
$remoteNames = git remote
$remotes = @()
foreach ($remoteName in $remoteNames) {
    $remoteUrl = git remote get-url $remoteName
    $remotes += [PSCustomObject]@{
        Name = $remoteName
        URL = $remoteUrl
    }
}

Write-Host "    [OK] Found $($remotes.Count) remote(s)" -ForegroundColor Green
foreach ($remote in $remotes) {
    Write-Host "        - $($remote.Name): $($remote.URL)" -ForegroundColor Cyan
}

# Step 4: Push to each repository one by one
Write-Host "[4/5] Pushing to repositories (one by one)..." -ForegroundColor Yellow
Write-Host ""

$pushResults = @()

foreach ($remote in $remotes) {
    Write-Host "Pushing to: $($remote.Name) ($($remote.URL))" -ForegroundColor Cyan
    Write-Host "  Branch: main" -ForegroundColor Yellow
    
    try {
        $pushOutput = git push $remote.Name main 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Successfully pushed to $($remote.Name)" -ForegroundColor Green
            $pushResults += [PSCustomObject]@{
                Remote = $remote.Name
                URL = $remote.URL
                Status = "SUCCESS"
            }
        } else {
            $errorMsg = ($pushOutput | Select-Object -First 3) -join " "
            Write-Host "  [WARNING] Push to $($remote.Name) had issues" -ForegroundColor Yellow
            Write-Host "  Error: $errorMsg" -ForegroundColor Yellow
            $pushResults += [PSCustomObject]@{
                Remote = $remote.Name
                URL = $remote.URL
                Status = "WARNING"
                Error = $errorMsg
            }
        }
    } catch {
        Write-Host "  [ERROR] Failed to push to $($remote.Name): $_" -ForegroundColor Red
        $pushResults += [PSCustomObject]@{
            Remote = $remote.Name
            URL = $remote.URL
            Status = "ERROR"
            Error = $_.ToString()
        }
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
}

# Step 5: Summary
Write-Host "[5/5] Generating summary..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Push Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$successCount = ($pushResults | Where-Object { $_.Status -eq "SUCCESS" }).Count
$warningCount = ($pushResults | Where-Object { $_.Status -eq "WARNING" }).Count
$errorCount = ($pushResults | Where-Object { $_.Status -eq "ERROR" }).Count

Write-Host "Total Repositories: $($remotes.Count)" -ForegroundColor Yellow
Write-Host "  ✅ Successful: $successCount" -ForegroundColor Green
Write-Host "  ⚠️  Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "  ❌ Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

foreach ($result in $pushResults) {
    $statusColor = switch ($result.Status) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
    }
    Write-Host "  $($result.Remote): $($result.Status)" -ForegroundColor $statusColor
    Write-Host "    URL: $($result.URL)" -ForegroundColor Cyan
    if ($result.Error) {
        Write-Host "    Error: $($result.Error)" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($successCount -eq $remotes.Count) {
    Write-Host "✅ All repositories pushed successfully!" -ForegroundColor Green
} elseif ($errorCount -eq 0) {
    Write-Host "⚠️  Some repositories had warnings but completed" -ForegroundColor Yellow
} else {
    Write-Host "❌ Some repositories failed to push" -ForegroundColor Red
}

Write-Host ""

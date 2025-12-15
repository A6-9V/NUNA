#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive GitHub Repository Review and Push Script
.DESCRIPTION
    Reviews all GitHub repositories, sets up USB support, commits changes, and pushes to all remotes
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Repository Review & Push" -ForegroundColor Cyan
Write-Host "  Complete Workflow" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
Set-Location $workspaceRoot

# ============================================
# STEP 1: Review All Repositories
# ============================================
Write-Host "[STEP 1/6] Reviewing All GitHub Repositories..." -ForegroundColor Yellow
Write-Host ""

# Get all remotes
$remotes = @()
$remoteNames = git remote 2>&1
foreach ($remoteName in $remoteNames) {
    if ($remoteName) {
        $remoteUrl = git remote get-url $remoteName 2>&1
        $remotes += [PSCustomObject]@{
            Name = $remoteName
            URL = $remoteUrl
        }
    }
}

Write-Host "Found $($remotes.Count) remote repository(ies):" -ForegroundColor Cyan
foreach ($remote in $remotes) {
    Write-Host "  - $($remote.Name): $($remote.URL)" -ForegroundColor Green
}
Write-Host ""

# Check current branch
$currentBranch = git branch --show-current 2>&1
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Check git status
Write-Host "Repository Status:" -ForegroundColor Yellow
$status = git status --short 2>&1
if ($status) {
    $modifiedCount = ($status | Where-Object { $_ -match "^ M" }).Count
    $untrackedCount = ($status | Where-Object { $_ -match "^\?\?" }).Count
    Write-Host "  Modified files: $modifiedCount" -ForegroundColor Yellow
    Write-Host "  Untracked files: $untrackedCount" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Working directory clean" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 2: Setup USB Flash Drive Support
# ============================================
Write-Host "[STEP 2/6] Setting Up USB Flash Drive Support..." -ForegroundColor Yellow
Write-Host ""

# Import USB support functions
$usbSupportScript = Join-Path $workspaceRoot "vps-services\usb-support.ps1"
if (Test-Path $usbSupportScript) {
    try {
        . $usbSupportScript
        Write-Host "  [OK] USB support functions loaded" -ForegroundColor Green
        
        # Detect USB drives
        $usbDrives = Get-USBDrives
        if ($usbDrives.Count -gt 0) {
            Write-Host "  Found $($usbDrives.Count) USB drive(s):" -ForegroundColor Cyan
            foreach ($drive in $usbDrives) {
                Write-Host "    - $($drive.DriveLetter) ($($drive.VolumeLabel))" -ForegroundColor Green
                Write-Host "      Free: $($drive.FreeSpace) GB ($($drive.FreePercent)%)" -ForegroundColor Gray
            }
            
            # Get preferred USB drive
            $preferredUSB = Get-PreferredUSBDrive -PreferredLabel "MQL5_SUPPORT" -MinFreeSpaceGB 5
            if ($preferredUSB) {
                Write-Host "  [OK] Preferred USB drive: $($preferredUSB.DriveLetter)" -ForegroundColor Green
                
                # Initialize USB for MQL5 support
                $initResult = Initialize-USBForMQL5 -USBDrivePath $preferredUSB.Path
                if ($initResult) {
                    Write-Host "  [OK] USB drive initialized for MQL5 support" -ForegroundColor Green
                } else {
                    Write-Host "  [WARNING] USB initialization had issues" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [WARNING] No suitable USB drive found (need 5GB+ free space)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [WARNING] No USB drives detected" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARNING] Could not load USB support: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARNING] USB support script not found: $usbSupportScript" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# STEP 3: Stage All Changes
# ============================================
Write-Host "[STEP 3/6] Staging All Changes..." -ForegroundColor Yellow

try {
    # Add all modified and untracked files
    git add . 2>&1 | Out-Null
    
    # Check what was staged
    $stagedFiles = git diff --cached --name-only 2>&1
    if ($stagedFiles) {
        $stagedCount = ($stagedFiles | Measure-Object).Count
        Write-Host "  [OK] Staged $stagedCount file(s)" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] No files to stage" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Failed to stage changes: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ============================================
# STEP 4: Commit Changes
# ============================================
Write-Host "[STEP 4/6] Committing Changes..." -ForegroundColor Yellow

try {
    # Check if there are changes to commit
    $statusCheck = git status --porcelain 2>&1
    if ($statusCheck) {
        $commitMessage = "Update: Repository review, USB support setup, and system improvements - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        git commit -m $commitMessage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Changes committed successfully" -ForegroundColor Green
            Write-Host "  Commit message: $commitMessage" -ForegroundColor Gray
        } else {
            Write-Host "  [WARNING] Commit may have warnings" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] No changes to commit" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Failed to commit: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ============================================
# STEP 5: Push to All Repositories
# ============================================
Write-Host "[STEP 5/6] Pushing to All Repositories..." -ForegroundColor Yellow
Write-Host ""

$pushResults = @()
$successCount = 0
$warningCount = 0
$errorCount = 0

foreach ($remote in $remotes) {
    Write-Host "Pushing to: $($remote.Name)" -ForegroundColor Cyan
    Write-Host "  URL: $($remote.URL)" -ForegroundColor Gray
    Write-Host "  Branch: $currentBranch" -ForegroundColor Gray
    
    try {
        # First, try to pull and merge if needed
        $pullOutput = git pull $remote.Name $currentBranch --no-edit 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $pullOutput -match "rejected|conflict") {
            Write-Host "  [INFO] Remote has changes, attempting to merge..." -ForegroundColor Yellow
            # Try to pull with rebase
            git pull $remote.Name $currentBranch --rebase --no-edit 2>&1 | Out-Null
        }
        
        # Now push
        $pushOutput = git push $remote.Name $currentBranch 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Successfully pushed to $($remote.Name)" -ForegroundColor Green
            $pushResults += [PSCustomObject]@{
                Remote = $remote.Name
                URL = $remote.URL
                Status = "SUCCESS"
                Message = "Push completed successfully"
            }
            $successCount++
        } else {
            $errorMsg = ($pushOutput -split "`n" | Select-Object -First 3) -join " "
            Write-Host "  [WARNING] Push to $($remote.Name) had issues" -ForegroundColor Yellow
            Write-Host "  Error: $errorMsg" -ForegroundColor Yellow
            $pushResults += [PSCustomObject]@{
                Remote = $remote.Name
                URL = $remote.URL
                Status = "WARNING"
                Message = $errorMsg
            }
            $warningCount++
        }
    } catch {
        Write-Host "  [ERROR] Failed to push to $($remote.Name): $_" -ForegroundColor Red
        $pushResults += [PSCustomObject]@{
            Remote = $remote.Name
            URL = $remote.URL
            Status = "ERROR"
            Message = $_.ToString()
        }
        $errorCount++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
}

# ============================================
# STEP 6: Generate Review Report
# ============================================
Write-Host "[STEP 6/6] Generating Review Report..." -ForegroundColor Yellow
Write-Host ""

$reportPath = Join-Path $workspaceRoot "REPOSITORY-REVIEW-REPORT.md"
$reportContent = @"
# GitHub Repository Review & Push Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Repository Overview

### Configured Remotes
"@

foreach ($remote in $remotes) {
    $reportContent += "`n- **$($remote.Name)**: $($remote.URL)"
}

$reportContent += @"

### Current Branch
- **Branch**: $currentBranch

## USB Flash Drive Support

"@

if ($usbDrives -and $usbDrives.Count -gt 0) {
    $reportContent += "### Detected USB Drives`n`n"
    foreach ($drive in $usbDrives) {
        $reportContent += "- **$($drive.DriveLetter)** ($($drive.VolumeLabel))`n"
        $reportContent += "  - Free Space: $($drive.FreeSpace) GB ($($drive.FreePercent)%)`n"
        $reportContent += "  - Total Size: $($drive.TotalSize) GB`n"
    }
    if ($preferredUSB) {
        $reportContent += "`n### Preferred USB Drive`n"
        $reportContent += "- **Drive**: $($preferredUSB.DriveLetter)`n"
        $reportContent += "- **Status**: Initialized for MQL5 support`n"
    }
} else {
    $reportContent += "### USB Drive Status`n"
    $reportContent += "- **Status**: No USB drives detected`n"
}

$reportContent += @"

## Push Results Summary

- **Total Repositories**: $($remotes.Count)
- **✅ Successful**: $successCount
- **⚠️  Warnings**: $warningCount
- **❌ Errors**: $errorCount

### Detailed Results

"@

foreach ($result in $pushResults) {
    $statusIcon = switch ($result.Status) {
        "SUCCESS" { "✅" }
        "WARNING" { "⚠️" }
        "ERROR" { "❌" }
    }
    $reportContent += "#### $statusIcon $($result.Remote)`n"
    $reportContent += "- **URL**: $($result.URL)`n"
    $reportContent += "- **Status**: $($result.Status)`n"
    if ($result.Message) {
        $reportContent += "- **Message**: $($result.Message)`n"
    }
    $reportContent += "`n"
}

$reportContent += @"

## Next Steps

1. Review push results above
2. Check GitHub repositories for updated commits
3. Verify USB drive is properly configured for MQL5 support
4. Monitor repository sync status

---
*Report generated by review-and-push-all-repos.ps1*
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "  [OK] Review report saved to: $reportPath" -ForegroundColor Green
Write-Host ""

# ============================================
# Final Summary
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Review & Push Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Repositories Reviewed: $($remotes.Count)" -ForegroundColor Cyan
Write-Host "  ✅ Successful Pushes: $successCount" -ForegroundColor Green
Write-Host "  ⚠️  Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "  ❌ Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($successCount -eq $remotes.Count) {
    Write-Host "✅ All repositories pushed successfully!" -ForegroundColor Green
} elseif ($errorCount -eq 0) {
    Write-Host "⚠️  Some repositories had warnings but completed" -ForegroundColor Yellow
} else {
    Write-Host "❌ Some repositories failed to push" -ForegroundColor Red
}

Write-Host ""
Write-Host "Review report: $reportPath" -ForegroundColor Cyan
Write-Host ""


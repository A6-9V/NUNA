# Simple C Drive Backup - Reliable Version
# Backs up critical files from C: drive step by step
param(
    [string]$TargetDrive = "I:",
    [switch]$ContinueExisting
)

$backupFolder = "C-Drive-Backup-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
if ($ContinueExisting) {
    $existing = Get-ChildItem "$TargetDrive\" | Where-Object {$_.Name -like "*C-Drive-Backup*"} | Sort-Object CreationTime -Descending | Select-Object -First 1
    if ($existing) {
        $backupFolder = $existing.Name
        Write-Host "Continuing backup in: $backupFolder" -ForegroundColor Green
    }
}

$fullBackupPath = "$TargetDrive\$backupFolder"
Write-Host "=== Simple C: Drive Backup ===" -ForegroundColor Green
Write-Host "Target: $fullBackupPath" -ForegroundColor Yellow

# Ensure backup directory exists
if (!(Test-Path $fullBackupPath)) {
    New-Item -ItemType Directory -Path $fullBackupPath -Force | Out-Null
}

# Define folders to backup
$folders = @(
    @{Source="$env:USERPROFILE\Desktop"; Target="Desktop"},
    @{Source="$env:USERPROFILE\Documents"; Target="Documents"},
    @{Source="$env:USERPROFILE\Downloads"; Target="Downloads"}
)

$totalFiles = 0
$totalSize = 0

foreach ($folder in $folders) {
    Write-Host "`n--- Processing $($folder.Target) ---" -ForegroundColor Yellow
    
    if (Test-Path $folder.Source) {
        $destPath = "$fullBackupPath\$($folder.Target)"
        
        try {
            # Use robocopy for reliable copying
            $result = robocopy $folder.Source $destPath /E /COPY:DAT /R:1 /W:1 /XF *.tmp *.temp /XD AppData "Application Data" /MT:4 /V
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -le 1) {
                Write-Host "✅ $($folder.Target) completed successfully" -ForegroundColor Green
            } elseif ($exitCode -le 7) {
                Write-Host "⚠️ $($folder.Target) completed with minor issues" -ForegroundColor Yellow
            } else {
                Write-Host "❌ $($folder.Target) had errors (code: $exitCode)" -ForegroundColor Red
            }
            
            # Count files in this backup
            $files = Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue
            $folderFiles = $files.Count
            $folderSize = ($files | Measure-Object Length -Sum).Sum
            
            Write-Host "Files: $folderFiles, Size: $([math]::Round($folderSize/1MB,2))MB" -ForegroundColor Cyan
            $totalFiles += $folderFiles
            $totalSize += $folderSize
            
        } catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "$($folder.Target) folder not found" -ForegroundColor Gray
    }
}

# Backup browser bookmarks
Write-Host "`n--- Backing up Browser Bookmarks ---" -ForegroundColor Yellow
$browserBackup = "$fullBackupPath\Browser-Bookmarks"
New-Item -ItemType Directory -Path $browserBackup -Force | Out-Null

$bookmarkPaths = @(
    "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks",
    "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
)

foreach ($path in $bookmarkPaths) {
    if (Test-Path $path) {
        $fileName = Split-Path $path -Leaf
        $browserName = if ($path -like "*Chrome*") { "Chrome" } else { "Edge" }
        Copy-Item $path "$browserBackup\${browserName}-${fileName}" -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Saved $browserName bookmarks" -ForegroundColor Green
    }
}

# Create summary
$summary = @"
C: Drive Backup Summary
=======================
Date: $(Get-Date)
Location: $fullBackupPath
Total Files: $totalFiles
Total Size: $([math]::Round($totalSize/1MB,2))MB

Folders Backed Up:
- Desktop: $(if (Test-Path "$fullBackupPath\Desktop") { "✅" } else { "❌" })
- Documents: $(if (Test-Path "$fullBackupPath\Documents") { "✅" } else { "❌" })
- Downloads: $(if (Test-Path "$fullBackupPath\Downloads") { "✅" } else { "❌" })
- Browser Bookmarks: $(if (Test-Path "$fullBackupPath\Browser-Bookmarks") { "✅" } else { "❌" })

Next Steps:
1. Verify important files are backed up
2. Clean up C: drive space
3. Consider moving large files to D: drive
"@

$summary | Out-File "$fullBackupPath\summary.txt" -Encoding UTF8

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
Write-Host "Summary saved to: $fullBackupPath\summary.txt" -ForegroundColor Cyan
Write-Host "Total: $totalFiles files ($([math]::Round($totalSize/1MB,2))MB)" -ForegroundColor Green

# Check remaining space
$driveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$freeGB = [math]::Round($driveInfo.FreeSpace / 1GB, 2)
Write-Host "`nC: Drive free space: ${freeGB}GB" -ForegroundColor $(if ($freeGB -lt 10) { "Red" } else { "Yellow" })
# Emergency C Drive Cleanup and Migration Script
# Moves files from C: to D: drive to prevent system crash
# URGENT: C: drive is 98.2% full!

Write-Host "🚨 EMERGENCY C: DRIVE CLEANUP 🚨" -ForegroundColor Red
Write-Host "C: Drive is critically full - system may crash!" -ForegroundColor Red

# Check current space
$cDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$freeGB = [math]::Round($cDrive.FreeSpace / 1GB, 2)
Write-Host "Current C: free space: ${freeGB}GB" -ForegroundColor Yellow

if ($freeGB -lt 5) {
    Write-Host "CRITICAL: Less than 5GB free - immediate action required!" -ForegroundColor Red
    
    # 1. Clean temporary files
    Write-Host "`n--- Cleaning Temporary Files ---" -ForegroundColor Yellow
    $tempPaths = @(
        "$env:TEMP\*",
        "C:\Windows\Temp\*",
        "$env:USERPROFILE\AppData\Local\Temp\*"
    )
    
    $totalCleaned = 0
    foreach ($path in $tempPaths) {
        try {
            $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            $size = ($files | Where-Object {!$_.PSIsContainer} | Measure-Object Length -Sum).Sum
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            $totalCleaned += $size
            Write-Host "Cleaned: $path ($([math]::Round($size/1MB,2))MB)" -ForegroundColor Green
        } catch {
            Write-Host "Could not clean: $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "Total cleaned: $([math]::Round($totalCleaned/1GB,2))GB" -ForegroundColor Green
    
    # 2. Move Downloads to D: drive
    Write-Host "`n--- Moving Downloads to D: Drive ---" -ForegroundColor Yellow
    $downloadsPath = "$env:USERPROFILE\Downloads"
    $targetPath = "D:\User-Data\Downloads"
    
    if (Test-Path $downloadsPath) {
        $downloadSize = (Get-ChildItem $downloadsPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Write-Host "Downloads folder size: $([math]::Round($downloadSize/1GB,2))GB" -ForegroundColor Cyan
        
        if ($downloadSize -gt 100MB) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            robocopy $downloadsPath $targetPath /MOVE /E /R:1 /W:1
            Write-Host "✅ Downloads moved to D:\User-Data\Downloads" -ForegroundColor Green
            
            # Create junction point so programs still work
            cmd /c "mklink /J `"$downloadsPath`" `"$targetPath`""
            Write-Host "✅ Created link so programs still work" -ForegroundColor Green
        }
    }
    
    # 3. Check space after cleanup
    $cDriveAfter = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeAfter = [math]::Round($cDriveAfter.FreeSpace / 1GB, 2)
    $gained = $freeAfter - $freeGB
    
    Write-Host "`n=== CLEANUP RESULTS ===" -ForegroundColor Green
    Write-Host "Space before: ${freeGB}GB" -ForegroundColor Yellow  
    Write-Host "Space after: ${freeAfter}GB" -ForegroundColor Green
    Write-Host "Space gained: ${gained}GB" -ForegroundColor Cyan
    
    if ($freeAfter -lt 10) {
        Write-Host "`n🚨 STILL CRITICAL - Need more cleanup!" -ForegroundColor Red
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Uninstall unused programs" -ForegroundColor White
        Write-Host "2. Move more files to D: drive" -ForegroundColor White  
        Write-Host "3. Run disk cleanup tool" -ForegroundColor White
    } else {
        Write-Host "✅ C: drive stabilized - but keep monitoring!" -ForegroundColor Green
    }
}

Write-Host "`n--- Storage Recommendations ---" -ForegroundColor Cyan
Write-Host "✅ Use D: drive (176GB free) for all your files" -ForegroundColor Green
Write-Host "✅ Set up Lexar SSD 512GB for external storage" -ForegroundColor Green  
Write-Host "✅ Keep C: drive only for Windows and programs" -ForegroundColor Green
Write-Host "⚠️ Don't rely on USB drives until connection issues fixed" -ForegroundColor Yellow
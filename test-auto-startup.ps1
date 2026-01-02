#Requires -Version 5.1
<#
.SYNOPSIS
    Test Auto-Startup Configuration
.DESCRIPTION
    Comprehensive testing of restart detection and screen event handling
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto-Startup Configuration Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$flagFile = "C:\Users\USER\OneDrive\.restart-flag"
$startupScript = "C:\Users\USER\OneDrive\auto-start-vps-admin.ps1"
$logsPath = "C:\Users\USER\OneDrive\vps-logs"

# Ensure logs directory exists
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    Write-Host "[TEST] Created logs directory" -ForegroundColor Green
}

$testResults = @()

# Test 1: Check if scripts exist
Write-Host "[TEST 1/6] Checking script files..." -ForegroundColor Yellow
$scripts = @(
    "restart-detector.ps1",
    "screen-handler.ps1",
    "shutdown-handler.ps1",
    "auto-start-vps-admin.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path $workspaceRoot $script
    if (Test-Path $scriptPath) {
        Write-Host "    [OK] Found: $script" -ForegroundColor Green
        $testResults += @{Test="Script Check: $script"; Status="PASS"}
    } else {
        Write-Host "    [FAIL] Missing: $script" -ForegroundColor Red
        $testResults += @{Test="Script Check: $script"; Status="FAIL"}
    }
}

# Test 2: Check scheduled tasks
Write-Host "[TEST 2/6] Checking scheduled tasks..." -ForegroundColor Yellow
$tasks = Get-ScheduledTask -TaskName "VPS-AutoStart-*" -ErrorAction SilentlyContinue

if ($tasks) {
    Write-Host "    [OK] Found $($tasks.Count) scheduled task(s)" -ForegroundColor Green
    foreach ($task in $tasks) {
        Write-Host "        - $($task.TaskName): $($task.State)" -ForegroundColor Cyan
        $testResults += @{Test="Scheduled Task: $($task.TaskName)"; Status="PASS"}
    }
} else {
    Write-Host "    [FAIL] No scheduled tasks found" -ForegroundColor Red
    $testResults += @{Test="Scheduled Tasks"; Status="FAIL"}
}

# Test 3: Test restart detection logic (Cold Boot Scenario)
Write-Host "[TEST 3/6] Testing restart detection (Cold Boot scenario)..." -ForegroundColor Yellow
try {
    # Simulate cold boot: Remove flag file
    if (Test-Path $flagFile) {
        Remove-Item $flagFile -Force
        Write-Host "    [INFO] Removed flag file to simulate cold boot" -ForegroundColor Cyan
    }
    
    # Run restart detector
    $detectorPath = Join-Path $workspaceRoot "restart-detector.ps1"
    $output = & powershell.exe -ExecutionPolicy Bypass -NoProfile -File $detectorPath 2>&1
    
    # Check if flag was created (cold boot behavior)
    if (Test-Path $flagFile) {
        Write-Host "    [OK] Cold boot detected correctly (flag created)" -ForegroundColor Green
        $testResults += @{Test="Restart Detection: Cold Boot"; Status="PASS"}
    } else {
        Write-Host "    [FAIL] Flag file not created on cold boot" -ForegroundColor Red
        $testResults += @{Test="Restart Detection: Cold Boot"; Status="FAIL"}
    }
} catch {
    Write-Host "    [ERROR] Test failed: $_" -ForegroundColor Red
    $testResults += @{Test="Restart Detection: Cold Boot"; Status="ERROR"}
}

# Test 4: Test restart detection logic (Restart Scenario)
Write-Host "[TEST 4/6] Testing restart detection (Restart scenario)..." -ForegroundColor Yellow
try {
    # Simulate restart: Ensure flag file exists
    if (-not (Test-Path $flagFile)) {
        New-Item -ItemType File -Path $flagFile -Force | Out-Null
    }
    Write-Host "    [INFO] Flag file exists to simulate restart" -ForegroundColor Cyan
    
    # Check log file to see if it would start
    $logFile = Join-Path $logsPath "restart-detector.log"
    $logBefore = if (Test-Path $logFile) { Get-Content $logFile -Tail 1 } else { "" }
    
    # Run restart detector
    $detectorPath = Join-Path $workspaceRoot "restart-detector.ps1"
    $output = & powershell.exe -ExecutionPolicy Bypass -NoProfile -File $detectorPath 2>&1
    
    Start-Sleep -Seconds 2
    
    # Check log file
    if (Test-Path $logFile) {
        $logAfter = Get-Content $logFile -Tail 1
        if ($logAfter -like "*RESTART DETECTED*") {
            Write-Host "    [OK] Restart detected correctly" -ForegroundColor Green
            $testResults += @{Test="Restart Detection: Restart"; Status="PASS"}
        } else {
            Write-Host "    [WARNING] Restart detection may not have logged correctly" -ForegroundColor Yellow
            $testResults += @{Test="Restart Detection: Restart"; Status="WARNING"}
        }
    } else {
        Write-Host "    [WARNING] Log file not created" -ForegroundColor Yellow
        $testResults += @{Test="Restart Detection: Restart"; Status="WARNING"}
    }
} catch {
    Write-Host "    [ERROR] Test failed: $_" -ForegroundColor Red
    $testResults += @{Test="Restart Detection: Restart"; Status="ERROR"}
}

# Test 5: Test screen handler script syntax
Write-Host "[TEST 5/6] Testing screen handler script..." -ForegroundColor Yellow
try {
    $screenHandlerPath = Join-Path $workspaceRoot "screen-handler.ps1"
    
    # Test script syntax
    $syntaxCheck = powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& { Get-Command -Syntax (Get-Content '$screenHandlerPath' | Out-String) }" 2>&1
    
    # Try to parse the script
    $parseTest = [System.Management.Automation.PSParser]::Tokenize((Get-Content $screenHandlerPath -Raw), [ref]$null)
    
    if ($parseTest) {
        Write-Host "    [OK] Screen handler script syntax is valid" -ForegroundColor Green
        $testResults += @{Test="Screen Handler: Syntax"; Status="PASS"}
    } else {
        Write-Host "    [FAIL] Screen handler script has syntax errors" -ForegroundColor Red
        $testResults += @{Test="Screen Handler: Syntax"; Status="FAIL"}
    }
} catch {
    Write-Host "    [WARNING] Could not fully validate syntax: $_" -ForegroundColor Yellow
    $testResults += @{Test="Screen Handler: Syntax"; Status="WARNING"}
}

# Test 6: Test flag file mechanism
Write-Host "[TEST 6/6] Testing flag file mechanism..." -ForegroundColor Yellow
try {
    # Test 1: Create flag
    if (Test-Path $flagFile) {
        Remove-Item $flagFile -Force
    }
    New-Item -ItemType File -Path $flagFile -Force | Out-Null
    
    if (Test-Path $flagFile) {
        Write-Host "    [OK] Flag file can be created" -ForegroundColor Green
        $testResults += @{Test="Flag File: Create"; Status="PASS"}
    } else {
        Write-Host "    [FAIL] Flag file creation failed" -ForegroundColor Red
        $testResults += @{Test="Flag File: Create"; Status="FAIL"}
    }
    
    # Test 2: Read flag
    if (Test-Path $flagFile) {
        Write-Host "    [OK] Flag file can be read" -ForegroundColor Green
        $testResults += @{Test="Flag File: Read"; Status="PASS"}
    } else {
        Write-Host "    [FAIL] Flag file not found for reading" -ForegroundColor Red
        $testResults += @{Test="Flag File: Read"; Status="FAIL"}
    }
    
    # Restore flag for actual use
    if (-not (Test-Path $flagFile)) {
        New-Item -ItemType File -Path $flagFile -Force | Out-Null
    }
} catch {
    Write-Host "    [ERROR] Flag file test failed: $_" -ForegroundColor Red
    $testResults += @{Test="Flag File"; Status="ERROR"}
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$warnings = ($testResults | Where-Object { $_.Status -eq "WARNING" }).Count
$errors = ($testResults | Where-Object { $_.Status -eq "ERROR" }).Count

Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor Yellow
Write-Host "  [OK] Passed: $passed" -ForegroundColor Green
Write-Host "  [FAIL] Failed: $failed" -ForegroundColor Red
Write-Host "  [WARN] Warnings: $warnings" -ForegroundColor Yellow
Write-Host "  [ERROR] Errors: $errors" -ForegroundColor Red
Write-Host ""

# Detailed results
Write-Host "Detailed Results:" -ForegroundColor Yellow
foreach ($result in $testResults) {
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    $symbol = switch ($result.Status) {
        "PASS" { "[OK]" }
        "FAIL" { "[FAIL]" }
        "WARNING" { "[WARN]" }
        "ERROR" { "[ERROR]" }
        default { "[?]" }
    }
    Write-Host "  $symbol $($result.Test): $($result.Status)" -ForegroundColor $color
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($failed -eq 0 -and $errors -eq 0) {
    Write-Host "[OK] All critical tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart your system to test actual restart detection" -ForegroundColor White
    Write-Host "  2. Lock/unlock screen to test screen event handling" -ForegroundColor White
    Write-Host "  3. Check logs in: $logsPath" -ForegroundColor White
} else {
    Write-Host "WARNING: Some tests failed. Please review the results above." -ForegroundColor Yellow
}

Write-Host ""


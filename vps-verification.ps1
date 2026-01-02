#Requires -Version 5.1
<#
.SYNOPSIS
    VPS Verification Script - Confirms all services are running correctly
.DESCRIPTION
    Verifies that all 24/7 services are running on the VPS:
    - Exness MT5 Terminal
    - Web Research Service
    - GitHub Website Service
    - CI/CD Automation
    - MQL5 Forge Integration
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VPS System Verification" -ForegroundColor Cyan
Write-Host "  Checking all 24/7 services..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$vpsServicesPath = "$workspaceRoot\vps-services"
$logsPath = "$workspaceRoot\vps-logs"

$allServicesRunning = $true

# Check Exness Terminal
Write-Host "[1/6] Checking Exness MT5 Terminal..." -ForegroundColor Yellow
$exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
if ($exnessProcess) {
    Write-Host "    [OK] Exness Terminal is running (PID: $($exnessProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [ERROR] Exness Terminal is NOT running" -ForegroundColor Red
    $allServicesRunning = $false
}

# Check Research Service
Write-Host "[2/6] Checking Web Research Service..." -ForegroundColor Yellow
$researchProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*research-service*" }
if ($researchProcess) {
    Write-Host "    [OK] Research Service is running (PID: $($researchProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] Research Service may not be running" -ForegroundColor Yellow
}

# Check Website Service
Write-Host "[3/6] Checking GitHub Website Service..." -ForegroundColor Yellow
$websiteProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*website-service*" }
if ($websiteProcess) {
    Write-Host "    [OK] Website Service is running (PID: $($websiteProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] Website Service may not be running" -ForegroundColor Yellow
}

# Check CI/CD Service
Write-Host "[4/6] Checking CI/CD Automation Service..." -ForegroundColor Yellow
$cicdProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*cicd-service*" }
if ($cicdProcess) {
    Write-Host "    [OK] CI/CD Service is running (PID: $($cicdProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] CI/CD Service may not be running" -ForegroundColor Yellow
}

# Check MQL5 Service
Write-Host "[5/6] Checking MQL5 Forge Service..." -ForegroundColor Yellow
$mql5Process = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*mql5-service*" }
if ($mql5Process) {
    Write-Host "    [OK] MQL5 Service is running (PID: $($mql5Process.Id))" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] MQL5 Service may not be running" -ForegroundColor Yellow
}

# Check Master Controller
Write-Host "[6/6] Checking Master Controller..." -ForegroundColor Yellow
$masterProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*master-controller*" }
if ($masterProcess) {
    Write-Host "    [OK] Master Controller is running (PID: $($masterProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    [WARNING] Master Controller may not be running" -ForegroundColor Yellow
}

# Check Firefox (for website and research)
Write-Host ""
Write-Host "Checking Firefox processes..." -ForegroundColor Yellow
$firefoxProcess = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
if ($firefoxProcess) {
    Write-Host "    [OK] Firefox is running ($($firefoxProcess.Count) process(es))" -ForegroundColor Green
} else {
    Write-Host "    [INFO] Firefox is not running (will start when needed)" -ForegroundColor Cyan
}

# Check log files
Write-Host ""
Write-Host "Checking log files..." -ForegroundColor Yellow
if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" -ErrorAction SilentlyContinue
    if ($logFiles) {
        Write-Host "    [OK] Found $($logFiles.Count) log file(s)" -ForegroundColor Green
        foreach ($log in $logFiles) {
            $lines = (Get-Content $log.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
            Write-Host "        - $($log.Name): $lines lines" -ForegroundColor Cyan
        }
    } else {
        Write-Host "    [INFO] No log files found yet" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [WARNING] Log directory not found" -ForegroundColor Yellow
}

# Check repository
Write-Host ""
Write-Host "Checking GitHub repositories..." -ForegroundColor Yellow
$zoloRepo = Join-Path $workspaceRoot "ZOLO-A6-9VxNUNA"
if (Test-Path $zoloRepo) {
    Write-Host "    [OK] ZOLO-A6-9VxNUNA repository exists" -ForegroundColor Green
    Set-Location $zoloRepo
    $gitStatus = git status --porcelain 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Repository is accessible" -ForegroundColor Green
    }
} else {
    Write-Host "    [WARNING] ZOLO-A6-9VxNUNA repository not found" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allServicesRunning) {
    Write-Host "[OK] All critical services are running!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Some services may not be running" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start all services, run:" -ForegroundColor Cyan
    Write-Host "  powershell.exe -ExecutionPolicy Bypass -File `"$vpsServicesPath\master-controller.ps1`"" -ForegroundColor White
}

Write-Host ""
Write-Host "Service location: $vpsServicesPath" -ForegroundColor Cyan
Write-Host "Logs location: $logsPath" -ForegroundColor Cyan
Write-Host ""

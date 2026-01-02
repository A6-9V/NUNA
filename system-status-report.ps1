#Requires -Version 5.1
<#
.SYNOPSIS
    System Status Report - Comprehensive verification and security check
.DESCRIPTION
    Generates a complete report of system status, services, and security
#>

$ErrorActionPreference = "Continue"
$reportPath = "C:\Users\USER\OneDrive\SYSTEM-STATUS-REPORT.txt"
$reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  System Status Report" -ForegroundColor Cyan
Write-Host "  Generating comprehensive report..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$report = @"
========================================
  SYSTEM STATUS REPORT
  Generated: $reportDate
  System: NuNa (Windows 11 Home Single Language 25H2)
========================================

"@

# 1. System Information
Write-Host "[1/8] Collecting system information..." -ForegroundColor Yellow
$report += @"
## 1. SYSTEM INFORMATION
------------------------
Computer Name: $env:COMPUTERNAME
User: $env:USERNAME
OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
Architecture: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture)
PowerShell Version: $($PSVersionTable.PSVersion)
Execution Policy: $(Get-ExecutionPolicy)

"@

# 2. Service Status
Write-Host "[2/8] Checking service status..." -ForegroundColor Yellow
$exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
$firefoxProcess = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
$pythonProcess = Get-Process -Name "python" -ErrorAction SilentlyContinue
$powershellServices = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*vps-services*" }

$report += @"
## 2. SERVICE STATUS
--------------------
Exness MT5 Terminal: $(if ($exnessProcess) { "RUNNING (PID: $($exnessProcess.Id))" } else { "NOT RUNNING" })
Firefox: $(if ($firefoxProcess) { "RUNNING ($($firefoxProcess.Count) process(es))" } else { "NOT RUNNING" })
Python: $(if ($pythonProcess) { "RUNNING ($($pythonProcess.Count) process(es))" } else { "NOT RUNNING" })
VPS Services: $(if ($powershellServices) { "RUNNING ($($powershellServices.Count) process(es))" } else { "NOT RUNNING" })

"@

# 3. File System Status
Write-Host "[3/8] Checking file system..." -ForegroundColor Yellow
$workspaceRoot = "C:\Users\USER\OneDrive"
$vpsServicesPath = "$workspaceRoot\vps-services"
$logsPath = "$workspaceRoot\vps-logs"
$zoloRepo = "$workspaceRoot\ZOLO-A6-9VxNUNA"

$report += @"
## 3. FILE SYSTEM STATUS
------------------------
Workspace Root: $(if (Test-Path $workspaceRoot) { "EXISTS" } else { "MISSING" })
VPS Services: $(if (Test-Path $vpsServicesPath) { "EXISTS ($((Get-ChildItem $vpsServicesPath -ErrorAction SilentlyContinue).Count) files)" } else { "MISSING" })
Logs Directory: $(if (Test-Path $logsPath) { "EXISTS ($((Get-ChildItem $logsPath -ErrorAction SilentlyContinue).Count) files)" } else { "MISSING" })
ZOLO Repository: $(if (Test-Path $zoloRepo) { "EXISTS" } else { "MISSING" })

"@

# 4. Security Status
Write-Host "[4/8] Checking security..." -ForegroundColor Yellow
$defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
$firewallStatus = Get-NetFirewallProfile -ErrorAction SilentlyContinue

$report += @"
## 4. SECURITY STATUS
---------------------
Windows Defender: $(if ($defenderStatus) { "ENABLED" } else { "UNKNOWN" })
Firewall Profiles:
$(if ($firewallStatus) {
    $firewallStatus | ForEach-Object { "  - $($_.Name): $($_.Enabled)" }
} else {
    "  - Status: UNKNOWN"
})

Execution Policy: $(Get-ExecutionPolicy)
Admin Privileges: $(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

"@

# 5. Network Status
Write-Host "[5/8] Checking network..." -ForegroundColor Yellow
$networkAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
$internetConnection = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue

$report += @"
## 5. NETWORK STATUS
--------------------
Internet Connection: $(if ($internetConnection) { "CONNECTED" } else { "NOT CONNECTED" })
Active Network Adapters: $($networkAdapters.Count)
$(if ($networkAdapters) {
    $networkAdapters | ForEach-Object { "  - $($_.Name): $($_.LinkSpeed)" }
})

"@

# 6. Application Status
Write-Host "[6/8] Checking applications..." -ForegroundColor Yellow
$exnessPath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
$firefoxPath = Get-Command firefox -ErrorAction SilentlyContinue
$pythonPath = Get-Command python -ErrorAction SilentlyContinue
$gitPath = Get-Command git -ErrorAction SilentlyContinue

$report += @"
## 6. APPLICATION STATUS
------------------------
Exness MT5: $(if (Test-Path $exnessPath) { "INSTALLED" } else { "NOT FOUND" })
Firefox: $(if ($firefoxPath) { "INSTALLED ($($firefoxPath.Source))" } else { "NOT FOUND" })
Python: $(if ($pythonPath) { "INSTALLED ($($pythonPath.Source))" } else { "NOT FOUND" })
Git: $(if ($gitPath) { "INSTALLED ($($gitPath.Source))" } else { "NOT FOUND" })

"@

# 7. Repository Status
Write-Host "[7/8] Checking repositories..." -ForegroundColor Yellow
$report += "## 7. REPOSITORY STATUS`n"
$report += "------------------------`n"

if (Test-Path $zoloRepo) {
    Set-Location $zoloRepo
    $gitStatus = git status --porcelain 2>&1
    $gitRemote = git remote -v 2>&1
    $report += "ZOLO-A6-9VxNUNA: EXISTS`n"
    $report += "  Remote: $(if ($gitRemote) { ($gitRemote | Select-Object -First 1) } else { "NOT CONFIGURED" })`n"
    $report += "  Status: $(if ($gitStatus) { "HAS CHANGES" } else { "CLEAN" })`n"
} else {
    $report += "ZOLO-A6-9VxNUNA: NOT CLONED`n"
}

$myDriveRepo = "$workspaceRoot\my-drive-projects"
if (Test-Path $myDriveRepo) {
    Set-Location $myDriveRepo
    $gitStatus = git status --porcelain 2>&1
    $report += "my-drive-projects: EXISTS`n"
    $report += "  Status: $(if ($gitStatus) { "HAS CHANGES" } else { "CLEAN" })`n"
} else {
    $report += "my-drive-projects: NOT CLONED`n"
}

$report += "`n"

# 8. Log Files Status
Write-Host "[8/8] Checking log files..." -ForegroundColor Yellow
$report += @"
## 8. LOG FILES STATUS
----------------------
"@

if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" -ErrorAction SilentlyContinue
    if ($logFiles) {
        foreach ($log in $logFiles) {
            $lines = (Get-Content $log.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
            $lastModified = $log.LastWriteTime
            $report += "$($log.Name): $lines lines (Last modified: $lastModified)`n"
        }
    } else {
        $report += "No log files found`n"
    }
} else {
    $report += "Log directory not found`n"
}

$report += "`n"

# Summary
$report += @"
========================================
  SUMMARY
========================================

System Status: $(if ($exnessProcess -and $powershellServices) { "OPERATIONAL" } else { "NEEDS ATTENTION" })
Services Running: $(if ($exnessProcess) { "Exness Terminal" } else { "None" })$(if ($powershellServices) { ", VPS Services" } else { "" })
Security: $(if ($defenderStatus) { "Windows Defender Active" } else { "Check Defender Status" })
Network: $(if ($internetConnection) { "Connected" } else { "Not Connected" })

Recommendations:
$(if (-not $exnessProcess) { "- Start Exness Terminal`n" })
$(if (-not $powershellServices) { "- Start VPS Services (run start-vps-system.ps1)`n" })
$(if (-not $internetConnection) { "- Check internet connection`n" })
$(if (-not (Test-Path $zoloRepo)) { "- Clone ZOLO-A6-9VxNUNA repository`n" })

========================================
Report generated: $reportDate
========================================
"@

# Save report
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Report Generated!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Green
Write-Host ""

# Display summary
Write-Host "QUICK SUMMARY:" -ForegroundColor Yellow
Write-Host "  Exness Terminal: $(if ($exnessProcess) { "RUNNING" } else { "NOT RUNNING" })" -ForegroundColor $(if ($exnessProcess) { "Green" } else { "Red" })
Write-Host "  VPS Services: $(if ($powershellServices) { "RUNNING" } else { "NOT RUNNING" })" -ForegroundColor $(if ($powershellServices) { "Green" } else { "Red" })
Write-Host "  Internet: $(if ($internetConnection) { "CONNECTED" } else { "NOT CONNECTED" })" -ForegroundColor $(if ($internetConnection) { "Green" } else { "Red" })
Write-Host "  Security: $(if ($defenderStatus) { "ACTIVE" } else { "CHECK" })" -ForegroundColor $(if ($defenderStatus) { "Green" } else { "Yellow" })
Write-Host ""

# Open report
try {
    Start-Process notepad.exe -ArgumentList $reportPath
} catch {
    Write-Host "Could not open report automatically. Open manually: $reportPath" -ForegroundColor Yellow
}

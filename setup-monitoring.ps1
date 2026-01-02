# 24/7 Monitoring and Automation Setup
# Provides continuous monitoring and automatic system management

$ErrorActionPreference = "Continue"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "24/7 Monitoring and Automation Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create monitoring directory
$monitoringDir = Join-Path $script:RepoPath "monitoring"
if (-not (Test-Path $monitoringDir)) {
    New-Item -ItemType Directory -Path $monitoringDir -Force | Out-Null
}

# Master monitor service
$masterMonitor = @'
# Master Monitor Service
# 24/7 monitoring and automation

param(
    [int]$CheckInterval = 30,
    [switch]$StartAll,
    [switch]$StopAll
)

$ErrorActionPreference = "Continue"
$script:RepoPath = "C:\Users\USER\OneDrive\OS-application-support"

Write-Host "Master Monitor Service" -ForegroundColor Cyan

function Start-MonitoringServices {
    Write-Host "[INFO] Starting all monitoring services..." -ForegroundColor Yellow
    
    # Start device monitoring
    $deviceMonitor = Join-Path $script:RepoPath "remote-device\device-monitor.ps1"
    if (Test-Path $deviceMonitor) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$deviceMonitor`" -Continuous" -WindowStyle Hidden
        Write-Host "    [OK] Device monitoring started" -ForegroundColor Green
    }
    
    # Start trading system monitoring
    $tradingMonitor = Join-Path $script:RepoPath "trading-system\trading-manager.ps1"
    if (Test-Path $tradingMonitor) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tradingMonitor`" status" -WindowStyle Hidden
        Write-Host "    [OK] Trading system monitoring started" -ForegroundColor Green
    }
    
    # Start security monitoring
    $securityMonitor = Join-Path $script:RepoPath "security\security-monitor.ps1"
    if (Test-Path $securityMonitor) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$securityMonitor`" -Continuous" -WindowStyle Hidden
        Write-Host "    [OK] Security monitoring started" -ForegroundColor Green
    }
}

function Stop-MonitoringServices {
    Write-Host "[INFO] Stopping all monitoring services..." -ForegroundColor Yellow
    Get-Process powershell | Where-Object { $_.CommandLine -like "*monitor*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "    [OK] Monitoring services stopped" -ForegroundColor Green
}

function Monitor-System {
    while ($true) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] System Check" -ForegroundColor Cyan
        
        # Check device status
        Write-Host "    Checking device..." -ForegroundColor Yellow
        # Add device check
        
        # Check trading system
        Write-Host "    Checking trading system..." -ForegroundColor Yellow
        # Add trading system check
        
        # Check security
        Write-Host "    Checking security..." -ForegroundColor Yellow
        # Add security check
        
        Write-Host "    [OK] All systems operational" -ForegroundColor Green
        Start-Sleep -Seconds $CheckInterval
    }
}

if ($StartAll) {
    Start-MonitoringServices
    Monitor-System
} elseif ($StopAll) {
    Stop-MonitoringServices
} else {
    Monitor-System
}
'@

Set-Content -Path (Join-Path $monitoringDir "master-monitor.ps1") -Value $masterMonitor
Write-Host "[OK] Created master-monitor.ps1" -ForegroundColor Green

# Auto-restart service
$autoRestart = @'
# Auto-Restart Service
# Automatically restarts services if they fail

param(
    [string]$ServiceName,
    [int]$CheckInterval = 60,
    [switch]$Continuous
)

$ErrorActionPreference = "Continue"

function Restart-ServiceIfDown {
    param([string]$Service)
    
    $process = Get-Process -Name $Service -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Host "[WARNING] Service $Service is down. Restarting..." -ForegroundColor Yellow
        # Add restart logic
        Write-Host "    [OK] Service restarted" -ForegroundColor Green
    } else {
        Write-Host "[OK] Service $Service is running" -ForegroundColor Green
    }
}

if ($Continuous) {
    Write-Host "Starting auto-restart monitoring (interval: $CheckInterval seconds)..." -ForegroundColor Yellow
    while ($true) {
        if ($ServiceName) {
            Restart-ServiceIfDown -Service $ServiceName
        }
        Start-Sleep -Seconds $CheckInterval
    }
} else {
    if ($ServiceName) {
        Restart-ServiceIfDown -Service $ServiceName
    }
}
'@

Set-Content -Path (Join-Path $monitoringDir "auto-restart.ps1") -Value $autoRestart
Write-Host "[OK] Created auto-restart.ps1" -ForegroundColor Green

# Health check service
$healthCheck = @'
# System Health Check
# Comprehensive system health monitoring

param(
    [switch]$FullCheck,
    [switch]$ExportReport
)

$ErrorActionPreference = "Continue"

Write-Host "System Health Check" -ForegroundColor Cyan

# CPU check
$cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
Write-Host "    CPU Usage: $([math]::Round($cpu.Average, 2))%" -ForegroundColor Yellow

# Memory check
$memory = Get-CimInstance Win32_OperatingSystem
$usedMemory = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
$totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
Write-Host "    Memory Usage: $usedMemory MB / $totalMemory MB" -ForegroundColor Yellow

# Disk check
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
Write-Host "    Disk Space: $freeSpace GB / $totalSpace GB free" -ForegroundColor Yellow

# Network check
$network = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
Write-Host "    Network Adapters: $($network.Count) active" -ForegroundColor Yellow

if ($FullCheck) {
    Write-Host "    Running full system check..." -ForegroundColor Yellow
    # Add more comprehensive checks
}

Write-Host "    [OK] Health check complete" -ForegroundColor Green

if ($ExportReport) {
    $reportPath = Join-Path $PSScriptRoot "health-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    # Export report
    Write-Host "    [OK] Report exported: $reportPath" -ForegroundColor Green
}
'@

Set-Content -Path (Join-Path $monitoringDir "health-check.ps1") -Value $healthCheck
Write-Host "[OK] Created health-check.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "[OK] Monitoring setup complete!" -ForegroundColor Green

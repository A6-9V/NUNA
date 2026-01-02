#Requires -Version 5.1
<#
.SYNOPSIS
    Complete Configuration for MetaTrader Exness on Port 5500
.DESCRIPTION
    This script configures the entire trading bridge system to use port 5500
    for MetaTrader Exness connection, including firewall setup.
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MetaTrader Exness Configuration" -ForegroundColor Cyan
Write-Host "  Port 5500 Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$firewallScript = Join-Path $scriptPath "setup-firewall-port-5500.ps1"

Write-Host "[INFO] Configuration Summary:" -ForegroundColor Yellow
Write-Host "  - Python Bridge Port: 5500" -ForegroundColor White
Write-Host "  - MQL5 EA Bridge Port: 5500" -ForegroundColor White
Write-Host "  - Firewall: Port 5500 (TCP Inbound)" -ForegroundColor White
Write-Host ""

Write-Host "[1/2] Configuring firewall for port 5500..." -ForegroundColor Yellow
if (Test-Path $firewallScript) {
    try {
        & $firewallScript
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Firewall configured successfully" -ForegroundColor Green
        }
        else {
            Write-Host "    [WARNING] Firewall configuration may have issues" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "    [ERROR] Failed to configure firewall: $_" -ForegroundColor Red
        Write-Host "    [INFO] You may need to run the firewall script as administrator separately" -ForegroundColor Yellow
    }
}
else {
    Write-Host "    [WARNING] Firewall script not found: $firewallScript" -ForegroundColor Yellow
    Write-Host "    [INFO] Please run setup-firewall-port-5500.ps1 as administrator" -ForegroundColor Cyan
}

Write-Host "[2/2] Verifying configuration files..." -ForegroundColor Yellow

# Check Python files
$pythonService = Join-Path $scriptPath "python\services\background_service.py"
$pythonBridge = Join-Path $scriptPath "python\bridge\mql5_bridge.py"

if (Test-Path $pythonService) {
    $serviceContent = Get-Content $pythonService -Raw
    if ($serviceContent -match "bridge_port: int = 5500") {
        Write-Host "    [OK] Python background service configured for port 5500" -ForegroundColor Green
    }
    else {
        Write-Host "    [WARNING] Python background service may not be configured correctly" -ForegroundColor Yellow
    }
}

if (Test-Path $pythonBridge) {
    $bridgeContent = Get-Content $pythonBridge -Raw
    if ($bridgeContent -match "port: int = 5500") {
        Write-Host "    [OK] Python bridge configured for port 5500" -ForegroundColor Green
    }
    else {
        Write-Host "    [WARNING] Python bridge may not be configured correctly" -ForegroundColor Yellow
    }
}

# Check MQL5 EA
$mql5EA = Join-Path $scriptPath "mql5\Experts\PythonBridgeEA.mq5"
if (Test-Path $mql5EA) {
    $eaContent = Get-Content $mql5EA -Raw
    if ($eaContent -match "BridgePort = 5500") {
        Write-Host "    [OK] MQL5 EA configured for port 5500" -ForegroundColor Green
    }
    else {
        Write-Host "    [WARNING] MQL5 EA may not be configured correctly" -ForegroundColor Yellow
    }
}
else {
    Write-Host "    [INFO] MQL5 EA file not found (may need to be copied to MT5 directory)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Copy PythonBridgeEA.mq5 to your MT5 Experts directory" -ForegroundColor White
Write-Host "  2. Compile the EA in MetaEditor (F7)" -ForegroundColor White
Write-Host "  3. Attach EA to chart with BridgePort = 5500" -ForegroundColor White
Write-Host "  4. Start the Python trading bridge service" -ForegroundColor White
Write-Host "  5. Verify connection on port 5500" -ForegroundColor White
Write-Host ""
Write-Host "MQL5 EA Location:" -ForegroundColor Cyan
Write-Host "  C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\" -ForegroundColor White
Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green


#Requires -Version 5.1
<#
.SYNOPSIS
    Fix Python Service Import Issues
.DESCRIPTION
    Fixes Python path and import issues for trading service
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$pythonPath = Join-Path $tradingBridgePath "python"

Write-Host "Fixing Python service..." -ForegroundColor Cyan

# Create __init__.py files if missing
$initFiles = @(
    "trading-bridge\python\__init__.py",
    "trading-bridge\python\bridge\__init__.py",
    "trading-bridge\python\brokers\__init__.py",
    "trading-bridge\python\trader\__init__.py",
    "trading-bridge\python\services\__init__.py",
    "trading-bridge\python\security\__init__.py"
)

foreach ($initFile in $initFiles) {
    $fullPath = Join-Path $workspaceRoot $initFile
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType File -Path $fullPath -Force | Out-Null
        Write-Host "Created: $initFile" -ForegroundColor Green
    }
}

# Test Python imports
Write-Host "Testing Python imports..." -ForegroundColor Yellow
Set-Location $pythonPath

$testScript = @"
import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

try:
    from bridge.mql5_bridge import MQL5Bridge
    print('Bridge import: OK')
except Exception as e:
    print(f'Bridge import: ERROR - {e}')

try:
    from brokers.broker_factory import BrokerFactory
    print('Broker factory import: OK')
except Exception as e:
    print(f'Broker factory import: ERROR - {e}')

try:
    from trader.multi_symbol_trader import MultiSymbolTrader
    print('Trader import: OK')
except Exception as e:
    print(f'Trader import: ERROR - {e}')
"@

$testScript | python 2>&1

Write-Host ""
Write-Host "Python service fix complete" -ForegroundColor Green





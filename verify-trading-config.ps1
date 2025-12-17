#Requires -Version 5.1
<#
.SYNOPSIS
    Verify Trading System Configuration
.DESCRIPTION
    Checks broker and symbol configuration files for correctness
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$configPath = Join-Path $tradingBridgePath "config"

Write-Host "=== Trading System Configuration Verification ===" -ForegroundColor Cyan
Write-Host ""

# Check if config directory exists
if (-not (Test-Path $configPath)) {
    Write-Host "[ERROR] Config directory not found: $configPath" -ForegroundColor Red
    exit 1
}

# Check brokers.json
$brokersConfig = Join-Path $configPath "brokers.json"
if (Test-Path $brokersConfig) {
    Write-Host "[OK] brokers.json found" -ForegroundColor Green
    try {
        $brokers = Get-Content $brokersConfig | ConvertFrom-Json
        $brokerCount = $brokers.brokers.Count
        Write-Host "    Found $brokerCount broker(s)" -ForegroundColor Cyan
        
        foreach ($broker in $brokers.brokers) {
            Write-Host "    - $($broker.name): " -NoNewline
            if ($broker.enabled) {
                Write-Host "ENABLED" -ForegroundColor Green
            } else {
                Write-Host "DISABLED" -ForegroundColor Yellow
            }
            
            # Check for credential placeholders
            if ($broker.api_key -like "CREDENTIAL:*") {
                $credName = $broker.api_key -replace "CREDENTIAL:", ""
                Write-Host "      API Key: Using credential '$credName'" -ForegroundColor Cyan
            } elseif ($broker.api_key -like "YOUR_*") {
                Write-Host "      API Key: NOT CONFIGURED (placeholder found)" -ForegroundColor Red
            } else {
                Write-Host "      API Key: WARNING - Stored in plain text!" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "[ERROR] Invalid JSON in brokers.json: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[WARNING] brokers.json not found - using example" -ForegroundColor Yellow
    Write-Host "    Copy brokers.json.example to brokers.json and configure" -ForegroundColor Cyan
}

Write-Host ""

# Check symbols.json
$symbolsConfig = Join-Path $configPath "symbols.json"
if (Test-Path $symbolsConfig) {
    Write-Host "[OK] symbols.json found" -ForegroundColor Green
    try {
        $symbols = Get-Content $symbolsConfig | ConvertFrom-Json
        $symbolCount = $symbols.symbols.Count
        Write-Host "    Found $symbolCount symbol(s)" -ForegroundColor Cyan
        
        $enabledCount = ($symbols.symbols | Where-Object { $_.enabled }).Count
        Write-Host "    Enabled: $enabledCount" -ForegroundColor Green
        
        foreach ($symbol in $symbols.symbols) {
            if ($symbol.enabled) {
                Write-Host "    - $($symbol.symbol) on $($symbol.broker) (Risk: $($symbol.risk_percent)%)" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "[ERROR] Invalid JSON in symbols.json: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[WARNING] symbols.json not found - using example" -ForegroundColor Yellow
    Write-Host "    Copy symbols.json.example to symbols.json and configure" -ForegroundColor Cyan
}

Write-Host ""

# Check Python modules
Write-Host "Checking Python modules..." -ForegroundColor Yellow
$pythonPath = Join-Path $tradingBridgePath "python"
if (Test-Path $pythonPath) {
    Set-Location $pythonPath
    
    $testImports = @"
import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

errors = []
try:
    from bridge.mql5_bridge import MQL5Bridge
    print('Bridge: OK')
except Exception as e:
    errors.append(f'Bridge: ERROR - {e}')

try:
    from brokers.broker_factory import BrokerFactory
    print('Broker Factory: OK')
except Exception as e:
    errors.append(f'Broker Factory: ERROR - {e}')

try:
    from trader.multi_symbol_trader import MultiSymbolTrader
    print('Trader: OK')
except Exception as e:
    errors.append(f'Trader: ERROR - {e}')

if errors:
    for err in errors:
        print(err)
    sys.exit(1)
"@

    $testResult = $testImports | python 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Python modules import successfully" -ForegroundColor Green
        $testResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
    } else {
        Write-Host "[ERROR] Python module import failed" -ForegroundColor Red
        $testResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    }
} else {
    Write-Host "[ERROR] Python directory not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure brokers.json with your API keys (use Credential Manager)" -ForegroundColor Cyan
Write-Host "2. Configure symbols.json with trading symbols" -ForegroundColor Cyan
Write-Host "3. Start system: .\START-TRADING-SYSTEM-COMPLETE.ps1" -ForegroundColor Cyan

Set-Location $workspaceRoot





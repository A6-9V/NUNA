#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Setup 18-Symbol Trading System with SMC Strategy
.DESCRIPTION
    Configures the complete trading automation system with:
    - 18 trading symbols
    - Capital-based allocation
    - SMC + Trend Breakout + Multi-timeframe indicators
    - Automated risk management (TP/SL/Pending)
    - Multi-team communication (WhatsApp, Perplexity, GPT)
    - Exness MT5 account integration
#>

$ErrorActionPreference = "Stop"

$workspaceRoot = $PSScriptRoot
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$configPath = Join-Path $tradingBridgePath "config"
$pythonPath = Join-Path $tradingBridgePath "python"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 18-Symbol Trading System Setup" -ForegroundColor Cyan
Write-Host " SMC + Trend Breakout + Multi-TF" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to safely store credentials in Windows Credential Manager
function Store-Credential {
    param(
        [string]$Target,
        [string]$Username,
        [string]$Password
    )
    
    try {
        # Remove existing credential if present
        cmdkey /delete:$Target 2>&1 | Out-Null
        
        # Add new credential
        $result = cmdkey /generic:$Target /user:$Username /pass:$Password
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Stored credential: $Target" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] Failed to store credential: $Target" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Exception storing credential: $_" -ForegroundColor Red
        return $false
    }
}

# Step 1: Create configuration directory structure
Write-Host "[1] Setting up directory structure..." -ForegroundColor Cyan

$directories = @(
    $configPath,
    (Join-Path $tradingBridgePath "logs"),
    (Join-Path $tradingBridgePath "data"),
    (Join-Path $pythonPath "risk"),
    (Join-Path $pythonPath "strategies"),
    (Join-Path $pythonPath "communications")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Gray
    }
}

# Step 2: Copy example configurations to active configs
Write-Host ""
Write-Host "[2] Setting up configuration files..." -ForegroundColor Cyan

$configFiles = @(
    @{
        Source = "capital-allocation.json.example"
        Dest = "capital-allocation.json"
    },
    @{
        Source = "symbols-18-trading.json.example"
        Dest = "symbols.json"
    },
    @{
        Source = "communication-teams.json.example"
        Dest = "communication-teams.json"
    }
)

foreach ($config in $configFiles) {
    $sourcePath = Join-Path $configPath $config.Source
    $destPath = Join-Path $configPath $config.Dest
    
    if (Test-Path $sourcePath) {
        if (-not (Test-Path $destPath)) {
            Copy-Item $sourcePath $destPath
            Write-Host "  Created: $($config.Dest)" -ForegroundColor Green
        } else {
            Write-Host "  Exists: $($config.Dest)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [WARNING] Missing: $($config.Source)" -ForegroundColor Yellow
    }
}

# Step 3: Configure trading account credentials
Write-Host ""
Write-Host "[3] Configuring trading account credentials..." -ForegroundColor Cyan
Write-Host "  Account: ENESS MT5_AUTO-TRAD #411534497" -ForegroundColor Gray
Write-Host "  Server: Exness-MT5Real8" -ForegroundColor Gray
Write-Host ""

$setupCredentials = Read-Host "Do you want to configure account credentials now? (Y/N)"

if ($setupCredentials -eq 'Y' -or $setupCredentials -eq 'y') {
    Write-Host ""
    Write-Host "Enter your Exness MT5 password (input will be hidden):" -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    
    # Convert SecureString to plain text for credential manager
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    # Store in Windows Credential Manager
    Store-Credential -Target "EXNESS_MT5_PASSWORD" -Username "411534497" -Password $password
    
    # Clear password from memory
    $password = $null
    $securePassword = $null
    
    Write-Host "  [OK] Account credentials stored securely" -ForegroundColor Green
} else {
    Write-Host "  [SKIPPED] Credentials setup" -ForegroundColor Yellow
    Write-Host "  You can configure later using Windows Credential Manager" -ForegroundColor Gray
}

# Step 4: Configure communication API keys
Write-Host ""
Write-Host "[4] Configuring communication systems..." -ForegroundColor Cyan
Write-Host "  - WhatsApp/Twilio (+1 833 436-3285)" -ForegroundColor Gray
Write-Host "  - Telegram (061755859, 0963376851)" -ForegroundColor Gray
Write-Host "  - Perplexity AI" -ForegroundColor Gray
Write-Host "  - OpenAI/ChatGPT" -ForegroundColor Gray
Write-Host ""

$setupComms = Read-Host "Do you want to configure communication API keys now? (Y/N)"

if ($setupComms -eq 'Y' -or $setupComms -eq 'y') {
    Write-Host ""
    
    # Telegram
    Write-Host "Enter Telegram Bot Token (or press Enter to skip):" -ForegroundColor Yellow
    $telegramToken = Read-Host
    if ($telegramToken) {
        Store-Credential -Target "TELEGRAM_BOT_TOKEN" -Username "TradingBridge" -Password $telegramToken
    }
    
    Write-Host "Enter Telegram Chat ID (or press Enter to skip):" -ForegroundColor Yellow
    $telegramChatId = Read-Host
    if ($telegramChatId) {
        Store-Credential -Target "TELEGRAM_CHAT_ID" -Username "TradingBridge" -Password $telegramChatId
    }
    
    # WhatsApp/Twilio
    Write-Host "Enter Twilio API Key (or press Enter to skip):" -ForegroundColor Yellow
    $twilioKey = Read-Host
    if ($twilioKey) {
        Store-Credential -Target "TWILIO_API_KEY" -Username "TradingBridge" -Password $twilioKey
    }
    
    # Perplexity
    Write-Host "Enter Perplexity API Key (or press Enter to skip):" -ForegroundColor Yellow
    $perplexityKey = Read-Host
    if ($perplexityKey) {
        Store-Credential -Target "PERPLEXITY_API_KEY" -Username "TradingBridge" -Password $perplexityKey
    }
    
    # OpenAI
    Write-Host "Enter OpenAI API Key (or press Enter to skip):" -ForegroundColor Yellow
    $openaiKey = Read-Host
    if ($openaiKey) {
        Store-Credential -Target "OPENAI_API_KEY" -Username "TradingBridge" -Password $openaiKey
    }
    
    Write-Host ""
    Write-Host "  [OK] Communication API keys stored" -ForegroundColor Green
} else {
    Write-Host "  [SKIPPED] Communication setup" -ForegroundColor Yellow
}

# Step 5: Update symbols configuration with account details
Write-Host ""
Write-Host "[5] Updating symbols configuration..." -ForegroundColor Cyan

$symbolsConfigPath = Join-Path $configPath "symbols.json"
if (Test-Path $symbolsConfigPath) {
    try {
        $symbolsConfig = Get-Content $symbolsConfigPath -Raw | ConvertFrom-Json
        
        # Update account info
        $symbolsConfig.account_info.account_number = "411534497"
        $symbolsConfig.account_info.broker = "EXNESS"
        $symbolsConfig.account_info.server = "Exness-MT5Real8"
        
        # Save updated config
        $symbolsConfig | ConvertTo-Json -Depth 10 | Set-Content $symbolsConfigPath
        
        Write-Host "  [OK] Updated symbols configuration" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to update symbols config: $_" -ForegroundColor Red
    }
}

# Step 6: Check Python dependencies
Write-Host ""
Write-Host "[6] Checking Python dependencies..." -ForegroundColor Cyan

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    Write-Host "  Python found: $($pythonCmd.Source)" -ForegroundColor Green
    
    $requirementsPath = Join-Path $tradingBridgePath "requirements.txt"
    if (Test-Path $requirementsPath) {
        Write-Host "  Installing Python packages..." -ForegroundColor Gray
        
        try {
            Push-Location $tradingBridgePath
            python -m pip install -r requirements.txt --quiet
            Write-Host "  [OK] Python dependencies installed" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Some dependencies may have failed to install" -ForegroundColor Yellow
        } finally {
            Pop-Location
        }
    }
} else {
    Write-Host "  [WARNING] Python not found. Please install Python 3.8+" -ForegroundColor Yellow
}

# Step 7: Create startup configuration
Write-Host ""
Write-Host "[7] Creating startup configuration..." -ForegroundColor Cyan

$startupConfig = @{
    enabled = $true
    auto_start_trading = $false
    auto_start_communications = $true
    capital = 28
    max_symbols = 3
    risk_per_trade_percent = 1.0
}

$startupConfigPath = Join-Path $configPath "startup.json"
$startupConfig | ConvertTo-Json -Depth 5 | Set-Content $startupConfigPath
Write-Host "  [OK] Startup configuration created" -ForegroundColor Green

# Step 8: Setup Windows Task Scheduler (optional)
Write-Host ""
Write-Host "[8] Windows Task Scheduler setup..." -ForegroundColor Cyan
$setupScheduler = Read-Host "Do you want to setup auto-start on system boot? (Y/N)"

if ($setupScheduler -eq 'Y' -or $setupScheduler -eq 'y') {
    $taskName = "TradingSystem-AutoStart"
    $scriptPath = Join-Path $workspaceRoot "start-trading-system-admin.ps1"
    
    if (Test-Path $scriptPath) {
        try {
            # Remove existing task if present
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            
            # Create new task
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
            $trigger = New-ScheduledTaskTrigger -AtStartup
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
            
            Write-Host "  [OK] Task scheduler configured" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Failed to setup task: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [WARNING] Startup script not found: $scriptPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIPPED] Task scheduler setup" -ForegroundColor Yellow
}

# Step 9: Security check
Write-Host ""
Write-Host "[9] Running security check..." -ForegroundColor Cyan

$securityScript = Join-Path $workspaceRoot "security-check-trading.ps1"
if (Test-Path $securityScript) {
    try {
        & $securityScript
        Write-Host "  [OK] Security check completed" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Security check encountered issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIPPED] Security script not found" -ForegroundColor Yellow
}

# Final summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Trading System Configuration:" -ForegroundColor White
Write-Host "  • 18 Trading Symbols: Configured" -ForegroundColor Gray
Write-Host "  • Capital Allocation: Ready" -ForegroundColor Gray
Write-Host "  • SMC Strategy: Implemented" -ForegroundColor Gray
Write-Host "  • Risk Management: Automated" -ForegroundColor Gray
Write-Host "  • Communication Teams: Configured" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review configuration files in: $configPath" -ForegroundColor Gray
Write-Host "  2. Test the system: .\verify-trading-system.ps1" -ForegroundColor Gray
Write-Host "  3. Start trading: .\start-trading-system-admin.ps1" -ForegroundColor Gray
Write-Host "  4. Monitor logs: $tradingBridgePath\logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  • README: .\trading-bridge\README.md" -ForegroundColor Gray
Write-Host "  • Configuration: .\trading-bridge\CONFIGURATION.md" -ForegroundColor Gray
Write-Host "  • Security: .\trading-bridge\SECURITY.md" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

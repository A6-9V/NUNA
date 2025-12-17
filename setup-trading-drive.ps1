#Requires -Version 5.1
<#
.SYNOPSIS
    Trading Bridge Drive Setup
.DESCRIPTION
    Creates complete directory structure for trading bridge system
    Sets proper permissions and initializes required files
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading Bridge Drive Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"

# Create directory structure
Write-Host "[1/6] Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "trading-bridge",
    "trading-bridge\python\bridge",
    "trading-bridge\python\brokers",
    "trading-bridge\python\strategies",
    "trading-bridge\python\utils",
    "trading-bridge\python\services",
    "trading-bridge\python\security",
    "trading-bridge\python\trader",
    "trading-bridge\mql5\Experts",
    "trading-bridge\mql5\Scripts",
    "trading-bridge\mql5\Include",
    "trading-bridge\config",
    "trading-bridge\logs",
    "trading-bridge\data"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $workspaceRoot $dir
    try {
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Host "    [OK] Created: $dir" -ForegroundColor Green
        } else {
            Write-Host "    [OK] Exists: $dir" -ForegroundColor Green
        }
    } catch {
        Write-Host "    [ERROR] Failed to create: $dir - $_" -ForegroundColor Red
    }
}

Write-Host ""

# Set permissions on config and logs directories
Write-Host "[2/6] Setting directory permissions..." -ForegroundColor Yellow

try {
    $configPath = Join-Path $tradingBridgePath "config"
    $logsPath = Join-Path $tradingBridgePath "logs"
    
    # Restrict config directory (user-only read)
    if (Test-Path $configPath) {
        $acl = Get-Acl $configPath
        $acl.SetAccessRuleProtection($true, $false)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $env:USERNAME, "Read,Write", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($accessRule)
        Set-Acl $configPath $acl
        Write-Host "    [OK] Config directory permissions set" -ForegroundColor Green
    }
    
    # Logs directory permissions
    if (Test-Path $logsPath) {
        Write-Host "    [OK] Logs directory ready" -ForegroundColor Green
    }
} catch {
    Write-Host "    [WARNING] Could not set permissions (may require admin): $_" -ForegroundColor Yellow
}

Write-Host ""

# Create __init__.py files for Python packages
Write-Host "[3/6] Creating Python package files..." -ForegroundColor Yellow

$pythonPackages = @(
    "trading-bridge\python\__init__.py",
    "trading-bridge\python\bridge\__init__.py",
    "trading-bridge\python\brokers\__init__.py",
    "trading-bridge\python\strategies\__init__.py",
    "trading-bridge\python\utils\__init__.py",
    "trading-bridge\python\services\__init__.py",
    "trading-bridge\python\security\__init__.py",
    "trading-bridge\python\trader\__init__.py"
)

foreach ($package in $pythonPackages) {
    $fullPath = Join-Path $workspaceRoot $package
    try {
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType File -Path $fullPath -Force | Out-Null
            Write-Host "    [OK] Created: $package" -ForegroundColor Green
        }
    } catch {
        Write-Host "    [WARNING] Could not create: $package" -ForegroundColor Yellow
    }
}

Write-Host ""

# Create .gitkeep files for empty directories
Write-Host "[4/6] Creating .gitkeep files..." -ForegroundColor Yellow

$gitkeepDirs = @(
    "trading-bridge\logs",
    "trading-bridge\data"
)

foreach ($dir in $gitkeepDirs) {
    $fullPath = Join-Path $workspaceRoot "$dir\.gitkeep"
    try {
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType File -Path $fullPath -Force | Out-Null
            Write-Host "    [OK] Created .gitkeep in: $dir" -ForegroundColor Green
        }
    } catch {
        Write-Host "    [WARNING] Could not create .gitkeep in: $dir" -ForegroundColor Yellow
    }
}

Write-Host ""

# Check USB support
Write-Host "[5/6] Checking USB support..." -ForegroundColor Yellow

$usbSupportScript = Join-Path $workspaceRoot "vps-services\usb-support.ps1"
if (Test-Path $usbSupportScript) {
    try {
        . $usbSupportScript
        $usbDrive = Get-PreferredUSBDrive -MinFreeSpaceGB 5 -ErrorAction SilentlyContinue
        if ($usbDrive) {
            Write-Host "    [OK] USB drive available: $($usbDrive.DriveLetter)" -ForegroundColor Green
            
            # Create trading bridge backup on USB
            $usbTradingPath = Join-Path $usbDrive.Path "TradingBridge-Backup"
            if (-not (Test-Path $usbTradingPath)) {
                New-Item -ItemType Directory -Path $usbTradingPath -Force | Out-Null
                Write-Host "    [OK] Created USB backup directory" -ForegroundColor Green
            }
        } else {
            Write-Host "    [INFO] No suitable USB drive found (optional)" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "    [INFO] USB support not available (optional)" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] USB support script not found (optional)" -ForegroundColor Cyan
}

Write-Host ""

# Verify structure
Write-Host "[6/6] Verifying structure..." -ForegroundColor Yellow

$requiredDirs = @(
    "trading-bridge\python\bridge",
    "trading-bridge\python\brokers",
    "trading-bridge\config",
    "trading-bridge\logs"
)

$allExist = $true
foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $workspaceRoot $dir
    if (Test-Path $fullPath) {
        Write-Host "    [OK] $dir" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] $dir missing!" -ForegroundColor Red
        $allExist = $false
    }
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allExist) {
    Write-Host "Trading bridge directory structure is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Configure brokers.json (copy from brokers.json.example)" -ForegroundColor White
    Write-Host "  2. Install Python dependencies: pip install -r requirements.txt" -ForegroundColor White
    Write-Host "  3. Run security check: .\security-check-trading.ps1" -ForegroundColor White
    Write-Host "  4. Start trading system: .\start-trading-system-admin.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Some directories are missing. Please check errors above." -ForegroundColor Red
    Write-Host ""
    exit 1
}


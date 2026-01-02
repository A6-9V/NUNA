#Requires -RunAsAdministrator
<#
.SYNOPSIS
    VPS Deployment Script - Complete 24/7 Trading System Setup
.DESCRIPTION
    Deploys and configures all components for 24/7 trading system on VPS:
    - Exness MT5 Terminal (24/7)
    - Web research automation (Perplexity AI)
    - GitHub website deployment (ZOLO-A6-9VxNUNA)
    - Firefox automation
    - CI/CD automation
    - MQL5 Forge integration
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VPS Deployment - 24/7 Trading System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$workspaceRoot = "C:\Users\USER\OneDrive"
$vpsServicesPath = "$workspaceRoot\vps-services"
$logsPath = "$workspaceRoot\vps-logs"

# Create directories
Write-Host "[1/8] Creating VPS service directories..." -ForegroundColor Yellow
try {
    @($vpsServicesPath, $logsPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-Host "    [OK] Created: $_" -ForegroundColor Green
        } else {
            Write-Host "    [OK] Exists: $_" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "    [ERROR] Failed to create directories: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Setup Exness Trading Service
Write-Host "[2/8] Setting up Exness Trading service..." -ForegroundColor Yellow
try {
    $exnessServiceScript = @"
# Exness Trading Service - Runs 24/7
`$ErrorActionPreference = "Continue"
`$workspaceRoot = "$workspaceRoot"
Set-Location `$workspaceRoot

# Launch Exness Terminal
`$exnessPath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
if (Test-Path `$exnessPath) {
    `$process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not `$process) {
        Start-Process -FilePath `$exnessPath
        Start-Sleep -Seconds 5
        Write-Host "[`$(Get-Date)] Exness Terminal started" | Out-File -Append "$logsPath\exness-service.log"
    }
} else {
    Write-Host "[`$(Get-Date)] ERROR: Exness Terminal not found" | Out-File -Append "$logsPath\exness-service.log"
}

# Keep service running
while (`$true) {
    `$process = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
    if (-not `$process) {
        Start-Process -FilePath `$exnessPath
        Write-Host "[`$(Get-Date)] Restarted Exness Terminal" | Out-File -Append "$logsPath\exness-service.log"
    }
    Start-Sleep -Seconds 300  # Check every 5 minutes
}
"@
    
    $exnessServiceScript | Out-File -FilePath "$vpsServicesPath\exness-service.ps1" -Encoding UTF8
    Write-Host "    [OK] Exness service script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create Exness service: $_" -ForegroundColor Red
}

# Step 3: Setup Web Research Service (Perplexity AI)
Write-Host "[3/8] Setting up web research service (Perplexity AI)..." -ForegroundColor Yellow
try {
    $researchServiceScript = @"
# Web Research Service - Perplexity AI Finance Research
`$ErrorActionPreference = "Continue"
`$workspaceRoot = "$workspaceRoot"
`$logsPath = "$logsPath"

function Start-PerplexityResearch {
    param(
        [string]`$query = "finance trading market analysis"
    )
    
    `$firefoxPath = Get-Command firefox -ErrorAction SilentlyContinue
    if (-not `$firefoxPath) {
        `$firefoxPaths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
        foreach (`$path in `$firefoxPaths) {
            if (Test-Path `$path) {
                `$firefoxPath = `$path
                break
            }
        }
    } else {
        `$firefoxPath = `$firefoxPath.Source
    }
    
    if (`$firefoxPath) {
        `$url = "https://www.perplexity.ai/finance?q=" + [System.Web.HttpUtility]::UrlEncode(`$query)
        Start-Process -FilePath `$firefoxPath -ArgumentList `$url
        Write-Host "[`$(Get-Date)] Started Perplexity research: `$query" | Out-File -Append "`$logsPath\research-service.log"
    }
}

# Research schedule (every 6 hours)
while (`$true) {
    `$queries = @(
        "forex market analysis today",
        "trading opportunities EURUSD",
        "cryptocurrency market trends",
        "stock market analysis",
        "economic calendar events"
    )
    
    foreach (`$query in `$queries) {
        Start-PerplexityResearch -Query `$query
        Start-Sleep -Seconds 3600  # Wait 1 hour between queries
    }
    
    Start-Sleep -Seconds 21600  # Wait 6 hours before next cycle
}
"@
    
    $researchServiceScript | Out-File -FilePath "$vpsServicesPath\research-service.ps1" -Encoding UTF8
    Write-Host "    [OK] Research service script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create research service: $_" -ForegroundColor Red
}

# Step 4: Setup GitHub Website Service
Write-Host "[4/8] Setting up GitHub website service..." -ForegroundColor Yellow
try {
    $websiteServiceScript = @"
# GitHub Website Service - ZOLO-A6-9VxNUNA
`$ErrorActionPreference = "Continue"
`$workspaceRoot = "$workspaceRoot"
`$websitePath = "`$workspaceRoot\ZOLO-A6-9VxNUNA"
`$logsPath = "$logsPath"

# Clone or update repository
if (-not (Test-Path `$websitePath)) {
    Write-Host "[`$(Get-Date)] Cloning ZOLO-A6-9VxNUNA repository..." | Out-File -Append "`$logsPath\website-service.log"
    Set-Location `$workspaceRoot
    git clone git@github.com:Mouy-leng/ZOLO-A6-9VxNUNA-.git `$websitePath 2>&1 | Out-File -Append "`$logsPath\website-service.log"
} else {
    Write-Host "[`$(Get-Date)] Updating ZOLO-A6-9VxNUNA repository..." | Out-File -Append "`$logsPath\website-service.log"
    Set-Location `$websitePath
    git pull origin main 2>&1 | Out-File -Append "`$logsPath\website-service.log"
}

# Launch website in Firefox
`$firefoxPath = Get-Command firefox -ErrorAction SilentlyContinue
if (-not `$firefoxPath) {
    `$firefoxPaths = @(
        "C:\Program Files\Mozilla Firefox\firefox.exe",
        "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
    )
    foreach (`$path in `$firefoxPaths) {
        if (Test-Path `$path) {
            `$firefoxPath = `$path
            break
        }
    }
} else {
    `$firefoxPath = `$firefoxPath.Source
}

if (`$firefoxPath) {
    # Check if local server is running, if not start it
    `$pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if (`$pythonPath) {
        Set-Location `$websitePath
        # Try to start Python web server
        Start-Process python -ArgumentList "-m", "http.server", "8000" -WindowStyle Hidden
        Start-Sleep -Seconds 2
        Start-Process -FilePath `$firefoxPath -ArgumentList "http://localhost:8000"
        Write-Host "[`$(Get-Date)] Website launched in Firefox" | Out-File -Append "`$logsPath\website-service.log"
    }
}

# Keep service running
while (`$true) {
    Start-Sleep -Seconds 3600  # Check every hour
    Set-Location `$websitePath
    git pull origin main 2>&1 | Out-File -Append "`$logsPath\website-service.log"
}
"@
    
    $websiteServiceScript | Out-File -FilePath "$vpsServicesPath\website-service.ps1" -Encoding UTF8
    Write-Host "    [OK] Website service script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create website service: $_" -ForegroundColor Red
}

# Step 5: Setup CI/CD Automation
Write-Host "[5/8] Setting up CI/CD automation..." -ForegroundColor Yellow
try {
    $cicdServiceScript = @"
# CI/CD Automation Service
`$ErrorActionPreference = "Continue"
`$workspaceRoot = "$workspaceRoot"
`$logsPath = "$logsPath"

function Run-CICDPipeline {
    param([string]`$repoPath, [string]`$repoName)
    
    Set-Location `$repoPath
    
    # Pull latest changes
    git pull origin main 2>&1 | Out-File -Append "`$logsPath\cicd-service.log"
    
    # Check for Python projects and run them
    `$pythonFiles = Get-ChildItem -Path `$repoPath -Filter "*.py" -Recurse -ErrorAction SilentlyContinue
    if (`$pythonFiles) {
        foreach (`$pyFile in `$pythonFiles) {
            Write-Host "[`$(Get-Date)] Running: `$(`$pyFile.Name)" | Out-File -Append "`$logsPath\cicd-service.log"
            Start-Process python -ArgumentList `$pyFile.FullName -WindowStyle Hidden
        }
    }
    
    # Check for requirements.txt and install dependencies
    `$requirements = Get-ChildItem -Path `$repoPath -Filter "requirements.txt" -Recurse -ErrorAction SilentlyContinue
    if (`$requirements) {
        foreach (`$req in `$requirements) {
            pip install -r `$req.FullName 2>&1 | Out-File -Append "`$logsPath\cicd-service.log"
        }
    }
}

# Monitor repositories
`$repos = @(
    @{Path="`$workspaceRoot\ZOLO-A6-9VxNUNA"; Name="ZOLO-A6-9VxNUNA"},
    @{Path="`$workspaceRoot\my-drive-projects"; Name="my-drive-projects"}
)

while (`$true) {
    foreach (`$repo in `$repos) {
        if (Test-Path `$repo.Path) {
            Run-CICDPipeline -RepoPath `$repo.Path -RepoName `$repo.Name
        }
    }
    Start-Sleep -Seconds 1800  # Run every 30 minutes
}
"@
    
    $cicdServiceScript | Out-File -FilePath "$vpsServicesPath\cicd-service.ps1" -Encoding UTF8
    Write-Host "    [OK] CI/CD service script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create CI/CD service: $_" -ForegroundColor Red
}

# Step 6: Setup MQL5 Forge Integration
Write-Host "[6/8] Setting up MQL5 Forge integration..." -ForegroundColor Yellow
try {
    $mql5ServiceScript = @"
# MQL5 Forge Integration Service
`$ErrorActionPreference = "Continue"
`$workspaceRoot = "$workspaceRoot"
`$logsPath = "$logsPath"
`$mql5ForgeUrl = "https://forge.mql5.io/LengKundee/mql5"

# Monitor MQL5 Forge and sync with local
function Sync-MQL5Forge {
    `$firefoxPath = Get-Command firefox -ErrorAction SilentlyContinue
    if (-not `$firefoxPath) {
        `$firefoxPaths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
        foreach (`$path in `$firefoxPaths) {
            if (Test-Path `$path) {
                `$firefoxPath = `$path
                break
            }
        }
    } else {
        `$firefoxPath = `$firefoxPath.Source
    }
    
    if (`$firefoxPath) {
        Start-Process -FilePath `$firefoxPath -ArgumentList `$mql5ForgeUrl
        Write-Host "[`$(Get-Date)] Opened MQL5 Forge" | Out-File -Append "`$logsPath\mql5-service.log"
    }
}

# Run sync every 12 hours
while (`$true) {
    Sync-MQL5Forge
    Start-Sleep -Seconds 43200  # Wait 12 hours
}
"@
    
    $mql5ServiceScript | Out-File -FilePath "$vpsServicesPath\mql5-service.ps1" -Encoding UTF8
    Write-Host "    [OK] MQL5 Forge service script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create MQL5 service: $_" -ForegroundColor Red
}

# Step 7: Create Master Service Controller
Write-Host "[7/8] Creating master service controller..." -ForegroundColor Yellow
try {
    $masterControllerScript = @"
#Requires -RunAsAdministrator
# Master Service Controller - Manages all 24/7 services
`$ErrorActionPreference = "Continue"
`$workspaceRoot = "$workspaceRoot"
`$vpsServicesPath = "$vpsServicesPath"
`$logsPath = "$logsPath"

function Start-VPSService {
    param([string]`$ServiceName, [string]`$ScriptPath)

    if (-not (Test-Path `$ScriptPath)) {
        Write-Host "[`$(Get-Date)] WARNING: Service script not found: `$ServiceName (`$ScriptPath)" | Out-File -Append "`$logsPath\master-controller.log"
        return
    }

    `$alreadyRunning = `$false
    try {
        `$procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue
        foreach (`$p in (`$procs | Where-Object { `$_.CommandLine })) {
            if (`$p.CommandLine -like "*`$ScriptPath*" -or `$p.CommandLine -like "*`$ServiceName*") {
                `$alreadyRunning = `$true
                break
            }
        }
    } catch {
        `$alreadyRunning = `$false
    }

    if (-not `$alreadyRunning) {
        Start-Process powershell.exe -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", `$ScriptPath
        ) -WindowStyle Hidden
        Write-Host "[`$(Get-Date)] Started service: `$ServiceName" | Out-File -Append "`$logsPath\master-controller.log"
    }
}

# Start all services
Start-VPSService -ServiceName "exness-service" -ScriptPath "`$vpsServicesPath\exness-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "research-service" -ScriptPath "`$vpsServicesPath\research-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "website-service" -ScriptPath "`$vpsServicesPath\website-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "cicd-service" -ScriptPath "`$vpsServicesPath\cicd-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "mql5-service" -ScriptPath "`$vpsServicesPath\mql5-service.ps1"
Start-Sleep -Seconds 2

Start-VPSService -ServiceName "trading-bridge-service" -ScriptPath "`$vpsServicesPath\trading-bridge-service.ps1"

Write-Host "[`$(Get-Date)] All services started" | Out-File -Append "`$logsPath\master-controller.log"

# Monitor services
while (`$true) {
    Start-Sleep -Seconds 300  # Check every 5 minutes
    # Restart any stopped services
    Start-VPSService -ServiceName "exness-service" -ScriptPath "`$vpsServicesPath\exness-service.ps1"
    Start-VPSService -ServiceName "research-service" -ScriptPath "`$vpsServicesPath\research-service.ps1"
    Start-VPSService -ServiceName "website-service" -ScriptPath "`$vpsServicesPath\website-service.ps1"
    Start-VPSService -ServiceName "cicd-service" -ScriptPath "`$vpsServicesPath\cicd-service.ps1"
    Start-VPSService -ServiceName "mql5-service" -ScriptPath "`$vpsServicesPath\mql5-service.ps1"
    Start-VPSService -ServiceName "trading-bridge-service" -ScriptPath "`$vpsServicesPath\trading-bridge-service.ps1"
}
"@
    
    $masterControllerScript | Out-File -FilePath "$vpsServicesPath\master-controller.ps1" -Encoding UTF8
    Write-Host "    [OK] Master controller script created" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to create master controller: $_" -ForegroundColor Red
}

# Step 8: Create Scheduled Task for Auto-Start
Write-Host "[8/8] Creating Windows Scheduled Task for auto-start..." -ForegroundColor Yellow
try {
    $taskName = "VPS-Trading-System-24-7"
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$vpsServicesPath\master-controller.ps1`"" `
        -WorkingDirectory $workspaceRoot
    
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Highest
    
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    Register-ScheduledTask -TaskName $taskName -Action $taskAction `
        -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings `
        -Description "24/7 Trading System - Auto-start on boot" -Force | Out-Null
    
    Write-Host "    [OK] Scheduled task created: $taskName" -ForegroundColor Green
} catch {
    Write-Host "    [WARNING] Failed to create scheduled task: $_" -ForegroundColor Yellow
    Write-Host "    [INFO] You can create it manually or run master-controller.ps1 on startup" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VPS Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services created:" -ForegroundColor Yellow
Write-Host "  [OK] Exness Trading Service" -ForegroundColor White
Write-Host "  [OK] Web Research Service (Perplexity AI)" -ForegroundColor White
Write-Host "  [OK] GitHub Website Service (ZOLO-A6-9VxNUNA)" -ForegroundColor White
Write-Host "  [OK] CI/CD Automation Service" -ForegroundColor White
Write-Host "  [OK] MQL5 Forge Integration Service" -ForegroundColor White
Write-Host "  [OK] Master Controller" -ForegroundColor White
Write-Host ""
Write-Host "To start all services:" -ForegroundColor Cyan
Write-Host "  powershell.exe -ExecutionPolicy Bypass -File `"$vpsServicesPath\master-controller.ps1`"" -ForegroundColor White
Write-Host ""
Write-Host "Service location: $vpsServicesPath" -ForegroundColor Cyan
Write-Host "Logs location: $logsPath" -ForegroundColor Cyan
Write-Host ""

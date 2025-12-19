#Requires -Version 5.1
<#
.SYNOPSIS
    Launch GitHub Repository for Exness Trading Terminal
.DESCRIPTION
    This script clones/pulls a GitHub repository and launches Exness MT5 terminal
    to start automated trading.
#>

param(
    # MT5 trading account number (not secret)
    [Parameter(Mandatory = $false)]
    [string]$Account,

    # MT5 server name (not secret), e.g. "Exness-MT5Real8"
    [Parameter(Mandatory = $false)]
    [string]$Server,

    # MT5 profile name/folder to load on startup (not secret)
    [Parameter(Mandatory = $false)]
    [string]$Profile,

    # Optional: password for auto-login. If not provided, terminal will be launched without auto-login.
    # IMPORTANT: Passing passwords on the command line is insecure; this script prefers a temporary config file.
    [Parameter(Mandatory = $false)]
    [SecureString]$Password,

    # Optional: env var name to read password from (fallback). Value is never printed.
    [Parameter(Mandatory = $false)]
    [string]$PasswordEnvVar = "EXNESS_MT5_PASSWORD",

    # If set, the script will prompt for password (secure prompt) when Account+Server provided but password missing.
    # Default is off to keep automation non-interactive.
    [Parameter(Mandatory = $false)]
    [switch]$PromptForPassword,

    # Skip cloning/pulling repos and MQL file discovery (faster launch).
    [Parameter(Mandatory = $false)]
    [switch]$SkipRepoSetup,

    # Skip opening folders in Explorer at the end.
    [Parameter(Mandatory = $false)]
    [switch]$SkipFolderOpen
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Exness Trading Launcher" -ForegroundColor Cyan
Write-Host "  GitHub Repository + MT5 Terminal" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$mql5RepoUrl = "https://forge.mql5.io/LengKundee/mql5.git"
$mql5RepoName = "mql5-repo"
$repoUrl = "https://github.com/A6-9V/my-drive-projects.git"
$repoName = "my-drive-projects"
$clonePath = "C:\Users\USER\OneDrive"
$mql5ConfigFile = Join-Path $clonePath "mql5-config.txt"
$mql5RepoFullPath = Join-Path $clonePath $mql5RepoName
$repoFullPath = Join-Path $clonePath $repoName

# Load MQL5 API Token
$mql5ApiToken = $null
if (Test-Path $mql5ConfigFile) {
    $configContent = Get-Content $mql5ConfigFile -ErrorAction SilentlyContinue
    $tokenLine = $configContent | Where-Object { $_ -match "^MQL5_API=" }
    if ($tokenLine) {
        $mql5ApiToken = ($tokenLine -split "=")[1].Trim()
    }
}
$exnessBasePath = "C:\Program Files\MetaTrader 5 EXNESS"
$exnessTerminalPath = "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
$exnessPaths = @(
    "C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe",
    "$env:LOCALAPPDATA\Programs\Exness Terminal\terminal64.exe",
    "$env:PROGRAMFILES\Exness Terminal\terminal64.exe",
    "$env:PROGRAMFILES(X86)\Exness Terminal\terminal64.exe",
    "$env:APPDATA\Exness Terminal\terminal64.exe",
    "$env:USERPROFILE\AppData\Local\Programs\Exness Terminal\terminal64.exe",
    "$env:USERPROFILE\AppData\Roaming\Exness Terminal\terminal64.exe"
)

function ConvertTo-PlainText {
    param([SecureString]$Secure)
    if (-not $Secure) { return $null }
    try {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        if ($bstr -and $bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function New-Mt5TempConfigFile {
    param(
        [Parameter(Mandatory = $true)][string]$Login,
        [Parameter(Mandatory = $true)][string]$ServerName,
        [Parameter(Mandatory = $true)][SecureString]$SecurePassword
    )

    $plainPassword = ConvertTo-PlainText -Secure $SecurePassword
    if (-not $plainPassword) { return $null }

    $fileName = "mt5-launch-$([Guid]::NewGuid().ToString('N')).ini"
    $tempPath = Join-Path $env:TEMP $fileName

    # Minimal INI format commonly supported by MetaTrader terminals for /config:
    $content = @"
[Common]
Login=$Login
Password=$plainPassword
Server=$ServerName
"@

    try {
        New-Item -ItemType File -Path $tempPath -Force | Out-Null
        Set-Content -Path $tempPath -Value $content -Encoding ASCII -Force

        # Best-effort: restrict file ACLs to current user only (may fail on some systems/policies)
        try {
            $currentUser = "$env:USERDOMAIN\$env:USERNAME"
            icacls $tempPath /inheritance:r /grant:r "$currentUser:(R,W)" /c | Out-Null
        } catch {
            # Non-fatal
        }

        return $tempPath
    } catch {
        Write-Host "    [WARNING] Could not create temporary MT5 config file: $_" -ForegroundColor Yellow
        return $null
    } finally {
        # Reduce lifetime of plaintext password in memory
        $plainPassword = $null
    }
}

# Step 1: Clone/Pull MQL5 Forge Repository
if (-not $SkipRepoSetup) {
    Write-Host "[1/5] Setting up MQL5 Forge repository..." -ForegroundColor Yellow
    try {
    
        if (Test-Path $mql5RepoFullPath) {
            Write-Host "    [INFO] MQL5 repository already exists, pulling latest changes..." -ForegroundColor Cyan
            Set-Location $mql5RepoFullPath
        
            # Configure git with token if available
            if ($mql5ApiToken) {
                $repoUrlWithToken = $mql5RepoUrl -replace "https://", "https://$mql5ApiToken@"
                git remote set-url origin $repoUrlWithToken 2>&1 | Out-Null
            }
        
            git pull origin main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] MQL5 repository updated successfully" -ForegroundColor Green
            }
            else {
                Write-Host "    [WARNING] Could not pull MQL5 updates, using existing version" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "    [INFO] Cloning MQL5 repository..." -ForegroundColor Cyan
            Set-Location $clonePath
        
            # Clone with token if available
            if ($mql5ApiToken) {
                $repoUrlWithToken = $mql5RepoUrl -replace "https://", "https://$mql5ApiToken@"
                git clone $repoUrlWithToken $mql5RepoName 2>&1 | Out-Null
            }
            else {
                git clone $mql5RepoUrl $mql5RepoName 2>&1 | Out-Null
            }
        
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] MQL5 repository cloned successfully" -ForegroundColor Green
            }
            else {
                Write-Host "    [ERROR] Failed to clone MQL5 repository" -ForegroundColor Red
                Write-Host "    [INFO] Continuing without MQL5 repository..." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "    [WARNING] MQL5 repository setup failed: $_" -ForegroundColor Yellow
        Write-Host "    [INFO] Continuing without MQL5 repository..." -ForegroundColor Yellow
    }
} else {
    Write-Host "[1/5] Skipping repository setup (SkipRepoSetup enabled)" -ForegroundColor Yellow
}

# Step 1b: Clone/Pull GitHub Repository (optional)
if (-not $SkipRepoSetup) {
    Write-Host "[1b/5] Setting up GitHub repository (optional)..." -ForegroundColor Yellow
    try {
    
        if (Test-Path $repoFullPath) {
            Write-Host "    [INFO] GitHub repository already exists, pulling latest changes..." -ForegroundColor Cyan
            Set-Location $repoFullPath
            git pull origin main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] GitHub repository updated successfully" -ForegroundColor Green
            }
            else {
                Write-Host "    [WARNING] Could not pull GitHub updates, using existing version" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "    [INFO] GitHub repository not found, skipping..." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "    [WARNING] GitHub repository setup failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[1b/5] Skipping GitHub repository setup (SkipRepoSetup enabled)" -ForegroundColor Yellow
}

# Step 2: Find Exness MT5 Terminal
Write-Host "[2/5] Locating Exness MT5 Terminal..." -ForegroundColor Yellow
$exnessPath = $null

# Check primary installation path first
if (Test-Path $exnessTerminalPath) {
    $exnessPath = $exnessTerminalPath
    Write-Host "    [OK] Found Exness Terminal at primary location: $exnessPath" -ForegroundColor Green
}
else {
    # Fallback to other locations
    foreach ($path in $exnessPaths) {
        if (Test-Path $path) {
            $exnessPath = $path
            Write-Host "    [OK] Found Exness Terminal: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $exnessPath) {
        Write-Host "    [WARNING] Exness Terminal not found in standard locations" -ForegroundColor Yellow
        Write-Host "    [INFO] Searching for terminal64.exe..." -ForegroundColor Cyan
        
        # Search in common locations
        $searchPaths = @(
            "$env:USERPROFILE",
            "$env:PROGRAMFILES",
            "$env:LOCALAPPDATA"
        )
        
        foreach ($searchPath in $searchPaths) {
            if (Test-Path $searchPath) {
                $found = Get-ChildItem -Path $searchPath -Filter "terminal64.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $exnessPath = $found.FullName
                    Write-Host "    [OK] Found Exness Terminal: $exnessPath" -ForegroundColor Green
                    break
                }
            }
        }
    }
}

if (-not $exnessPath) {
    Write-Host "    [ERROR] Exness Terminal not found" -ForegroundColor Red
    Write-Host "    [INFO] Expected location: C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe" -ForegroundColor Yellow
    Write-Host "    [INFO] Please install Exness Terminal from: https://www.exness.com/" -ForegroundColor Yellow
    Write-Host "    [ERROR] Cannot proceed without Exness Terminal" -ForegroundColor Red
    exit 1
}

# Step 3: Launch Exness Terminal
Write-Host "[3/5] Launching Exness MT5 Terminal..." -ForegroundColor Yellow
try {
    if (Test-Path $exnessPath) {
        $exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
        
        if (-not $exnessProcess) {
            Write-Host "    [INFO] Starting Exness Terminal..." -ForegroundColor Cyan
            $argumentList = @()

            # Profile support (optional)
            if ($Profile) {
                $argumentList += "/profile:$Profile"
            }

            # Password retrieval (optional, never printed)
            if (-not $Password -and $PasswordEnvVar) {
                try {
                    $envValue = [Environment]::GetEnvironmentVariable($PasswordEnvVar, "Process")
                    if (-not $envValue) {
                        $envValue = [Environment]::GetEnvironmentVariable($PasswordEnvVar, "User")
                    }
                    if (-not $envValue) {
                        $envValue = [Environment]::GetEnvironmentVariable($PasswordEnvVar, "Machine")
                    }

                    if ($envValue) {
                        $Password = ConvertTo-SecureString -String $envValue -AsPlainText -Force
                    }
                } catch {
                    # Non-fatal
                } finally {
                    $envValue = $null
                }
            }

            if ($Account -and $Server -and -not $Password -and $PromptForPassword) {
                try {
                    $Password = Read-Host "Enter MT5 password (hidden input)" -AsSecureString
                } catch {
                    # Non-fatal
                }
            }

            # Auto-login support (optional)
            $tempConfigPath = $null
            if ($Account -and $Server -and $Password) {
                $tempConfigPath = New-Mt5TempConfigFile -Login $Account -ServerName $Server -SecurePassword $Password
                if ($tempConfigPath) {
                    $argumentList += "/config:$tempConfigPath"
                } else {
                    Write-Host "    [WARNING] Auto-login config could not be created; launching terminal without auto-login" -ForegroundColor Yellow
                }
            } elseif ($Account -or $Server) {
                Write-Host "    [WARNING] Account/Server provided but no password available; launching terminal without auto-login" -ForegroundColor Yellow
            }

            Start-Process -FilePath $exnessPath -ArgumentList $argumentList -ErrorAction Stop
            Start-Sleep -Seconds 3
            
            $exnessProcess = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
            if ($exnessProcess) {
                Write-Host "    [OK] Exness Terminal launched successfully" -ForegroundColor Green
                if ($tempConfigPath) {
                    # Best-effort cleanup: remove temp config file after launch
                    try {
                        Remove-Item -Path $tempConfigPath -Force -ErrorAction SilentlyContinue
                    } catch {
                        # Non-fatal
                    }
                }
            }
            else {
                Write-Host "    [WARNING] Terminal process not detected, but launch command executed" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "    [OK] Exness Terminal is already running" -ForegroundColor Green
        }
    }
    else {
        Write-Host "    [ERROR] Exness Terminal executable not found at: $exnessPath" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "    [ERROR] Failed to launch Exness Terminal: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Check MQL5 Files
if (-not $SkipRepoSetup) {
    Write-Host "[4/5] Checking MQL5 files..." -ForegroundColor Yellow
    try {
    
        if (Test-Path $mql5RepoFullPath) {
            Set-Location $mql5RepoFullPath
        
            # Look for MQL5 files
            $mql5Files = Get-ChildItem -Path $mql5RepoFullPath -Filter "*.mq5" -Recurse -ErrorAction SilentlyContinue
            $mql4Files = Get-ChildItem -Path $mql5RepoFullPath -Filter "*.mq4" -Recurse -ErrorAction SilentlyContinue
        
            if ($mql5Files -or $mql4Files) {
                Write-Host "    [OK] Found MQL5/MQL4 files:" -ForegroundColor Green
                if ($mql5Files) {
                    Write-Host "      MQL5 files: $($mql5Files.Count)" -ForegroundColor Cyan
                }
                if ($mql4Files) {
                    Write-Host "      MQL4 files: $($mql4Files.Count)" -ForegroundColor Cyan
                }
                Write-Host "    [INFO] MQL5 repository location: $mql5RepoFullPath" -ForegroundColor Cyan
            }
            else {
                Write-Host "    [INFO] No MQL5/MQL4 files found in repository" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "    [WARNING] MQL5 repository path not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "    [WARNING] Could not check MQL5 files: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[4/5] Skipping MQL5 file scan (SkipRepoSetup enabled)" -ForegroundColor Yellow
}

# Step 5: Navigate to Trading Scripts
if (-not $SkipRepoSetup) {
    Write-Host "[5/5] Setting up trading environment..." -ForegroundColor Yellow
    try {
    
        if (Test-Path $repoFullPath) {
            Set-Location $repoFullPath
        
            # Look for trading-related scripts
            $tradingScripts = @(
                "start_live_trading.bat",
                "live_trading_system.py",
                "trading_system.py",
                "run_trading.ps1",
                "launch_trading.bat"
            )
        
            $foundScript = $null
            foreach ($script in $tradingScripts) {
                $scriptPath = Get-ChildItem -Path $repoFullPath -Filter $script -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($scriptPath) {
                    $foundScript = $scriptPath.FullName
                    Write-Host "    [OK] Found trading script: $script" -ForegroundColor Green
                    break
                }
            }
        
            if ($foundScript) {
                Write-Host "    [INFO] Trading script location: $foundScript" -ForegroundColor Cyan
                Write-Host "    [INFO] You can run it manually or it may auto-start" -ForegroundColor Cyan
            }
            else {
                Write-Host "    [INFO] No trading scripts found in GitHub repository" -ForegroundColor Yellow
                Write-Host "    [INFO] Repository location: $repoFullPath" -ForegroundColor Cyan
            }
        
            Write-Host "    [OK] Trading environment ready" -ForegroundColor Green
        }
        else {
            Write-Host "    [WARNING] GitHub repository path not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "    [WARNING] Could not set up trading environment: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[5/5] Skipping trading environment setup (SkipRepoSetup enabled)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Launch Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status:" -ForegroundColor Yellow
if (Test-Path $mql5RepoFullPath) {
    Write-Host "  [OK] MQL5 Repository: $mql5RepoFullPath" -ForegroundColor White
}
if (Test-Path $repoFullPath) {
    Write-Host "  [OK] GitHub Repository: $repoFullPath" -ForegroundColor White
}
Write-Host "  [OK] Exness Terminal: $exnessPath" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Log in to Exness Terminal if not already logged in" -ForegroundColor White
Write-Host "  2. Ensure your trading account is connected" -ForegroundColor White
Write-Host "  3. Check MQL5 files in: $mql5RepoFullPath" -ForegroundColor White
Write-Host "  4. Run your trading scripts from the repositories" -ForegroundColor White
Write-Host "  5. Monitor trading activity in the terminal" -ForegroundColor White
Write-Host ""
if (Test-Path $mql5RepoFullPath) {
    Write-Host "MQL5 Repository location: $mql5RepoFullPath" -ForegroundColor Cyan
}
if (Test-Path $repoFullPath) {
    Write-Host "GitHub Repository location: $repoFullPath" -ForegroundColor Cyan
}
Write-Host ""

# Open repository folders
if (-not $SkipFolderOpen) {
    try {
        if (Test-Path $mql5RepoFullPath) {
            Write-Host "Opening MQL5 repository folder..." -ForegroundColor Cyan
            Start-Process explorer.exe -ArgumentList $mql5RepoFullPath
        }
        if (Test-Path $repoFullPath) {
            Write-Host "Opening GitHub repository folder..." -ForegroundColor Cyan
            Start-Process explorer.exe -ArgumentList $repoFullPath
        }
    }
    catch {
        Write-Host "[WARNING] Could not open repository folder(s)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green

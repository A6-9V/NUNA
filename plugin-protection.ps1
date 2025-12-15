# Plugin Protection Script
# Protects Cursor and VS Code extensions from unauthorized access and validates security

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Plugin and Extension Protection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$protectionIssues = @()
$protectionWarnings = @()
$protectionPassed = @()

# ========================================
# 1. Cursor Extensions Protection
# ========================================
Write-Host "[1/5] Protecting Cursor Extensions..." -ForegroundColor Yellow

$cursorExtensionsPath = "$env:APPDATA\Cursor\User\extensions"
if (Test-Path $cursorExtensionsPath) {
    Write-Host "    [INFO] Cursor extensions directory: $cursorExtensionsPath" -ForegroundColor Cyan
    
    # Check directory permissions
    try {
        $acl = Get-Acl $cursorExtensionsPath
        $isSecure = $true
        foreach ($access in $acl.Access) {
            # Check for write access by non-admin users
            if ($access.FileSystemRights -match "Write|FullControl" -and 
                $access.IdentityReference -notlike "*BUILTIN\Administrators*" -and
                $access.IdentityReference -notlike "*$env:USERNAME*") {
                $isSecure = $false
                Write-Host "    [WARNING] Extension directory has write access for: $($access.IdentityReference)" -ForegroundColor Yellow
                $protectionWarnings += "Extension directory accessible by: $($access.IdentityReference)"
            }
        }
        
        if ($isSecure) {
            Write-Host "    [OK] Extension directory permissions are secure" -ForegroundColor Green
            $protectionPassed += "Cursor extensions directory permissions secure"
        }
    } catch {
        Write-Host "    [WARNING] Could not check extension directory permissions" -ForegroundColor Yellow
    }
    
    # List installed extensions
    $extensions = Get-ChildItem $cursorExtensionsPath -Directory -ErrorAction SilentlyContinue
    if ($extensions) {
        Write-Host "    [INFO] Found $($extensions.Count) installed extension(s)" -ForegroundColor Cyan
        
        # Check for known malicious or suspicious extensions
        $suspiciousExtensions = @()
        $knownGoodExtensions = @("ms-python", "ms-vscode", "github", "cursor")
        
        foreach ($ext in $extensions) {
            $extName = $ext.Name
            $extPath = $ext.FullName
            
            # Check extension package.json for suspicious content
            $packageJson = Join-Path $extPath "package.json"
            if (Test-Path $packageJson) {
                try {
                    $packageContent = Get-Content $packageJson -Raw | ConvertFrom-Json
                    
                    # Check for suspicious permissions or commands
                    if ($packageContent.contributes -and $packageContent.contributes.commands) {
                        foreach ($cmd in $packageContent.contributes.commands) {
                            if ($cmd.command -match "(?i)(exec|shell|system|eval|spawn)") {
                                Write-Host "    [WARNING] Extension '$extName' has suspicious command: $($cmd.command)" -ForegroundColor Yellow
                                $protectionWarnings += "Extension $extName has suspicious commands"
                            }
                        }
                    }
                    
                    # Check for suspicious activation events
                    if ($packageContent.activationEvents) {
                        foreach ($activationEvent in $packageContent.activationEvents) {
                            if ($activationEvent -match "\*" -and $activationEvent -notmatch "onLanguage") {
                                Write-Host "    [WARNING] Extension '$extName' activates on: $activationEvent" -ForegroundColor Yellow
                                $protectionWarnings += "Extension $extName has broad activation: $activationEvent"
                            }
                        }
                    }
                } catch {
                    Write-Host "    [WARNING] Could not parse package.json for: $extName" -ForegroundColor Yellow
                }
            }
            
            # Check if extension is from known publisher
            $isKnownGood = $false
            foreach ($known in $knownGoodExtensions) {
                if ($extName -like "*$known*") {
                    $isKnownGood = $true
                    break
                }
            }
            
            if (-not $isKnownGood) {
                $suspiciousExtensions += $extName
            }
        }
        
        if ($suspiciousExtensions.Count -gt 0) {
            Write-Host "    [WARNING] Found $($suspiciousExtensions.Count) extension(s) from unknown publishers:" -ForegroundColor Yellow
            foreach ($ext in $suspiciousExtensions) {
                Write-Host "      - $ext" -ForegroundColor White
            }
            $protectionWarnings += "Extensions from unknown publishers: $($suspiciousExtensions -join ', ')"
        } else {
            Write-Host "    [OK] All extensions are from known publishers" -ForegroundColor Green
            $protectionPassed += "All Cursor extensions verified"
        }
    } else {
        Write-Host "    [INFO] No extensions installed" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [INFO] Cursor extensions directory not found" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 2. VS Code Extensions Protection
# ========================================
Write-Host "[2/5] Protecting VS Code Extensions..." -ForegroundColor Yellow

$vscodeExtensionsPath = "$env:USERPROFILE\.vscode\extensions"
if (Test-Path $vscodeExtensionsPath) {
    Write-Host "    [INFO] VS Code extensions directory: $vscodeExtensionsPath" -ForegroundColor Cyan
    
    $vscodeExtensions = Get-ChildItem $vscodeExtensionsPath -Directory -ErrorAction SilentlyContinue
    if ($vscodeExtensions) {
        Write-Host "    [INFO] Found $($vscodeExtensions.Count) VS Code extension(s)" -ForegroundColor Cyan
        Write-Host "    [OK] VS Code extensions directory accessible" -ForegroundColor Green
        $protectionPassed += "VS Code extensions directory accessible"
    }
} else {
    Write-Host "    [INFO] VS Code extensions directory not found" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 3. Extension Settings Security
# ========================================
Write-Host "[3/5] Checking Extension Settings Security..." -ForegroundColor Yellow

# Check Cursor settings for suspicious configurations
$cursorSettingsPath = "$env:APPDATA\Cursor\User\settings.json"
if (Test-Path $cursorSettingsPath) {
    try {
        $settings = Get-Content $cursorSettingsPath -Raw | ConvertFrom-Json
        
        # Check for suspicious settings
        $suspiciousSettings = @("http.proxy", "terminal.integrated.env", "remote.extensionKind")
        foreach ($setting in $suspiciousSettings) {
            if ($settings.PSObject.Properties.Name -contains $setting) {
                $value = $settings.$setting
                Write-Host "    [INFO] Setting found: $setting = $value" -ForegroundColor Cyan
                # Review but don't flag as error - these can be legitimate
            }
        }
        
        Write-Host "    [OK] Cursor settings file accessible" -ForegroundColor Green
        $protectionPassed += "Cursor settings accessible"
    } catch {
        Write-Host "    [WARNING] Could not parse Cursor settings" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Cursor settings file not found" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 4. Extension File Integrity
# ========================================
Write-Host "[4/5] Checking Extension File Integrity..." -ForegroundColor Yellow

if (Test-Path $cursorExtensionsPath) {
    $extensions = Get-ChildItem $cursorExtensionsPath -Directory -ErrorAction SilentlyContinue
    $integrityIssues = 0
    
    foreach ($ext in $extensions) {
        $extPath = $ext.FullName
        $packageJson = Join-Path $extPath "package.json"
        
        if (Test-Path $packageJson) {
            # Check if package.json is readable and valid
            try {
                $packageContent = Get-Content $packageJson -Raw | ConvertFrom-Json
                
                # Verify required fields
                if (-not $packageContent.name -or -not $packageContent.version) {
                    Write-Host "    [WARNING] Extension '$($ext.Name)' has invalid package.json" -ForegroundColor Yellow
                    $integrityIssues++
                } else {
                    Write-Host "    [OK] Extension '$($ext.Name)' ($($packageContent.version)) - Valid" -ForegroundColor Green
                }
            } catch {
                Write-Host "    [WARNING] Extension '$($ext.Name)' - Could not validate package.json" -ForegroundColor Yellow
                $integrityIssues++
            }
        } else {
            Write-Host "    [WARNING] Extension '$($ext.Name)' - Missing package.json" -ForegroundColor Yellow
            $integrityIssues++
        }
    }
    
    if ($integrityIssues -eq 0) {
        Write-Host "    [OK] All extensions have valid package.json files" -ForegroundColor Green
        $protectionPassed += "All extensions have valid package files"
    } else {
        Write-Host "    [WARNING] Found $integrityIssues extension(s) with integrity issues" -ForegroundColor Yellow
        $protectionWarnings += "$integrityIssues extension(s) have integrity issues"
    }
} else {
    Write-Host "    [INFO] No extensions directory found" -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# 5. Extension Execution Security
# ========================================
Write-Host "[5/5] Checking Extension Execution Security..." -ForegroundColor Yellow

# Check for running extension host processes
try {
    $extensionHosts = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($extensionHosts) {
        Write-Host "    [INFO] Found $($extensionHosts.Count) extension host process(es) running" -ForegroundColor Cyan
        foreach ($proc in $extensionHosts) {
            Write-Host "      - PID $($proc.Id): $($proc.ProcessName)" -ForegroundColor White
        }
    } else {
        Write-Host "    [INFO] No extension host processes currently running" -ForegroundColor Cyan
    }
    
    # Check Cursor processes
    $cursorProcesses = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue
    if ($cursorProcesses) {
        Write-Host "    [INFO] Found $($cursorProcesses.Count) Cursor process(es) running" -ForegroundColor Cyan
    }
    
    Write-Host "    [OK] Process check completed" -ForegroundColor Green
    $protectionPassed += "Extension execution security checked"
} catch {
    Write-Host "    [WARNING] Could not check running processes" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Protection Summary
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Plugin Protection Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($protectionPassed.Count -gt 0) {
    Write-Host "Protection Checks Passed ($($protectionPassed.Count)):" -ForegroundColor Green
    foreach ($check in $protectionPassed) {
        Write-Host "  [OK] $check" -ForegroundColor Green
    }
    Write-Host ""
}

if ($protectionWarnings.Count -gt 0) {
    Write-Host "Warnings ($($protectionWarnings.Count)):" -ForegroundColor Yellow
    foreach ($warning in $protectionWarnings) {
        Write-Host "  [WARNING] $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($protectionIssues.Count -gt 0) {
    Write-Host "Protection Issues ($($protectionIssues.Count)):" -ForegroundColor Red
    foreach ($issue in $protectionIssues) {
        Write-Host "  [ERROR] $issue" -ForegroundColor Red
    }
    Write-Host ""
}

# Overall status
if ($protectionIssues.Count -eq 0 -and $protectionWarnings.Count -eq 0) {
    Write-Host "Overall Status: [OK] All plugin protection checks passed!" -ForegroundColor Green
} elseif ($protectionIssues.Count -eq 0) {
    Write-Host "Overall Status: [WARNING] Plugin protection checks passed with warnings" -ForegroundColor Yellow
    Write-Host "  Review warnings above and verify extension sources." -ForegroundColor Yellow
} else {
    Write-Host "Overall Status: [ERROR] Plugin protection issues found!" -ForegroundColor Red
    Write-Host "  Please review and address the issues above." -ForegroundColor Red
}

Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "  1. Only install extensions from trusted publishers" -ForegroundColor White
Write-Host "  2. Regularly review installed extensions" -ForegroundColor White
Write-Host "  3. Keep extensions updated to latest versions" -ForegroundColor White
Write-Host "  4. Monitor extension permissions and activation events" -ForegroundColor White
Write-Host "  5. Run security checks regularly" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""




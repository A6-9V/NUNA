# Complete ASUS PC Setup Script
# Runs all setup components in sequence

param(
    [switch]$DryRun,
    [switch]$SkipCleanup,
    [switch]$SkipRegistry,
    [switch]$SkipDriveRoles,
    # Back-compat: skips only Cursor-specific config (kept for older callers)
    [switch]$SkipCursor,

    # Optional editor targeting:
    # - cursor: apply settings + MCP config to Cursor
    # - vscode: apply settings to VS Code (UI)
    # - both: apply settings to both (MCP only for Cursor)
    # - none: skip editor config completely
    [ValidateSet('cursor','vscode','both','none')]
    [string]$EditorTarget = 'cursor'
)

# Requires Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    exit 1
}

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ASUS PC Complete Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Resolve editor toggles
$configureCursor = ($EditorTarget -in @('cursor','both')) -and (-not $SkipCursor)
$configureVSCode = ($EditorTarget -in @('vscode','both'))

# Step 1: Drive Cleanup
if (-not $SkipCleanup) {
    Write-Host "Step 1: Cleaning up all drives..." -ForegroundColor Yellow
    $cleanupScript = Join-Path $scriptDir "cleanup-all-drives.ps1"
    if (Test-Path $cleanupScript) {
        & $cleanupScript -DryRun:$DryRun
    } else {
        Write-Host "  ⚠ Cleanup script not found: $cleanupScript" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 2: Apply Drive Roles
if (-not $SkipDriveRoles) {
    Write-Host "Step 2: Applying drive roles and permissions..." -ForegroundColor Yellow
    $driveRolesScript = Join-Path $scriptDir "apply-drive-roles.ps1"
    if (Test-Path $driveRolesScript) {
        & $driveRolesScript -DryRun:$DryRun
    } else {
        Write-Host "  ⚠ Drive roles script not found: $driveRolesScript" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 3: Registry Settings
if (-not $SkipRegistry) {
    Write-Host "Step 3: Applying registry settings..." -ForegroundColor Yellow
    $registryScript = Join-Path $scriptDir "apply-registry-settings.ps1"
    if (Test-Path $registryScript) {
        & $registryScript -DryRun:$DryRun
    } else {
        Write-Host "  ⚠ Registry script not found: $registryScript" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 4: Editor Configuration (optional)
if ($EditorTarget -ne 'none') {
    Write-Host "Step 4: Configuring Editor Settings..." -ForegroundColor Yellow
    $baseSettingsPath = Join-Path $scriptDir "cursor-settings.json"

    if (-not (Test-Path $baseSettingsPath)) {
        Write-Host "  ⚠ Settings file not found: $baseSettingsPath" -ForegroundColor Yellow
        Write-Host ""
    } else {
        # Load settings once (used for VS Code filtering)
        $baseSettings = $null
        try {
            $baseSettings = Get-Content $baseSettingsPath -Raw | ConvertFrom-Json
        } catch {
            Write-Host "  ✗ Failed to parse settings JSON: $($_.Exception.Message)" -ForegroundColor Red
        }

        if ($configureCursor) {
            Write-Host "  - Cursor IDE" -ForegroundColor Cyan
            $cursorTarget = "$env:APPDATA\Cursor\User\settings.json"
            try {
                if (-not $DryRun) {
                    if (Test-Path $cursorTarget) {
                        Copy-Item $cursorTarget "$cursorTarget.backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')" -ErrorAction SilentlyContinue
                    }
                    $cursorDir = Split-Path $cursorTarget
                    if (-not (Test-Path $cursorDir)) {
                        New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null
                    }
                    Copy-Item $baseSettingsPath $cursorTarget -Force
                    Write-Host "    ✓ Cursor settings applied" -ForegroundColor Green
                } else {
                    Write-Host "    [DRY RUN] Would copy settings to: $cursorTarget" -ForegroundColor Gray
                }
            } catch {
                Write-Host "    ✗ Failed to apply Cursor settings: $($_.Exception.Message)" -ForegroundColor Red
            }
        } elseif ($SkipCursor -and ($EditorTarget -in @('cursor','both'))) {
            Write-Host "  - Cursor IDE" -ForegroundColor Cyan
            Write-Host "    [INFO] Skipped (requested via -SkipCursor)" -ForegroundColor Gray
        }

        if ($configureVSCode) {
            Write-Host "  - VS Code (UI)" -ForegroundColor Cyan
            $vscodeTarget = "$env:APPDATA\Code\User\settings.json"
            try {
                if (-not $DryRun) {
                    if (Test-Path $vscodeTarget) {
                        Copy-Item $vscodeTarget "$vscodeTarget.backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')" -ErrorAction SilentlyContinue
                    }
                    $vscodeDir = Split-Path $vscodeTarget
                    if (-not (Test-Path $vscodeDir)) {
                        New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
                    }

                    # VS Code doesn't natively use Cursor MCP keys; remove any "mcp.*" or "cursor.*" keys.
                    if ($baseSettings) {
                        foreach ($prop in @($baseSettings.PSObject.Properties.Name)) {
                            if ($prop -like 'mcp.*' -or $prop -like 'cursor.*') {
                                $baseSettings.PSObject.Properties.Remove($prop) | Out-Null
                            }
                        }
                        ($baseSettings | ConvertTo-Json -Depth 20) | Set-Content -Path $vscodeTarget -Encoding UTF8
                        Write-Host "    ✓ VS Code settings applied (Cursor-only keys removed)" -ForegroundColor Green
                    } else {
                        # Fallback: copy as-is if parsing failed
                        Copy-Item $baseSettingsPath $vscodeTarget -Force
                        Write-Host "    ✓ VS Code settings applied (copied as-is)" -ForegroundColor Green
                    }
                } else {
                    Write-Host "    [DRY RUN] Would write settings to: $vscodeTarget" -ForegroundColor Gray
                }
            } catch {
                Write-Host "    ✗ Failed to apply VS Code settings: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        Write-Host ""
    }
}

# Step 5: MCP Configuration
Write-Host "Step 5: Configuring MCP..." -ForegroundColor Yellow
if ($configureCursor) {
    $mcpConfig = Join-Path $scriptDir "mcp-config.json"
    $mcpTarget = "$env:APPDATA\Cursor\User\globalStorage\mcp.json"

    if (Test-Path $mcpConfig) {
        try {
            if (-not $DryRun) {
                $mcpDir = Split-Path $mcpTarget
                if (-not (Test-Path $mcpDir)) {
                    New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null
                }

                Copy-Item $mcpConfig $mcpTarget -Force
                Write-Host "  ✓ MCP configuration applied (Cursor)" -ForegroundColor Green
                Write-Host "  ⚠ Remember to add your GitHub token in: $mcpTarget" -ForegroundColor Yellow
            } else {
                Write-Host "  [DRY RUN] Would copy MCP config to: $mcpTarget" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  ✗ Failed to apply MCP config: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠ MCP config file not found: $mcpConfig" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [INFO] Skipped (MCP config currently applies to Cursor only)" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "⚠️ DRY RUN MODE - No changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes`n" -ForegroundColor Yellow
}

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review ASUS-PC-SETUP.md for detailed documentation" -ForegroundColor White
Write-Host "  2. Add GitHub token to MCP config if using GitHub integration" -ForegroundColor White
if ($configureCursor) {
    Write-Host "  3. Restart Cursor IDE to apply settings" -ForegroundColor White
} elseif ($configureVSCode) {
    Write-Host "  3. Restart VS Code to apply settings" -ForegroundColor White
} else {
    Write-Host "  3. (No editor configured)" -ForegroundColor White
}
Write-Host "  4. Test the project scanner: cd D:\my-drive-projects\project-scanner && .\run-all-projects.ps1" -ForegroundColor White
Write-Host ""


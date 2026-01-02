#Requires -Version 5.1
<#
.SYNOPSIS
    Network Location Mapping Setup
.DESCRIPTION
    Maps network drives and UNC paths for PC and network access
    Supports persistent mappings, credentials, and error handling
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Network Location Mapping Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$networkConfigPath = Join-Path $workspaceRoot "network-config.json"

# Network locations configuration
$networkConfig = @{
    "mappings" = @(
        @{
            "drive_letter" = "Z:"
            "unc_path" = "\\SERVER-NAME\SharedFolder"
            "description" = "Main Network Share"
            "persistent" = $true
            "credentials" = $null  # Will be stored in Credential Manager
        }
    ),
    "unc_paths" = @(
        @{
            "name" = "VPS-Share"
            "path" = "\\VPS-IP\Share"
            "description" = "VPS Network Share"
            "credentials" = $null
        }
    ),
    "network_resources" = @(
        @{
            "name" = "Network-PC"
            "ip_address" = "192.168.1.100"
            "description" = "Local Network PC"
            "ports" = @(445, 3389)  # SMB, RDP
        }
    )
}

# Save configuration template
if (-not (Test-Path $networkConfigPath)) {
    $networkConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $networkConfigPath -Encoding UTF8
    Write-Host "[OK] Created network configuration template: $networkConfigPath" -ForegroundColor Green
    Write-Host "    Edit this file to configure your network mappings" -ForegroundColor Cyan
} else {
    Write-Host "[INFO] Network configuration exists: $networkConfigPath" -ForegroundColor Yellow
    $networkConfig = Get-Content $networkConfigPath -Raw | ConvertFrom-Json
}

# Function to map network drive
function Map-NetworkDrive {
    param(
        [string]$DriveLetter,
        [string]$UNCPath,
        [string]$Username = $null,
        [string]$Password = $null,
        [bool]$Persistent = $true
    )
    
    try {
        # Check if drive already mapped
        $existing = Get-PSDrive -Name $DriveLetter.TrimEnd(':') -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Host "    [INFO] Drive $DriveLetter already mapped" -ForegroundColor Yellow
            return $true
        }
        
        # Test network path
        if (-not (Test-Path $UNCPath)) {
            Write-Host "    [WARNING] Cannot access $UNCPath - may need credentials" -ForegroundColor Yellow
        }
        
        # Map drive
        if ($Username -and $Password) {
            $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
            New-PSDrive -Name $DriveLetter.TrimEnd(':') -PSProvider FileSystem -Root $UNCPath -Credential $credential -Persist:$Persistent | Out-Null
        } else {
            New-PSDrive -Name $DriveLetter.TrimEnd(':') -PSProvider FileSystem -Root $UNCPath -Persist:$Persistent | Out-Null
        }
        
        Write-Host "    [OK] Mapped $DriveLetter to $UNCPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    [ERROR] Failed to map $DriveLetter: $_" -ForegroundColor Red
        return $false
    }
}

# Function to test network connection
function Test-NetworkConnection {
    param(
        [string]$ComputerName,
        [int[]]$Ports = @(445, 3389, 80, 443)
    )
    
    Write-Host "    Testing connection to $ComputerName..." -ForegroundColor Cyan
    
    $results = @{}
    foreach ($port in $Ports) {
        try {
            $test = Test-NetConnection -ComputerName $ComputerName -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
            $results[$port] = $test
            if ($test) {
                Write-Host "      [OK] Port $port is open" -ForegroundColor Green
            } else {
                Write-Host "      [INFO] Port $port is closed" -ForegroundColor Yellow
            }
        } catch {
            $results[$port] = $false
            Write-Host "      [WARNING] Could not test port $port" -ForegroundColor Yellow
        }
    }
    
    return $results
}

# Process network mappings
Write-Host "[1/3] Processing network drive mappings..." -ForegroundColor Yellow

if ($networkConfig.mappings) {
    foreach ($mapping in $networkConfig.mappings) {
        $driveLetter = $mapping.drive_letter
        $uncPath = $mapping.unc_path
        $persistent = if ($mapping.persistent -ne $null) { $mapping.persistent } else { $true }
        
        Write-Host "  Mapping $driveLetter to $uncPath..." -ForegroundColor Cyan
        
        # Get credentials from Credential Manager if needed
        $username = $null
        $password = $null
        
        if ($mapping.credentials) {
            $credName = "NetworkDrive_$($driveLetter.TrimEnd(':'))"
            try {
                $cred = cmdkey /list:$credName 2>&1
                # Extract credentials (simplified - use proper method)
            } catch {
                Write-Host "    [INFO] No stored credentials found" -ForegroundColor Cyan
            }
        }
        
        Map-NetworkDrive -DriveLetter $driveLetter -UNCPath $uncPath -Persistent $persistent
    }
} else {
    Write-Host "  [INFO] No drive mappings configured" -ForegroundColor Cyan
}

# Test network resources
Write-Host "[2/3] Testing network resources..." -ForegroundColor Yellow

if ($networkConfig.network_resources) {
    foreach ($resource in $networkConfig.network_resources) {
        Write-Host "  Testing $($resource.name) ($($resource.ip_address))..." -ForegroundColor Cyan
        $ports = if ($resource.ports) { $resource.ports } else { @(445, 3389) }
        Test-NetworkConnection -ComputerName $resource.ip_address -Ports $ports
    }
} else {
    Write-Host "  [INFO] No network resources configured" -ForegroundColor Cyan
}

# Create network shortcuts
Write-Host "[3/3] Creating network shortcuts..." -ForegroundColor Yellow

$shortcutsPath = Join-Path $workspaceRoot "Network-Shortcuts"
if (-not (Test-Path $shortcutsPath)) {
    New-Item -ItemType Directory -Path $shortcutsPath -Force | Out-Null
}

if ($networkConfig.unc_paths) {
    foreach ($unc in $networkConfig.unc_paths) {
        $shortcutPath = Join-Path $shortcutsPath "$($unc.name).lnk"
        try {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $unc.path
            $Shortcut.Description = $unc.description
            $Shortcut.Save()
            Write-Host "    [OK] Created shortcut: $($unc.name)" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Could not create shortcut for $($unc.name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Network Mapping Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration: $networkConfigPath" -ForegroundColor Cyan
Write-Host "Shortcuts: $shortcutsPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "To add network mappings:" -ForegroundColor Yellow
Write-Host "  1. Edit $networkConfigPath" -ForegroundColor White
Write-Host "  2. Run this script again" -ForegroundColor White
Write-Host ""


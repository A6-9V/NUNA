#Requires -Version 5.1
<#
.SYNOPSIS
    Check Network and Firewall Configuration
.DESCRIPTION
    Verifies network connectivity and firewall settings
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Network and Firewall Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Network Adapters
Write-Host "[1/5] Checking Network Adapters..." -ForegroundColor Yellow
try {
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object Name, InterfaceDescription, LinkSpeed, Status
    if ($adapters) {
        Write-Host "    [OK] Active network adapters:" -ForegroundColor Green
        foreach ($adapter in $adapters) {
            Write-Host ("      - " + $adapter.Name + " (" + $adapter.LinkSpeed + ")") -ForegroundColor Cyan
        }
    } else {
        Write-Host "    [WARNING] No active network adapters found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [ERROR] Could not check adapters: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[2/5] Checking IP Configuration..." -ForegroundColor Yellow
try {
    $ipConfig = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1
    if ($ipConfig) {
        Write-Host ("    [OK] IP Address: " + $ipConfig.IPAddress) -ForegroundColor Green
        Write-Host ("    [OK] Subnet Mask: " + $ipConfig.PrefixLength) -ForegroundColor Green
        $gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gateway) {
            Write-Host ("    [OK] Default Gateway: " + $gateway.NextHop) -ForegroundColor Green
        }
    } else {
        Write-Host "    [WARNING] No valid IP address found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [ERROR] Could not check IP config: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[3/5] Testing Internet Connectivity..." -ForegroundColor Yellow
try {
    $test1 = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
    $test2 = Test-NetConnection -ComputerName "google.com" -Port 80 -InformationLevel Quiet -WarningAction SilentlyContinue
    
    if ($test1) {
        Write-Host "    [OK] Internet connectivity: Working (DNS)" -ForegroundColor Green
    } else {
        Write-Host "    [WARNING] DNS connectivity test failed" -ForegroundColor Yellow
    }
    
    if ($test2) {
        Write-Host "    [OK] Internet connectivity: Working (HTTP)" -ForegroundColor Green
    } else {
        Write-Host "    [WARNING] HTTP connectivity test failed" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [WARNING] Connectivity test had issues: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[4/5] Checking Windows Firewall..." -ForegroundColor Yellow
try {
    $firewallProfiles = Get-NetFirewallProfile
    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "Enabled" } else { "Disabled" }
        $color = if ($profile.Enabled) { "Green" } else { "Yellow" }
        Write-Host ("    [$status] " + $profile.Name + " profile") -ForegroundColor $color
    }
    
    # Check important firewall rules
    Write-Host ""
    Write-Host "    Checking important firewall rules..." -ForegroundColor Cyan
    $importantRules = @("Remote Desktop", "File and Printer Sharing", "Windows Remote Management")
    foreach ($ruleGroup in $importantRules) {
        $rules = Get-NetFirewallRule -DisplayGroup $ruleGroup -ErrorAction SilentlyContinue | Where-Object {$_.Enabled -eq $true}
        if ($rules) {
            Write-Host ("      [OK] " + $ruleGroup + ": " + $rules.Count + " rule(s) enabled") -ForegroundColor Green
        } else {
            Write-Host ("      [INFO] " + $ruleGroup + ": No enabled rules") -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "    [ERROR] Could not check firewall: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[5/5] Checking DNS Configuration..." -ForegroundColor Yellow
try {
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.ServerAddresses.Count -gt 0} | Select-Object -First 1
    if ($dnsServers) {
        Write-Host "    [OK] DNS Servers configured:" -ForegroundColor Green
        foreach ($dns in $dnsServers.ServerAddresses) {
            Write-Host ("      - " + $dns) -ForegroundColor Cyan
        }
    } else {
        Write-Host "    [WARNING] No DNS servers configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [WARNING] Could not check DNS: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Network and Firewall Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


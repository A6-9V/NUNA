# Domain Controller Synchronization Script
# Run this script as Administrator on your Domain Controller
# Created: November 7, 2025

param(
    [switch]$CheckOnly,
    [switch]$ForceSync,
    [switch]$RestartServices,
    [string]$LogPath = "C:\Temp\DC-Sync-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
)

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Create log directory
$logDir = Split-Path $LogPath -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    $logMessage | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Test-DomainController {
    Write-Log "=== DOMAIN CONTROLLER VERIFICATION ===" "Cyan"
    
    # Check if this is a domain controller
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $domainRole = $computerSystem.DomainRole
    
    Write-Log "Computer Name: $($computerSystem.Name)"
    Write-Log "Domain: $($computerSystem.Domain)"
    Write-Log "Domain Role: $domainRole"
    
    # Domain Role values: 0=Standalone Workstation, 1=Member Workstation, 2=Standalone Server, 3=Member Server, 4=Backup Domain Controller, 5=Primary Domain Controller
    if ($domainRole -lt 4) {
        Write-Log "ERROR: This machine is not a Domain Controller (Role: $domainRole)" "Red"
        Write-Log "Domain Roles: 0=Standalone WS, 1=Member WS, 2=Standalone Server, 3=Member Server, 4=Backup DC, 5=Primary DC" "Yellow"
        return $false
    }
    
    Write-Log "✅ Confirmed: This is a Domain Controller" "Green"
    return $true
}

function Test-ADServices {
    Write-Log "`n=== ACTIVE DIRECTORY SERVICES CHECK ===" "Cyan"
    
    $criticalServices = @("NTDS", "DNS", "W32Time", "Kdc", "ADWS")
    $serviceStatus = @{}
    
    foreach ($service in $criticalServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                $serviceStatus[$service] = $svc.Status
                $color = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
                Write-Log "$service Service: $($svc.Status)" $color
            } else {
                $serviceStatus[$service] = "Not Found"
                Write-Log "$service Service: Not Found" "Yellow"
            }
        } catch {
            $serviceStatus[$service] = "Error"
            Write-Log "$service Service: Error checking - $($_.Exception.Message)" "Red"
        }
    }
    
    return $serviceStatus
}

function Test-TimeSync {
    Write-Log "`n=== WINDOWS TIME SERVICE CHECK ===" "Cyan"
    
    try {
        $w32tmStatus = w32tm /query /status 2>&1
        Write-Log "W32Time Status:"
        $w32tmStatus | ForEach-Object { Write-Log "  $_" }
        
        # Check if time is in sync
        if ($w32tmStatus -like "*Last Successful Sync Time*") {
            Write-Log "✅ Time service appears to be working" "Green"
            return $true
        } else {
            Write-Log "⚠️ Time service may have issues" "Yellow"
            return $false
        }
    } catch {
        Write-Log "❌ Error checking time status: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Test-Replication {
    Write-Log "`n=== ACTIVE DIRECTORY REPLICATION CHECK ===" "Cyan"
    
    try {
        Write-Log "Running replication summary..."
        $replSummary = repadmin /replsummary 2>&1
        Write-Log "Replication Summary:"
        $replSummary | ForEach-Object { Write-Log "  $_" }
        
        # Check for errors in replication
        $errors = $replSummary | Where-Object { $_ -like "*error*" -or $_ -like "*fail*" }
        if ($errors) {
            Write-Log "⚠️ Replication errors detected:" "Yellow"
            $errors | ForEach-Object { Write-Log "  ERROR: $_" "Red" }
            return $false
        } else {
            Write-Log "✅ No obvious replication errors found" "Green"
            return $true
        }
    } catch {
        Write-Log "❌ Error checking replication: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Test-DCHealth {
    Write-Log "`n=== DOMAIN CONTROLLER HEALTH CHECK ===" "Cyan"
    
    try {
        Write-Log "Running DC diagnostics (this may take a few minutes)..."
        $dcdiag = dcdiag /v /c 2>&1
        Write-Log "DC Diagnostics Results:"
        $dcdiag | ForEach-Object { Write-Log "  $_" }
        
        # Check for failed tests
        $failures = $dcdiag | Where-Object { $_ -like "*failed*" }
        if ($failures) {
            Write-Log "⚠️ DC diagnostic failures detected:" "Yellow"
            $failures | ForEach-Object { Write-Log "  FAILURE: $_" "Red" }
            return $false
        } else {
            Write-Log "✅ DC diagnostics completed successfully" "Green"
            return $true
        }
    } catch {
        Write-Log "❌ Error running DC diagnostics: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Invoke-TimeSync {
    Write-Log "`n=== SYNCHRONIZING TIME SERVICE ===" "Cyan"
    
    try {
        Write-Log "Restarting Windows Time service..."
        Stop-Service W32Time -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Service W32Time
        
        Write-Log "Forcing time resynchronization..."
        $resync = w32tm /resync /rediscover 2>&1
        Write-Log "Resync Results:"
        $resync | ForEach-Object { Write-Log "  $_" }
        
        Write-Log "✅ Time synchronization completed" "Green"
        return $true
    } catch {
        Write-Log "❌ Error during time sync: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Invoke-ADReplication {
    Write-Log "`n=== FORCING ACTIVE DIRECTORY REPLICATION ===" "Cyan"
    
    try {
        Write-Log "Forcing replication to all partners..."
        $syncall = repadmin /syncall /AeD 2>&1
        Write-Log "Sync All Results:"
        $syncall | ForEach-Object { Write-Log "  $_" }
        
        Write-Log "Waiting 10 seconds for replication to process..."
        Start-Sleep -Seconds 10
        
        Write-Log "Checking replication status after sync..."
        $postSyncSummary = repadmin /replsummary 2>&1
        Write-Log "Post-Sync Replication Summary:"
        $postSyncSummary | ForEach-Object { Write-Log "  $_" }
        
        Write-Log "✅ AD replication sync completed" "Green"
        return $true
    } catch {
        Write-Log "❌ Error during AD replication: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Restart-ADServices {
    Write-Log "`n=== RESTARTING ACTIVE DIRECTORY SERVICES ===" "Cyan"
    
    $servicesToRestart = @("NTDS", "DNS", "W32Time")
    
    foreach ($service in $servicesToRestart) {
        try {
            Write-Log "Restarting $service service..."
            Restart-Service $service -Force
            Write-Log "✅ $service service restarted successfully" "Green"
        } catch {
            Write-Log "❌ Error restarting $service: $($_.Exception.Message)" "Red"
        }
    }
}

# Main execution
Write-Log "=== DOMAIN CONTROLLER SYNC SCRIPT STARTED ===" "Green"
Write-Log "Script started at: $(Get-Date)"
Write-Log "Log file: $LogPath"
Write-Log "Parameters: CheckOnly=$CheckOnly, ForceSync=$ForceSync, RestartServices=$RestartServices"

# Step 1: Verify this is a domain controller
if (-not (Test-DomainController)) {
    Write-Log "SCRIPT TERMINATED: Not running on a Domain Controller" "Red"
    exit 1
}

# Step 2: Check AD services
$serviceStatus = Test-ADServices

# Step 3: Check time sync
$timeOK = Test-TimeSync

# Step 4: Check replication
$replOK = Test-Replication

# Step 5: Check DC health
$healthOK = Test-DCHealth

# Summary of checks
Write-Log "`n=== HEALTH CHECK SUMMARY ===" "Cyan"
Write-Log "Time Service: $(if($timeOK){'✅ OK'}else{'❌ Issues'})"
Write-Log "Replication: $(if($replOK){'✅ OK'}else{'❌ Issues'})"
Write-Log "DC Health: $(if($healthOK){'✅ OK'}else{'❌ Issues'})"

# If CheckOnly mode, exit here
if ($CheckOnly) {
    Write-Log "`n=== CHECK-ONLY MODE COMPLETE ===" "Green"
    Write-Log "To perform synchronization, run with -ForceSync parameter"
    exit 0
}

# Perform synchronization if requested
if ($ForceSync) {
    Write-Log "`n=== STARTING SYNCHRONIZATION PROCEDURES ===" "Yellow"
    
    # Sync time if there were issues
    if (-not $timeOK) {
        Write-Log "Time service had issues, attempting to fix..."
        Invoke-TimeSync
    }
    
    # Force AD replication
    if (-not $replOK) {
        Write-Log "Replication had issues, forcing sync..."
        Invoke-ADReplication
    } else {
        Write-Log "Replication was OK, but forcing sync anyway as requested..."
        Invoke-ADReplication
    }
    
    # Restart services if requested
    if ($RestartServices) {
        Write-Log "Restarting services as requested..."
        Restart-ADServices
    }
    
    Write-Log "`n=== SYNCHRONIZATION COMPLETE ===" "Green"
} else {
    Write-Log "`n=== CHECKS COMPLETE ===" "Yellow"
    Write-Log "To perform synchronization, run with -ForceSync parameter"
    Write-Log "To restart services, add -RestartServices parameter"
}

Write-Log "`n=== SCRIPT COMPLETED ===" "Green"
Write-Log "Script ended at: $(Get-Date)"
Write-Log "Full log saved to: $LogPath"

# Display quick usage guide
Write-Host "`n=== USAGE EXAMPLES ===" -ForegroundColor Cyan
Write-Host "Check only (safe):         .\DC-Sync.ps1 -CheckOnly" -ForegroundColor White
Write-Host "Check and sync:            .\DC-Sync.ps1 -ForceSync" -ForegroundColor White
Write-Host "Full sync with restart:    .\DC-Sync.ps1 -ForceSync -RestartServices" -ForegroundColor White
Write-Host "Custom log location:       .\DC-Sync.ps1 -CheckOnly -LogPath C:\MyLogs\dc.log" -ForegroundColor White
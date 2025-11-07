# DC Script Transfer Helper
# Run this on your current machine to prepare transfer to Domain Controller

param(
    [Parameter(Mandatory=$true)]
    [string]$TransferMethod,
    [string]$DCName = "",
    [string]$USBDrive = "E:",
    [string]$DestinationPath = "C:\Scripts"
)

Write-Host "=== DC SCRIPT TRANSFER HELPER ===" -ForegroundColor Green
Write-Host "Transfer Method: $TransferMethod" -ForegroundColor Cyan

$scriptPath = "H:\My Drive\storage-management\DC-Sync.ps1"
$guidePath = "H:\My Drive\storage-management\DC-Sync-Guide.md"

# Verify source files exist
if (!(Test-Path $scriptPath)) {
    Write-Host "ERROR: DC-Sync.ps1 not found at $scriptPath" -ForegroundColor Red
    exit 1
}

switch ($TransferMethod.ToLower()) {
    "usb" {
        Write-Host "`n--- USB TRANSFER ---" -ForegroundColor Yellow
        
        # Check if USB drive exists
        if (!(Test-Path "$USBDrive\")) {
            Write-Host "ERROR: USB drive $USBDrive not found" -ForegroundColor Red
            Write-Host "Available drives:" -ForegroundColor Yellow
            Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 2} | Select-Object DeviceID, VolumeName
            exit 1
        }
        
        try {
            Write-Host "Copying DC-Sync.ps1 to $USBDrive..." -ForegroundColor Cyan
            Copy-Item $scriptPath "$USBDrive\DC-Sync.ps1" -Force
            
            Write-Host "Copying guide to $USBDrive..." -ForegroundColor Cyan  
            Copy-Item $guidePath "$USBDrive\DC-Sync-Guide.md" -Force
            
            Write-Host "✅ Files copied to USB successfully!" -ForegroundColor Green
            Write-Host "`nNext steps:" -ForegroundColor Yellow
            Write-Host "1. Take USB to Domain Controller" -ForegroundColor White
            Write-Host "2. Copy files: Copy-Item 'E:\DC-Sync.ps1' 'C:\Scripts\DC-Sync.ps1'" -ForegroundColor White
            Write-Host "3. Run: .\DC-Sync.ps1 -CheckOnly" -ForegroundColor White
            
        } catch {
            Write-Host "ERROR: Failed to copy to USB - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "network" {
        Write-Host "`n--- NETWORK TRANSFER ---" -ForegroundColor Yellow
        
        if ($DCName -eq "") {
            Write-Host "ERROR: DCName parameter required for network transfer" -ForegroundColor Red
            Write-Host "Usage: .\Transfer-Helper.ps1 -TransferMethod network -DCName YOUR-DC-NAME" -ForegroundColor Yellow
            exit 1
        }
        
        $networkPath = "\\$DCName\C$\Scripts"
        
        try {
            Write-Host "Testing connection to $DCName..." -ForegroundColor Cyan
            Test-NetConnection $DCName -Port 445 -WarningAction SilentlyContinue | Out-Null
            
            Write-Host "Creating remote scripts directory..." -ForegroundColor Cyan
            if (!(Test-Path $networkPath)) {
                New-Item -ItemType Directory -Path $networkPath -Force
            }
            
            Write-Host "Copying DC-Sync.ps1 to $DCName..." -ForegroundColor Cyan
            Copy-Item $scriptPath "$networkPath\DC-Sync.ps1" -Force
            
            Write-Host "Copying guide to $DCName..." -ForegroundColor Cyan
            Copy-Item $guidePath "$networkPath\DC-Sync-Guide.md" -Force
            
            Write-Host "✅ Files copied to $DCName successfully!" -ForegroundColor Green
            Write-Host "`nNext steps:" -ForegroundColor Yellow
            Write-Host "1. RDP to $DCName" -ForegroundColor White
            Write-Host "2. Open PowerShell as Administrator" -ForegroundColor White
            Write-Host "3. cd C:\Scripts" -ForegroundColor White
            Write-Host "4. .\DC-Sync.ps1 -CheckOnly" -ForegroundColor White
            
        } catch {
            Write-Host "ERROR: Network transfer failed - $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Try USB transfer instead" -ForegroundColor Yellow
        }
    }
    
    "show-content" {
        Write-Host "`n--- SCRIPT CONTENT FOR COPY-PASTE ---" -ForegroundColor Yellow
        Write-Host "Copy this content and paste into PowerShell ISE on your DC:" -ForegroundColor Cyan
        Write-Host "Save as: C:\Scripts\DC-Sync.ps1" -ForegroundColor Cyan
        Write-Host "`n" + "="*60 -ForegroundColor Gray
        Get-Content $scriptPath
        Write-Host "`n" + "="*60 -ForegroundColor Gray
        Write-Host "✅ Content displayed above" -ForegroundColor Green
    }
    
    default {
        Write-Host "ERROR: Invalid transfer method '$TransferMethod'" -ForegroundColor Red
        Write-Host "Valid methods: usb, network, show-content" -ForegroundColor Yellow
        Write-Host "`nExamples:" -ForegroundColor Cyan
        Write-Host ".\Transfer-Helper.ps1 -TransferMethod usb" -ForegroundColor White
        Write-Host ".\Transfer-Helper.ps1 -TransferMethod network -DCName DC01" -ForegroundColor White
        Write-Host ".\Transfer-Helper.ps1 -TransferMethod show-content" -ForegroundColor White
    }
}

Write-Host "`n=== TRANSFER HELPER COMPLETE ===" -ForegroundColor Green
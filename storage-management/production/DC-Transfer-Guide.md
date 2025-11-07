# Domain Controller Script Transfer & Execution Guide

## 🎯 Step-by-Step Transfer Process

### Method 1: USB Transfer (Recommended for Air-Gapped DCs)
```powershell
# 1. Copy script to USB drive from current machine
Copy-Item "H:\My Drive\storage-management\DC-Sync.ps1" "E:\DC-Sync.ps1"
Copy-Item "H:\My Drive\storage-management\DC-Sync-Guide.md" "E:\DC-Sync-Guide.md"

# 2. On Domain Controller, copy from USB
Copy-Item "E:\DC-Sync.ps1" "C:\Scripts\DC-Sync.ps1"
```

### Method 2: Network Copy (If DC accessible via network)
```powershell
# Replace YOUR-DC-NAME with actual DC hostname
$DCName = "YOUR-DC-NAME"
Copy-Item "H:\My Drive\storage-management\DC-Sync.ps1" "\\$DCName\C$\Scripts\DC-Sync.ps1"
```

### Method 3: RDP Copy-Paste
```powershell
# 1. Remote Desktop to your Domain Controller
# 2. Open PowerShell ISE or notepad as Administrator
# 3. Copy-paste the script content and save as C:\Scripts\DC-Sync.ps1
```

---

## 🚀 Execution Steps on Domain Controller

### Step 1: Prepare Environment
```powershell
# On Domain Controller - Open PowerShell as Administrator
# Create scripts directory if it doesn't exist
New-Item -ItemType Directory -Path "C:\Scripts" -Force

# Navigate to scripts directory
cd C:\Scripts

# Verify script exists
Get-ChildItem DC-Sync.ps1
```

### Step 2: Set Execution Policy (If Needed)
```powershell
# Check current policy
Get-ExecutionPolicy

# If Restricted, temporarily allow scripts
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Step 3: Run Safety Check First
```powershell
# SAFE MODE - No changes made
.\DC-Sync.ps1 -CheckOnly
```

### Step 4: Review Results
Look for these indicators:
- ✅ `Confirmed: This is a Domain Controller`
- ✅ `NTDS Service: Running`
- ✅ `Time service appears to be working`
- ✅ `No obvious replication errors found`

### Step 5: Sync if Issues Found
```powershell
# If CheckOnly found problems, run sync
.\DC-Sync.ps1 -ForceSync
```

### Step 6: Full Reset if Major Issues
```powershell
# Only if serious problems persist
.\DC-Sync.ps1 -ForceSync -RestartServices
```

---

## 📋 Quick Transfer Script

I'll create a transfer helper script for you:
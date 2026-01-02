# Auto-Startup Configuration - Restart Only

**Configuration**: Restart = True, Power On = False  
**Screen Events**: Lock/Unlock = True

---

## 🎯 Configuration Summary

### Auto-Start Conditions:

- ✅ **RESTART**: Auto-start ENABLED
- ❌ **POWER ON**: Auto-start DISABLED
- ✅ **SCREEN LOCK**: Auto-start ENABLED
- ✅ **SCREEN UNLOCK**: Auto-start ENABLED

---

## 🔧 How It Works

### Restart Detection:

1. **On Shutdown**: Creates `.restart-flag` file
2. **On Startup**: 
   - If flag exists → **RESTART detected** → System starts
   - If flag missing → **COLD BOOT detected** → System does NOT start
3. **After Check**: Flag is preserved for next restart

### Screen Lock/Unlock:

- Monitors Windows session events
- Triggers on session lock (EventType 8)
- Triggers on session unlock (EventType 7)
- Automatically starts VPS system

---

## 📋 Scheduled Tasks

### Task 1: VPS-AutoStart-RestartOnly
- **Trigger**: At startup
- **Action**: Runs `restart-detector.ps1`
- **Function**: Detects restart vs cold boot, starts system only on restart

### Task 2: VPS-AutoStart-ScreenEvents
- **Trigger**: At logon + Session events
- **Action**: Runs `screen-handler.ps1`
- **Function**: Starts system on screen lock/unlock

---

## 🚀 Setup

### Run Setup Script:

```powershell
# Run as Administrator (auto-elevates)
.\setup-auto-startup-restart-only.ps1
```

Or double-click: `SETUP-AUTO-STARTUP.bat`

---

## 📁 Files Created

- `restart-detector.ps1` - Detects restart vs cold boot
- `screen-handler.ps1` - Handles screen lock/unlock events
- `shutdown-handler.ps1` - Preserves restart flag on shutdown
- `.restart-flag` - Flag file for restart detection

---

## ✅ Verification

### Check Scheduled Tasks:

```powershell
Get-ScheduledTask -TaskName "VPS-AutoStart-*"
```

### Check Flag File:

```powershell
Test-Path "C:\Users\USER\OneDrive\.restart-flag"
```

### View Logs:

```powershell
Get-Content vps-logs\restart-detector.log -Tail 20
Get-Content vps-logs\screen-handler.log -Tail 20
```

---

## 🔄 Behavior

### On RESTART:
1. System restarts
2. Scheduled task runs `restart-detector.ps1`
3. Flag file exists → **VPS system starts automatically**
4. Flag file preserved for next restart

### On POWER ON (Cold Boot):
1. System powers on
2. Scheduled task runs `restart-detector.ps1`
3. Flag file missing → **VPS system does NOT start**
4. Flag file created for next restart detection

### On SCREEN LOCK/UNLOCK:
1. Screen locked or unlocked
2. Session event detected
3. `screen-handler.ps1` runs
4. **VPS system starts automatically**

---

## 📝 Notes

- Flag file (`.restart-flag`) is used to distinguish restart from cold boot
- Screen events trigger immediately on lock/unlock
- All operations run in background (hidden windows)
- No user interaction required
- Fully automated error handling

---

**Created**: 2025-12-14  
**System**: NuNa (Windows 11 Home Single Language 25H2)  
**Status**: **CONFIGURED** ✅

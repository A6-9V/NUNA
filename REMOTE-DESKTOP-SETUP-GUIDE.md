# Remote Desktop Setup Guide

## Overview

This guide helps you set up Remote Desktop (RDP) on your Windows 11 system to allow remote access from other computers.

## Quick Setup

### Option 1: Automated Setup (Recommended)

1. **Run the setup script:**
   ```powershell
   .\setup-remote-desktop.ps1
   ```
   
   Or double-click: `SETUP-REMOTE-DESKTOP.bat`

2. **The script will:**
   - Enable Remote Desktop
   - Configure Windows Firewall
   - Enable Network Level Authentication (NLA)
   - Display connection information
   - Save connection details to `remote-desktop-info.txt`

### Option 2: Manual Setup

1. **Open System Settings:**
   - Press `Win + I`
   - Go to **System** → **Remote Desktop**

2. **Enable Remote Desktop:**
   - Toggle "Remote Desktop" to **On**
   - Choose "Enable Remote Desktop" when prompted

3. **Configure Firewall:**
   - Windows Firewall will automatically allow RDP connections

## Connection Information

After setup, you'll need:

- **Computer Name:** Your Windows computer name
- **IP Address:** Your local network IP address
- **Username:** Your Windows username
- **Password:** Your Windows password

To find your IP address:
```powershell
ipconfig
```
Look for "IPv4 Address" under your active network adapter.

## Connecting from Another Computer

### Windows

1. Open **Remote Desktop Connection** (`mstsc.exe`)
2. Enter your computer name or IP address
3. Click **Connect**
4. Enter your username and password
5. Click **OK**

### Mac

1. Install **Microsoft Remote Desktop** from App Store
2. Click **Add PC**
3. Enter computer name or IP address
4. Enter username and password
5. Click **Add** and connect

### Mobile (iOS/Android)

1. Install **Microsoft Remote Desktop** app
2. Add new connection
3. Enter computer name or IP address
4. Enter credentials
5. Save and connect

## Security Best Practices

### ✅ Recommended Settings

- **Network Level Authentication (NLA):** Enabled (default)
- **Strong Password:** Required for your Windows account
- **Firewall:** Enabled and configured
- **Windows Updates:** Keep system updated

### 🔒 For Internet Access

If you need to access from outside your local network:

1. **Use VPN (Recommended):**
   - Set up a VPN server
   - Connect via VPN first, then use RDP
   - More secure than exposing RDP to internet

2. **Port Forwarding (Less Secure):**
   - Forward port 3389 on your router
   - Use strong password
   - Consider changing default RDP port
   - Use firewall rules to limit access

3. **Remote Desktop Gateway:**
   - Enterprise solution for secure remote access
   - Requires Windows Server

## Troubleshooting

### Cannot Connect

1. **Check Remote Desktop is enabled:**
   ```powershell
   Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
   ```
   Should return `0` (enabled)

2. **Check Firewall:**
   ```powershell
   Get-NetFirewallRule -DisplayGroup "Remote Desktop"
   ```
   Should show rules as enabled

3. **Check Network:**
   - Ensure both computers are on same network (for local access)
   - Ping the target computer
   - Check if port 3389 is accessible

### Connection Issues

- **"Remote Desktop can't connect":**
  - Verify Remote Desktop is enabled
  - Check firewall settings
  - Ensure computer is not sleeping

- **"The credentials that were used to connect to [computer] did not work":**
  - Verify username and password
  - Ensure account has password (required for RDP)
  - Check if account is locked

- **"This computer can't connect to the remote computer":**
  - Check network connectivity
  - Verify IP address or computer name
  - Check if Remote Desktop service is running

## Verification

After setup, verify Remote Desktop is working:

```powershell
# Check if RDP is enabled
(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections").fDenyTSConnections
# Should return 0

# Check firewall rules
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Select-Object DisplayName, Enabled

# Check RDP service
Get-Service TermService
# Should be Running
```

## Files Created

- `setup-remote-desktop.ps1` - Main setup script
- `SETUP-REMOTE-DESKTOP.bat` - Quick launcher
- `remote-desktop-info.txt` - Connection information
- `REMOTE-DESKTOP-SETUP-GUIDE.md` - This guide

## Additional Resources

- [Microsoft Remote Desktop Documentation](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/)
- [Windows 11 Remote Desktop Guide](https://support.microsoft.com/windows/how-to-use-remote-desktop-5fe128d5-8fb1-7a23-3b8a-41e636865e8c)

## Notes

- Remote Desktop requires a password-protected account
- Home editions of Windows may have limitations
- For best security, use VPN for internet access
- Keep Windows updated for security patches

---

**Created:** 2025-12-16  
**System:** Windows 11 Home Single Language 25H2  
**Device:** NuNa





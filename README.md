# Windows Setup Scripts

Complete Windows configuration scripts for setting up cloud sync, security, and system settings.

## Features

- ✅ Configure Windows Account Sync
- ✅ Set up File Explorer preferences
- ✅ Configure default browser and apps
- ✅ Windows Defender exclusions for cloud folders
- ✅ Windows Firewall rules for cloud services
- ✅ Windows Security (Controlled Folder Access) configuration
- ✅ Cloud sync service verification (OneDrive, Google Drive, Dropbox)

## Accounts

- **Microsoft/Outlook**: Lengkundee01@outlook.com
- **Google/Gmail**: Lengkundee01@gmail.com

## Quick Start

### Run Complete Setup

1. **Run as Administrator**: Right-click `complete-windows-setup.ps1` > Run with PowerShell > Run as Administrator
   - Or use: `RUN-COMPLETE-SETUP.bat`
   - Or use: `run-setup.ps1`

2. **Follow the prompts** and let the script configure your system

3. **Complete manual steps** (see MANUAL-SETUP-GUIDE.md)

### Helper Scripts

- `open-settings.ps1` - Opens all necessary Windows Settings windows
- `check-cloud-services.ps1` - Checks status of cloud sync services
- `run-cursor-admin.ps1` - Launch Cursor as Administrator
- `run-vscode-admin.ps1` - Launch VSCode as Administrator
- `clone-repo.ps1` - Clone this repository using GitHub CLI

## Files

### Main Scripts
- `complete-windows-setup.ps1` - Main setup script (run this)
- `setup-cloud-sync.ps1` - Cloud sync security configuration

### Helper Scripts
- `open-settings.ps1` - Open Windows Settings
- `check-cloud-services.ps1` - Check cloud services status
- `run-cursor-admin.ps1` - Run Cursor as admin
- `run-vscode-admin.ps1` - Run VSCode as admin
- `clone-repo.ps1` - Clone repository

### Documentation
- `MANUAL-SETUP-GUIDE.md` - Step-by-step manual configuration guide
- `SETUP-INSTRUCTIONS.txt` - Setup instructions
- `AUTOMATION-RULES.md` - Automation rules and best practices
- `GITHUB-DESKTOP-RULES.md` - GitHub Desktop integration rules
- `DEBUG-SUMMARY.md` - Debug and troubleshooting guide
- `README.md` - This file

## Requirements

- Windows 10/11
- Administrator privileges
- PowerShell 5.1 or later

## Cloud Services

The scripts configure security settings for:
- **OneDrive** (Lengkundee01@outlook.com)
- **Google Drive** (Lengkundee01@gmail.com)
- **Dropbox** (if installed)

## Usage

### Initial Setup
```powershell
# Run as Administrator
.\complete-windows-setup.ps1
```

### Check Cloud Services
```powershell
.\check-cloud-services.ps1
```

### Open Settings
```powershell
.\open-settings.ps1
```

### Run Cursor/VSCode as Admin
```powershell
.\run-cursor-admin.ps1
.\run-vscode-admin.ps1
```

## Manual Steps Required

After running the setup script, you need to:

1. Sign in to Microsoft account (Lengkundee01@outlook.com) in Windows Settings
2. Sign in to OneDrive with Lengkundee01@outlook.com
3. Sign in to Google Drive with Lengkundee01@gmail.com
4. Sign in to Dropbox (if using)
5. Configure default apps in Settings > Apps > Default apps
6. Enable browser sync in Chrome/Edge/Firefox
7. Verify all cloud services are syncing properly

See `MANUAL-SETUP-GUIDE.md` for detailed instructions.

## Repository

- **GitHub**: https://github.com/Mouy-leng/Window-setup.git

### Clone Repository
```bash
# Using GitHub CLI
gh repo clone Mouy-leng/Window-setup

# Using Git (HTTPS)
git clone https://github.com/Mouy-leng/Window-setup.git

# Using GitHub Desktop
# Download from: https://desktop.github.com/
# File > Clone Repository > https://github.com/Mouy-leng/Window-setup.git
```

### GitHub Desktop Integration
- **Download**: https://desktop.github.com/
- **Release Notes**: https://desktop.github.com/release-notes/
- **Setup Script**: Run `github-desktop-setup.ps1` after installation
- **Documentation**: See `GITHUB-DESKTOP-RULES.md` for integration rules

## Troubleshooting

### Script won't run
- Make sure you're running as Administrator
- Check PowerShell execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Cloud services not found
- Install the services manually:
  - OneDrive: https://www.microsoft.com/microsoft-365/onedrive/download
  - Google Drive: https://www.google.com/drive/download/
  - Dropbox: https://www.dropbox.com/downloading

### Sync not working
- Verify you're signed in to each service
- Check Windows Security exclusions
- Restart the cloud service
- Check firewall settings

## License

This project is for personal use.

## Author

Lengkundee01


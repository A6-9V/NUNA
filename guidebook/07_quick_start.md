# Quick Start Guide - NUNA Tools

## ✅ Installation Status

Run this to verify packages are installed:
```bash
python -c "import google.auth; import msal; import requests; print('All packages OK!')"
```

## 🚀 Quick Setup

### Option 1: Use Interactive Scripts (Recommended)

#### Google Drive Setup:
```powershell
.\setup-google-oauth.ps1
```

#### OneDrive Setup:
```powershell
.\setup-onedrive-oauth.ps1
```

### Option 2: Manual Setup

See `SETUP-OAUTH.md` for detailed step-by-step instructions.

---

## 📋 Google Drive Cleanup

### First Time Setup:
1. Run: `.\setup-google-oauth.ps1`
2. Follow the prompts to download `credentials.json`
3. Test: `python gdrive_cleanup.py audit --top 5`

### Common Commands:

**Audit - Find largest files:**
```bash
python gdrive_cleanup.py audit --top 25 --show-links
```

**Export full inventory:**
```bash
python gdrive_cleanup.py audit --csv gdrive-report.csv --json gdrive-report.json
```

**Find duplicates:**
```bash
python gdrive_cleanup.py duplicates --show 20 --show-per-group 10
```

**Trash files (dry-run first!):**
```bash
# 1. Create ids_to_trash.json with file IDs
# 2. Dry-run:
python gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES"
# 3. Apply (actually trash):
python gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES" --apply
```

---

## 📋 Dropbox to OneDrive Import

### First Time Setup:
1. Run: `.\setup-onedrive-oauth.ps1`
2. Enter your Azure Client ID when prompted
3. Test: `python dropbox_to_onedrive.py --dropbox-url "YOUR_URL" --dry-run`

### Common Commands:

**Dry-run (preview only):**
```bash
python dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --dry-run
```

**Import to OneDrive:**
```bash
python dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --onedrive-folder "Dropbox Import"
```

---

## 📈 Trading Data File Management (Local)

This repo also includes a safe-by-default local automation helper for trading logs/exports/reports:

- Script: `trading_data_manager.py`
- Guide: `guidebook/05_trading_data_file_management.md`

**Initialize folders + write example config:**
```bash
python3 trading_data_manager.py init --write-example-config trading_data_config.example.json
```

**Daily run (dry-run first):**
```bash
python3 trading_data_manager.py run
```

**Apply (moves/converts files):**
```bash
python3 trading_data_manager.py run --apply
```

---

## 🔧 Troubleshooting

### Packages Not Installed?
```bash
python -m pip install -r requirements.txt
```

### Google OAuth Issues?
- Check `credentials.json` exists in `H:\Pictures\.Gallery2\recycle\bins`
- Verify Google Drive API is enabled in Google Cloud Console
- Check OAuth consent screen is configured

### OneDrive OAuth Issues?
- Verify `ONEDRIVE_CLIENT_ID` environment variable is set:
  ```powershell
  echo $env:ONEDRIVE_CLIENT_ID
  ```
- If empty, run `.\setup-onedrive-oauth.ps1` again
- Restart terminal after setting permanent environment variable

### Need Help?
- See `SETUP-OAUTH.md` for detailed OAuth setup
- Check `README.md` for full documentation
- Review `guidebook/` folder for detailed guides

---

## 📁 File Structure

```
H:\Pictures\.Gallery2\recycle\bins\
├── gdrive_cleanup.py          # Google Drive cleanup tool
├── dropbox_to_onedrive.py     # Dropbox to OneDrive importer
├── requirements.txt           # Python dependencies
├── credentials.json           # Google OAuth (create this)
├── token.json                 # Google auth token (auto-generated)
├── setup-google-oauth.ps1     # Google OAuth setup helper
├── setup-onedrive-oauth.ps1   # OneDrive OAuth setup helper
├── SETUP-OAUTH.md            # Detailed OAuth setup guide
├── QUICK-START.md            # This file
└── guidebook/                # Detailed documentation
```

---

## 🎯 Next Steps

1. ✅ Packages installed
2. ⏳ Set up Google OAuth: `.\setup-google-oauth.ps1`
3. ⏳ Set up OneDrive OAuth: `.\setup-onedrive-oauth.ps1`
4. 🚀 Start using the tools!

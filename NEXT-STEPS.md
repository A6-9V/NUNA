# Next Steps Guide

## Current Status

✅ Repository cloned and ready  
✅ Python packages installed  
✅ Setup scripts created  
⏳ OAuth credentials need to be configured

---

## Step 1: Complete OAuth Setup

### Quick Setup (Recommended)

Run the automated helper:
```powershell
cd J:\NUNA
.\auto-setup-helper.ps1
```

This will:
- Open Google Cloud Console and Azure Portal in your browser
- Show step-by-step instructions
- Check what's already configured

### Manual Setup

See `SETUP-OAUTH.md` for detailed instructions.

---

## Step 2: Verify Setup

After completing OAuth setup, verify everything works:

### Check Status:
```powershell
.\check-oauth-setup.ps1
```

### Test Google Drive:
```powershell
.\test-google-drive.ps1
```

### Test OneDrive:
```powershell
.\test-onedrive.ps1
```

---

## Step 3: Start Using the Tools

### Google Drive Cleanup

**Audit your Drive (find largest files):**
```bash
python gdrive_cleanup.py audit --top 25 --show-links
```

**Export full inventory:**
```bash
python gdrive_cleanup.py audit --csv gdrive-report.csv --json gdrive-report.json
```

**Find duplicate files:**
```bash
python gdrive_cleanup.py duplicates --show 20 --show-per-group 10
```

**Trash files (carefully!):**
```bash
# 1. Create ids_to_trash.json with file IDs you want to trash
# 2. Dry-run first:
python gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES"
# 3. Apply (actually trash):
python gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES" --apply
```

### Dropbox to OneDrive Import

**Preview what will be imported (dry-run):**
```bash
python dropbox_to_onedrive.py --dropbox-url "YOUR_DROPBOX_SHARED_FOLDER_URL" --dry-run
```

**Import to OneDrive:**
```bash
python dropbox_to_onedrive.py --dropbox-url "YOUR_DROPBOX_SHARED_FOLDER_URL" --onedrive-folder "Dropbox Import"
```

---

## Step 4: Advanced Usage

### Filter Google Drive Queries

All Google Drive commands support `--query` for filtering:

**Only items in a specific folder:**
```bash
python gdrive_cleanup.py audit --query "'FOLDER_ID' in parents" --top 10
```

**Only PDFs:**
```bash
python gdrive_cleanup.py audit --query "mimeType='application/pdf'" --top 10
```

**Only large files (>1GB):**
```bash
python gdrive_cleanup.py audit --query "size > 1073741824" --top 10
```

---

## Troubleshooting

### Google Drive Issues

**"credentials.json not found"**
- Run `.\auto-setup-helper.ps1` and complete Google OAuth setup
- Ensure `credentials.json` is in `J:\NUNA\`

**"403 Error" or "Permission denied"**
- Check that Google Drive API is enabled in Google Cloud Console
- Verify OAuth consent screen is configured
- Check that required scopes are added

**"ModuleNotFoundError: No module named 'google'"**
- Install packages: `python -m pip install -r requirements.txt`

### OneDrive Issues

**"ONEDRIVE_CLIENT_ID not set"**
- Set environment variable: `$env:ONEDRIVE_CLIENT_ID = "YOUR_CLIENT_ID"`
- Or run `.\setup-onedrive-oauth.ps1`

**"Permission denied"**
- Check that `Files.ReadWrite.All` and `User.Read` permissions are added in Azure Portal
- For organizational accounts, admin consent may be required

**"Device code expired"**
- Device codes expire after 15 minutes
- Run the command again to get a new code

---

## Quick Reference Commands

```powershell
# Check setup status
.\check-oauth-setup.ps1

# Open OAuth setup pages
.\open-oauth-pages.ps1

# Test Google Drive
.\test-google-drive.ps1

# Test OneDrive
.\test-onedrive.ps1

# View help
python gdrive_cleanup.py --help
python dropbox_to_onedrive.py --help
```

---

## Documentation Files

- `QUICK-START.md` - Quick reference guide
- `SETUP-OAUTH.md` - Detailed OAuth setup instructions
- `SETUP-COMPLETE.md` - Setup summary
- `README.md` - Original project documentation
- `guidebook/` - Detailed guides for each tool

---

## Need Help?

1. Check `SETUP-OAUTH.md` for OAuth setup issues
2. Review `guidebook/` for detailed tool documentation
3. Run `.\check-oauth-setup.ps1` to see what's missing
4. Check error messages - they usually indicate what's wrong

---

## You're Ready!

Once OAuth is configured, you can start using the tools immediately. Start with dry-runs to see what the tools will do before making any changes!

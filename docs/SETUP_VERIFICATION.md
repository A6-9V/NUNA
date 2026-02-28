# Setup Verification Checklist

Use this checklist to verify that the forge.mql5.io and Replit integration is
working correctly.

## ✅ Pre-flight Checks

- [ ] Repository cloned locally
- [ ] Git installed and configured
- [ ] Internet connection available

## 🔧 Git Remote Verification

### Check Remotes

```bash
git remote -v

```bash

**Expected Output:**

```bash
forge   https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git (fetch)
forge   https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git (push)
origin  https://github.com/A6-9V/NUNA (fetch)
origin  https://github.com/A6-9V/NUNA (push)

```bash

- [ ] forge remote exists
- [ ] origin remote exists
- [ ] URLs are correct

## 📄 File Verification

### Configuration Files

- [ ] `.replit` exists
- [ ] `replit.nix` exists

### Documentation Files

- [ ] `FORGE_MQL5_SETUP.md` exists (5.8 KB)
- [ ] `REPLIT_INTEGRATION.md` exists (7.8 KB)
- [ ] `INTEGRATION_SETUP_SUMMARY.md` exists (8.0 KB)
- [ ] `INTEGRATION_QUICK_REFERENCE.md` exists (2.6 KB)
- [ ] `SECURITY_NOTICE.md` exists (4.4 KB)

### Script Files

- [ ] `scripts/sync-forge.sh` exists and is executable
- [ ] `scripts/sync-forge.ps1` exists
- [ ] `scripts/cleanup-forge.sh` exists and is executable
- [ ] `scripts/cleanup-forge.ps1` exists

### Verify Executability (Linux/Mac)

```bash
ls -l scripts/*forge*

```bash

Should show `-rwxr-xr-x` for .sh files.

## 📊 System Information

### Check system-info.json

```bash
cat system-info.json | grep -A 30 "repository_integrations"

```bash

- [ ] `repository_integrations` section exists
- [ ] `github` entry present
- [ ] `forge_mql5` entry present
- [ ] `replit` entry present

## 🧪 Script Testing

### Test Sync Script Syntax (Bash)

```bash
bash -n scripts/sync-forge.sh

```bash

- [ ] No syntax errors

### Test Cleanup Script Syntax (Bash)

```bash
bash -n scripts/cleanup-forge.sh

```bash

- [ ] No syntax errors

### Test Script Help (optional)

```bash

# Should show colored output with instructions

./scripts/sync-forge.sh --help 2>&1 | head -5

```bash

- [ ] Script displays information

## 🌐 Network Connectivity (Optional)

⚠️ **Note**: This may fail in sandboxed environments but should work in
production.

### Test forge.mql5.io Connectivity

```bash
ping -c 3 forge.mql5.io

```bash

- [ ] Host is reachable (or note if environment blocks ping)

### Test Git Access to forge

```bash
git ls-remote forge

```bash

- [ ] Lists remote branches (or note if authentication fails)

## 📖 Documentation Review

### Quick Reference

```bash
cat INTEGRATION_QUICK_REFERENCE.md

```bash

- [ ] Contains repository URLs
- [ ] Contains quick commands
- [ ] Contains troubleshooting section

### Security Notice

```bash
cat SECURITY_NOTICE.md

```bash

- [ ] Documents token location
- [ ] Provides security recommendations
- [ ] Includes rotation instructions

## 🚀 Functional Testing

### Dry Run: Check Current Branch

```bash
git branch --show-current

```bash

- [ ] Shows current branch name

### Dry Run: Verify No Uncommitted Changes

```bash
git status

```bash

- [ ] Working tree is clean

### Optional: Test Fetch from forge

```bash
git fetch forge --dry-run

```bash

- [ ] Command executes (may show "Everything up-to-date" or connection error)

## 📦 Replit Integration

### Access Replit Project

Open in browser:

```bash
https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS

```bash

- [ ] Replit project loads
- [ ] Can see file structure
- [ ] `.replit` and `replit.nix` files are present

### Optional: Test Replit Environment

If you have access to Replit:

1. Click "Run" button
2. Check console output
3. Verify Python 3.11 is running

- [ ] Replit environment starts
- [ ] Python application runs
- [ ] No critical errors

## 🔒 Security Verification

### Check .gitignore

```bash
cat .gitignore | grep -E "(token|secret|key)"

```bash

- [ ] `.env` files are ignored
- [ ] `.key` files are ignored
- [ ] `.pem` files are ignored

### Check Git Config Not Committed

```bash
git ls-files | grep ".git/config"

```bash

- [ ] Returns empty (config file is not tracked)

## 📋 Commit History

### View Recent Commits

```bash
git log --oneline -6

```bash

Expected commits:

- [ ] "Add security notice for forge.mql5.io token usage"
- [ ] "Add integration setup summary and quick reference guides"
- [ ] "Update system-info.json with repository integrations"
- [ ] "Add forge.mql5.io and Replit integration with sync scripts"
- [ ] "Add WiFi network information (SSID: LengA6-9V) to system-info.json"

## ✅ Final Verification

### All Checks Complete

- [ ] Git remotes configured correctly
- [ ] All files present and executable
- [ ] Documentation complete
- [ ] Scripts validated
- [ ] System information updated
- [ ] Security notice in place
- [ ] Commits pushed to origin

### Ready for Use

- [ ] Can sync to forge.mql5.io (or know the commands)
- [ ] Can access Replit environment
- [ ] Can find documentation when needed
- [ ] Understand security considerations

## 🎯 Next Steps

1. **Read the Documentation**
   - Start with `INTEGRATION_QUICK_REFERENCE.md`
   - Review `INTEGRATION_SETUP_SUMMARY.md` for details

2. **Test Sync (When Ready)**
   ```bash
   ./scripts/sync-forge.sh main
   ```

3. **Test Replit**

   - Open the Replit URL
   - Click "Run" to test the environment

4. **Bookmark Important Links**

   - GitHub: https://github.com/A6-9V/NUNA
   - forge.mql5.io: https://forge.mql5.io/LengKundee/NUNA
   - Replit: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS

## 📞 Support

If any checks fail:

1. Review the relevant documentation file
2. Check the troubleshooting section
3. Verify network connectivity
4. Ensure git is properly configured

---

**Verification Date**: _____________  
**Verified By**: _____________  
**Status**: ☐ Pass ☐ Fail ☐ Partial  
**Notes**: _____________


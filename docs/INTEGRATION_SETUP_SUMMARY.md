# Integration Setup Summary

## Overview

This document summarizes the forge.mql5.io and Replit integration setup
completed on 2026-02-05.

## What Was Configured

### 1. Git Remote for forge.mql5.io

A new git remote named `forge` has been added to the repository:

```bash
git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git

```bash

**Configuration Location**: `.git/config`

**Verification**:

```bash
git remote -v

```bash

Should show:

```bash
forge   https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git (fetch)
forge   https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git (push)
origin  https://github.com/A6-9V/NUNA (fetch)
origin  https://github.com/A6-9V/NUNA (push)

```bash

### 2. Replit Configuration Files

Created two configuration files for Replit cloud IDE:

- **`.replit`**: Main configuration (run commands, ports, debugging, deployment)
- **`replit.nix`**: System packages and dependencies (Python 3.11, PostgreSQL, Redis, etc.)

These files enable the project to run seamlessly on Replit.

### 3. Sync and Cleanup Scripts

Created four scripts for managing the forge.mql5.io integration:

#### Bash Scripts (Linux/Mac)

- **`scripts/sync-forge.sh`**: Sync repository to forge.mql5.io
- **`scripts/cleanup-forge.sh`**: Reset forge.mql5.io to clean state

#### PowerShell Scripts (Windows)

- **`scripts/sync-forge.ps1`**: Sync repository to forge.mql5.io
- **`scripts/cleanup-forge.ps1`**: Reset forge.mql5.io to clean state

All scripts are executable and include proper error handling.

### 4. Documentation

Created comprehensive guides:

- **`FORGE_MQL5_SETUP.md`** (5.8 KB): Complete guide for forge.mql5.io setup and usage
- **`REPLIT_INTEGRATION.md`** (7.9 KB): Comprehensive guide for Replit cloud development
- **`README.md`**: Updated with integration information and quick links

### 5. System Information

Updated `system-info.json` with repository integration details:

```json
{
  "repository_integrations": {
    "github": {
      "url": "https://github.com/A6-9V/NUNA",
      "type": "primary",
      "description": "Main development repository"
    },
    "forge_mql5": {
      "url": "https://forge.mql5.io/LengKundee/NUNA.git",
      "type": "mirror",
      "description": "MQL5 community integration",
      "authentication": "token-based",
      "configured_date": "2026-02-05",
      "sync_scripts": [...]
    },
    "replit": {
      "url": "https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS",
      "type": "cloud_ide",
      "description": "Cloud development environment",
      "fork_id": "74fbf663-fcf3-40e5-b496-2295edb70b17",
      "configured_date": "2026-02-05",
      "config_files": [...]
    }
  }
}

```bash

## How to Use

### Syncing to forge.mql5.io

**Linux/Mac**:

```bash

# Sync current branch
./scripts/sync-forge.sh

# Sync main branch
./scripts/sync-forge.sh main

# Sync all branches and tags
./scripts/sync-forge.sh --all

```bash

**Windows**:

```powershell

# Sync current branch
.\scripts\sync-forge.ps1

# Sync main branch
.\scripts\sync-forge.ps1 -Branch main

# Sync all branches and tags
.\scripts\sync-forge.ps1 -All

```bash

### Cleaning Up forge.mql5.io

**Linux/Mac**:

```bash

# Interactive cleanup (asks for confirmation)
./scripts/cleanup-forge.sh

# Force cleanup (no confirmation)
./scripts/cleanup-forge.sh --force

```bash

**Windows**:

```powershell

# Interactive cleanup
.\scripts\cleanup-forge.ps1

# Force cleanup
.\scripts\cleanup-forge.ps1 -Force

```bash

### Manual Git Commands

```bash

# Push to forge
git push forge main

# Pull from forge
git pull forge main

# Force push (reset forge to match local)
git push forge main --force

# Push all branches
git push forge --all

# Push all tags
git push forge --tags

```bash

### Developing on Replit

1. Open the Replit project:

```
https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS
```

2. The environment is pre-configured with:

   - Python 3.11
   - All dependencies from requirements.txt
   - Port forwarding (8000, 5555)
   - Git integration
   - Debugging tools

3. Click "Run" to start the application
4. Use the integrated terminal for git commands
5. Edit files in the cloud IDE

## Repository URLs

- **GitHub (Primary)**: https://github.com/A6-9V/NUNA
- **forge.mql5.io**: https://forge.mql5.io/LengKundee/NUNA
- **Replit**: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS

## Authentication

### forge.mql5.io

- **Method**: Token-based authentication
- **Token**: `PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW`
- **Storage**: Embedded in git remote URL (`.git/config`)
- **Security**: Token is not committed to repository, only stored locally

### Replit

- **Method**: OAuth with GitHub
- **Access**: Requires Replit account linked to GitHub
- **Permissions**: Read/write access to repository

## Files Added

1. `.replit` - Replit configuration
2. `replit.nix` - Nix package manager configuration
3. `FORGE_MQL5_SETUP.md` - forge.mql5.io documentation
4. `REPLIT_INTEGRATION.md` - Replit documentation
5. `scripts/sync-forge.sh` - Bash sync script
6. `scripts/sync-forge.ps1` - PowerShell sync script
7. `scripts/cleanup-forge.sh` - Bash cleanup script
8. `scripts/cleanup-forge.ps1` - PowerShell cleanup script

## Files Modified

1. `README.md` - Added integration section
2. `system-info.json` - Added repository_integrations section

## Next Steps

### Immediate Actions

1. **Test forge.mql5.io sync**:

```bash
./scripts/sync-forge.sh main
```

2. **Test Replit environment**:

   - Open the Replit URL
   - Click "Run" to verify the environment
   - Make a test commit and push

3. **Verify git remotes**:

```bash
git remote -v
```

### Regular Workflow

1. **Development**:
   - Work on GitHub or Replit
   - Commit and push changes to GitHub

2. **Sync to forge.mql5.io**:

   - Run sync script after major updates
   - Keep MQL5 community in sync with GitHub

3. **Cleanup (if needed)**:

   - Run cleanup script to reset forge.mql5.io
   - Use when forge repository gets out of sync

### Best Practices

1. **Always test locally first** before pushing to forge
2. **Use descriptive commit messages** visible on all platforms
3. **Keep remotes in sync** by running sync regularly
4. **Backup before cleanup** operations on forge
5. **Use Replit for quick testing** without local setup

## Troubleshooting

### Cannot connect to forge.mql5.io

**Problem**: Connection errors when pushing/pulling

**Solutions**:
1. Check internet connection
2. Verify forge.mql5.io is accessible: `ping forge.mql5.io`
3. Check token is correct in `.git/config`
4. Try updating the remote URL:

```bash
git remote set-url forge https://NEW_TOKEN@forge.mql5.io/LengKundee/NUNA.git
```

### Replit environment not working

**Problem**: Replit shows errors or won't run

**Solutions**:
1. Check `.replit` and `replit.nix` files exist
2. Run in Shell tab: `pip install -r requirements.txt`
3. Restart the Repl (click Stop, then Run)
4. Check Secrets tab for environment variables

### Sync script fails

**Problem**: Scripts exit with errors

**Solutions**:
1. Ensure you're in the repository root directory
2. Check git remotes are configured: `git remote -v`
3. Verify you have uncommitted changes: `git status`
4. Try manual git commands to isolate the issue

## Security Notes

1. **Token Security**: The forge token is stored in `.git/config` which is not committed
2. **Never commit** `.git/config` or files containing the token
3. **Rotate tokens** periodically for security
4. **Use environment variables** for sensitive data in Replit (Secrets tab)
5. **Review** `.gitignore` to ensure sensitive files are excluded

## Support

For help with:

- **forge.mql5.io issues**: See `FORGE_MQL5_SETUP.md`
- **Replit issues**: See `REPLIT_INTEGRATION.md`
- **GitHub issues**: Open an issue at https://github.com/A6-9V/NUNA/issues

---

**Setup Date**: 2026-02-05
**Setup Status**: ✅ Complete
**Ready for Use**: Yes

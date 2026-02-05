# Quick Reference: Repository Integration

## 🔗 Repository URLs

| Platform | URL | Type |
|----------|-----|------|
| **GitHub** | https://github.com/A6-9V/NUNA | Primary |
| **forge.mql5.io** | https://forge.mql5.io/LengKundee/NUNA | Mirror |
| **Replit** | https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS | Cloud IDE |

## ⚡ Quick Commands

### Sync to forge.mql5.io
```bash
# Linux/Mac
./scripts/sync-forge.sh

# Windows
.\scripts\sync-forge.ps1
```

### Reset forge.mql5.io
```bash
# Linux/Mac
./scripts/cleanup-forge.sh

# Windows
.\scripts\cleanup-forge.ps1
```

### Manual Git Operations
```bash
# Check remotes
git remote -v

# Push to forge
git push forge main

# Push to all remotes
git push origin main
git push forge main

# Fetch from forge
git fetch forge
```

## 📚 Documentation

- [FORGE_MQL5_SETUP.md](FORGE_MQL5_SETUP.md) - Complete forge.mql5.io guide
- [REPLIT_INTEGRATION.md](REPLIT_INTEGRATION.md) - Complete Replit guide
- [INTEGRATION_SETUP_SUMMARY.md](INTEGRATION_SETUP_SUMMARY.md) - Setup summary

## 🔐 Authentication

### forge.mql5.io
- **Token**: `PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW`
- **Location**: `.git/config` (not committed)

### Replit
- **Method**: GitHub OAuth
- **Access via**: Replit website with GitHub account

## 🎯 Common Tasks

### Start Development on Replit
1. Go to: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS
2. Click "Run"
3. Edit code in the cloud IDE

### Sync All Repositories
```bash
# Push to GitHub
git push origin main

# Sync to forge
./scripts/sync-forge.sh main
```

### Update forge After Major Changes
```bash
# Commit changes
git add .
git commit -m "Your changes"
git push origin main

# Sync to forge
./scripts/sync-forge.sh main
```

### Reset forge to Clean State
```bash
# Full cleanup (interactive)
./scripts/cleanup-forge.sh

# Or force cleanup
./scripts/cleanup-forge.sh --force
```

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't push to forge | Check internet, verify token in `.git/config` |
| Replit won't run | Install deps: `pip install -r requirements.txt` |
| Sync script fails | Run from repo root, check `git remote -v` |
| Token issues | Update remote: `git remote set-url forge https://TOKEN@forge.mql5.io/LengKundee/NUNA.git` |

## 📦 Setup Status

✅ Git remote configured for forge.mql5.io  
✅ Replit configuration files added (.replit, replit.nix)  
✅ Sync scripts created (Bash + PowerShell)  
✅ Cleanup scripts created (Bash + PowerShell)  
✅ Documentation complete  
✅ system-info.json updated  

**Last Updated**: 2026-02-05

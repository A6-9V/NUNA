# Workspace Setup Guide

This document describes the workspace setup and how to use it.

## Workspace Overview

**Location**: `C:\Users\USER\OneDrive`  
**Type**: Windows automation and setup scripts repository  
**Git Repository**: `https://github.com/Mouy-leng/Window-setup.git`

## Quick Setup

Run the workspace setup script to verify your workspace configuration:

```powershell
.\setup-workspace.ps1
```

This script checks:
- ✅ Workspace root directory
- ✅ Git repository configuration
- ✅ Cursor rules structure
- ✅ Essential configuration files
- ✅ Documentation files
- ✅ .gitignore configuration
- ✅ PowerShell scripts

## Workspace Structure

```
OneDrive/
├── .cursor/
│   └── rules/              # Cursor AI rules
│       ├── powershell-standards/
│       ├── system-configuration/
│       ├── automation-patterns/
│       ├── security-tokens/
│       └── github-desktop-integration/
├── *.ps1                   # PowerShell automation scripts
├── *.md                    # Documentation files
├── .gitignore             # Git exclusions
├── .cursorignore          # Cursor indexing exclusions
├── AGENTS.md              # Cursor agent instructions
└── README.md              # Project overview
```

## Configuration Files

### Essential Files
- `.gitignore` - Excludes personal files, tokens, and system files
- `.cursorignore` - Excludes files from Cursor indexing
- `AGENTS.md` - Instructions for Cursor AI agent
- `README.md` - Project documentation

### Documentation
- `SYSTEM-INFO.md` - System specifications
- `AUTOMATION-RULES.md` - Automation patterns
- `GITHUB-DESKTOP-RULES.md` - GitHub Desktop integration
- `CURSOR-RULES-SETUP.md` - Cursor rules documentation
- `MANUAL-SETUP-GUIDE.md` - Manual setup instructions

## Git Configuration

**User**: `Mouy-leng`  
**Email**: `Mouy-leng@users.noreply.github.com`  
**Remote**: `https://github.com/Mouy-leng/Window-setup.git`

To configure git, run:
```powershell
.\git-setup.ps1
```

## Excluded Files

The following are excluded from git via `.gitignore`:
- Personal directories: `Desktop/`, `Pictures/`, `documents/`
- Media files: `*.jpg`, `*.png`, `*.jpeg`, `*.bmp`
- Executables: `*.exe`
- Documents: `*.pdf`, `*.docx`, `*.xlsx`, `*.one`, `*.url`
- Security: `*credentials*`, `*.token`, `*.secret`
- System files: `Thumbs.db`, `desktop.ini`, `.DS_Store`

## Cursor Rules

Cursor rules are organized in `.cursor/rules/`:
- **powershell-standards** - PowerShell coding standards
- **system-configuration** - System-specific information
- **automation-patterns** - Automation patterns and defaults
- **security-tokens** - Security and token management
- **github-desktop-integration** - GitHub Desktop rules

## Setup Scripts

### Workspace Setup
```powershell
.\setup-workspace.ps1
```
Verifies workspace configuration and structure.

### Windows Setup
```powershell
.\auto-setup.ps1
# or
.\complete-windows-setup.ps1
```
Configures Windows settings, security, and cloud sync.

### Git Setup
```powershell
.\git-setup.ps1
```
Initializes git and configures remotes.

## Next Steps

1. **Verify workspace**: Run `.\setup-workspace.ps1`
2. **Configure Windows**: Run `.\auto-setup.ps1` (as Administrator)
3. **Set up git**: Run `.\git-setup.ps1` if needed
4. **Review documentation**: Check `README.md` and other `.md` files

## Troubleshooting

### Workspace setup issues
- Check that you're in the correct directory: `C:\Users\USER\OneDrive`
- Verify PowerShell execution policy: `Get-ExecutionPolicy`
- Run as Administrator if needed

### Git issues
- Run `.\git-setup.ps1` to reconfigure git
- Check git status: `git status`
- Verify remote: `git remote -v`

### Cursor rules not working
- Verify rules exist in `.cursor/rules/`
- Check Cursor Settings → Rules, Commands
- Restart Cursor after adding rules

## References

- `README.md` - Main project documentation
- `AGENTS.md` - Cursor agent instructions
- `AUTOMATION-RULES.md` - Automation patterns
- `SYSTEM-INFO.md` - System specifications

---

**Created**: 2025-12-09  
**System**: NuNa (Windows 11 Home Single Language 25H2)

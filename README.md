# MetaTrader 5 Logs Organization

This directory contains organized log files from MetaTrader 5 terminal operations.

## Directory Structure

```
logs/
├── terminal/          # Daily terminal logs (YYYYMMDD.log format)
│   └── *.log         # Contains terminal, experts, and network activity logs
│
├── metaeditor/        # MetaEditor compilation logs
│   └── metaeditor.log # MQL5 compilation and build logs
│
└── hosting/           # Hosting service logs
    ├── hosting.6759730.experts/    # Expert Advisor hosting logs
    └── hosting.6759730.terminal/   # Terminal hosting logs
```

## Log Types

### Terminal Logs (`terminal/`)
- **Format**: `YYYYMMDD.log` (e.g., `20251227.log`)
- **Content**: 
  - Terminal startup/shutdown events
  - Expert Advisor (EA) loading/unloading
  - Network connections and authorization
  - Trading operations
  - System events

### MetaEditor Logs (`metaeditor/`)
- **File**: `metaeditor.log`
- **Content**:
  - MQL5 code compilation results
  - Build errors and warnings
  - Compilation timings

### Hosting Logs (`hosting/`)
- **Format**: `hosting.{ID}.{type}/YYYYMMDD.log`
- **Content**:
  - Expert Advisor execution logs (experts)
  - Terminal hosting service logs (terminal)
  - Remote hosting operations

## Notes

- Current day's log file (`YYYYMMDD.log`) may remain in the root directory if MetaTrader is actively writing to it
- Log files are automatically created by MetaTrader 5
- Old logs can be archived or deleted as needed to save disk space

## Automation

### PowerShell Script (No Dependencies Required)

Run the automated log organizer:
```powershell
.\organize-logs.ps1
```

This script will:
- Automatically move daily terminal logs to `terminal/`
- Organize MetaEditor logs to `metaeditor/`
- Move hosting directories to `hosting/`
- Skip files that are currently in use (locked by MT5)

### Google Jules Agent CLI (Advanced Automation)

For AI-powered automation and maintenance, see [setup-jules.md](setup-jules.md) for complete setup instructions.

**Quick Start:**
1. Install Node.js from https://nodejs.org/
2. Install Jules: `npm install -g @google/jules`
3. Authenticate: `jules login`
4. Connect GitHub repository at [jules.google.com](https://jules.google.com)

Once set up, delegate tasks to Jules:
```bash
jules remote new --repo YOUR_REPO_NAME --session "Automatically organize and maintain log file structure daily"
```

## Maintenance

To keep logs organized:
1. **Automated**: Run `.\organize-logs.ps1` manually or schedule it with Windows Task Scheduler
2. **AI-Powered**: Use Google Jules to create and maintain automated workflows
3. **Manual**: Periodically move any remaining daily logs from root to `terminal/`
4. Archive old logs (older than 30/60/90 days) if needed
5. Monitor disk space usage in the logs directory

## Files

- `organize-logs.ps1` - PowerShell script for automatic log organization
- `setup-jules.md` - Complete guide for setting up Google Jules Agent C# A6-9V Project Repository - Complete Device Setup

This repository contains the complete device skeleton structure, project blueprints, and setup scripts for the NuNa Windows 11 automation system, including the ZOLO-A6-9VxNUNA trading system.

## 📁 Project Structure

```
.
├── .cursor/                          # Cursor IDE Configuration
│   └── rules/                        # AI Assistant Rules
├── Scripts/                          # PowerShell Automation Scripts
│   ├── Setup Scripts/
│   ├── Git Scripts/
│   ├── Security Scripts/
│   ├── GitHub Desktop Scripts/
│   └── Utility Scripts/
├── Documentation/                    # Project Documentation
│   ├── DEVICE-SKELETON.md           # Complete device structure
│   ├── PROJECT-BLUEPRINTS.md         # Project blueprints
│   ├── SYSTEM-INFO.md               # System specifications
│   ├── WORKSPACE-SETUP.md           # Workspace setup guide
│   └── SET-REPOS-PRIVATE.md         # Instructions for private repos
├── vps-services/                     # VPS 24/7 Trading System Services
│   ├── exness-service.ps1           # Exness MT5 Terminal service
│   ├── research-service.ps1         # Perplexity AI research service
│   ├── website-service.ps1          # GitHub website service
│   ├── cicd-service.ps1             # CI/CD automation service
│   ├── mql5-service.ps1              # MQL5 Forge integration
│   └── master-controller.ps1       # Master service controller
├── projects/                         # Active development projects
│   ├── Google AI Studio/            # AI Studio related projects
│   └── LiteWriter/                  # LiteWriter application
├── project-scanner/                  # Project Discovery & Execution System
├── system-setup/                     # System Configuration & Optimization
├── storage-management/               # Storage and drive management tools
├── Document,sheed,PDF, PICTURE/     # Documentation and media
├── Secrets/                          # Protected credentials (not tracked in git)
└── TECHNO POVA 6 PRO/                # Device-specific files
```

## 🚀 Quick Start

### Complete Device Setup

Run the comprehensive device setup script:

```powershell
# Run as Administrator
.\complete-device-setup.ps1
```

This will set up:
- ✅ Workspace structure
- ✅ Windows configuration
- ✅ Cloud sync services
- ✅ Git repositories
- ✅ Security settings
- ✅ Cursor rules
- ✅ All automation projects

### VPS 24/7 Trading System

Start the complete 24/7 automated trading system:

```powershell
# Run as Administrator (fully automated, no user interaction)
.\auto-start-vps-admin.ps1
```

Or double-click: `AUTO-START-VPS.bat`

This will:
- ✅ Deploy all VPS services
- ✅ Start Exness MT5 Terminal
- ✅ Start Web Research Service (Perplexity AI)
- ✅ Start GitHub Website Service (ZOLO-A6-9VxNUNA)
- ✅ Start CI/CD Automation Service
- ✅ Start MQL5 Forge Integration
- ✅ Handle all errors automatically

### Windows Setup Automation

```powershell
# Run as Administrator
.\auto-setup.ps1
# or
.\complete-windows-setup.ps1
```

### Workspace Verification

```powershell
.\setup-workspace.ps1
```

## 📋 Features

### Windows Setup Scripts
- ✅ Configure Windows Account Sync
- ✅ Set up File Explorer preferences
- ✅ Configure default browser and apps
- ✅ Windows Defender exclusions for cloud folders
- ✅ Windows Firewall rules for cloud services
- ✅ Windows Security (Controlled Folder Access) configuration
- ✅ Cloud sync service verification (OneDrive, Google Drive, Dropbox)

### Git Automation
- ✅ Multi-remote repository support
- ✅ Automated git operations
- ✅ Secure credential management

### Security Validation
- ✅ Comprehensive security checks
- ✅ Token security validation
- ✅ Script integrity verification

### VPS 24/7 Trading System
- ✅ Exness MT5 Terminal (24/7 operation)
- ✅ Web Research Automation (Perplexity AI)
- ✅ GitHub Website Hosting (ZOLO-A6-9VxNUNA)
- ✅ CI/CD Automation (Python projects)
- ✅ MQL5 Forge Integration
- ✅ Automated error handling
- ✅ Auto-restart capabilities

### Project Scanner
- ✅ Scan all local drives for development projects
- ✅ Discover scripts, applications, and code projects
- ✅ Execute projects in the background
- ✅ Generate comprehensive reports

### System Setup & Optimization
- ✅ Drive cleanup and optimization
- ✅ Drive role assignment and permissions
- ✅ Registry optimizations
- ✅ Cursor IDE configuration
- ✅ MCP (Model Context Protocol) setup

## 🔒 Security

Sensitive files including credentials, API keys, certificates, and logs are automatically excluded from version control via `.gitignore`.

**Protected file types:**
- `.pem` files (certificates and keys)
- `.json` credential files
- `.csv` data exports
- Log files
- Screenshots
- Temporary files
- Personal directories and media files

## 📚 Documentation

- **DEVICE-SKELETON.md** - Complete device structure blueprint
- **PROJECT-BLUEPRINTS.md** - Detailed project blueprints
- **SYSTEM-INFO.md** - System specifications
- **WORKSPACE-SETUP.md** - Workspace setup guide
- **VPS-SETUP-GUIDE.md** - VPS 24/7 trading system guide
- **AUTOMATION-RULES.md** - Automation patterns
- **GITHUB-DESKTOP-RULES.md** - GitHub Desktop integration
- **MANUAL-SETUP-GUIDE.md** - Manual setup instructions

## 🏢 Organization

Managed by **A6-9V** organization for better control and collaboration.

## 📝 Accounts

- **Microsoft/Outlook**: Lengkundee01@outlook.com
- **Google/Gmail**: Lengkundee01@gmail.com
- **GitHub**: Mouy-leng / A6-9V

## 🔧 System Information

- **Device**: NuNa
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)
- **Architecture**: 64-bit x64-based processor

## 📦 Git Repositories

This workspace is connected to multiple repositories:

- **Primary (origin)**: https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-.git
- **Secondary 1 (bridges3rd)**: https://github.com/A6-9V/I-bride_bridges3rd.git
- **Secondary 2 (drive-projects)**: https://github.com/A6-9V/my-drive-projects.git

### Git Submodules

The following repositories are integrated as git submodules:

- **my-drive-projects**: https://github.com/A6-9V/my-drive-projects.git
  - Location: `./my-drive-projects/`
  - Contains drive project files and automation scripts
  
- **OS-Twin**: https://github.com/A6-9V/OS-Twin.git
  - Location: `./OS-Twin/`
  - Status: Repository placeholder (awaiting repository creation or access)
  - To initialize once available: `git submodule update --init --recursive`

## 🔐 Making Repositories Private

See **SET-REPOS-PRIVATE.md** for instructions on making repositories private.

## 📝 Notes

- This workspace is synchronized with OneDrive and Google Drive
- Duplicate files are excluded from version control
- All sensitive data is gitignored for security
- Complete device skeleton structure and blueprints included
- VPS 24/7 trading system fully automated

## License

This project is for personal use.

## Author

Lengkundee01 / A6-9V
LI
- `package.json` - Node.js package configuration (for Jules integration)
- `.gitignore` - Git ignore rules (excludes log files from version control)


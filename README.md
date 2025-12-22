# A6-9V Project Repository - Complete Device Setup

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

### GitHub Secrets Setup

For OAuth credentials and other sensitive configuration, use GitHub Secrets:

```powershell
# Automated setup with your credentials
.\setup-github-secrets.ps1 `
    -ClientId "YOUR_CLIENT_ID" `
    -ClientSecret "YOUR_CLIENT_SECRET"

# Or use environment variables
$env:OAUTH_CLIENT_ID = "YOUR_CLIENT_ID"
$env:OAUTH_CLIENT_SECRET = "YOUR_CLIENT_SECRET"
.\SETUP-GITHUB-SECRETS.bat
```

See **GITHUB-SECRETS-SETUP.md** for complete instructions on setting up GitHub repository secrets for secure credential management in GitHub Actions workflows.

## 📚 Documentation

- **DEVICE-SKELETON.md** - Complete device structure blueprint
- **PROJECT-BLUEPRINTS.md** - Detailed project blueprints
- **SYSTEM-INFO.md** - System specifications
- **WORKSPACE-SETUP.md** - Workspace setup guide
- **VPS-SETUP-GUIDE.md** - VPS 24/7 trading system guide
- **AUTOMATION-RULES.md** - Automation patterns
- **GITHUB-DESKTOP-RULES.md** - GitHub Desktop integration
- **GITHUB-SECRETS-SETUP.md** - GitHub secrets and OAuth setup
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

## 🗄️ Graph Database Architecture & Connection Diagram

### System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         COMPLETE SYSTEM ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐
│   LAPTOP (NuNa)      │         │   VPS (Remote)      │
│   Windows 11         │◄───────►│   24/7 Trading      │
│                      │  Git    │                     │
│  ┌────────────────┐  │  Sync   │  ┌────────────────┐ │
│  │ Python Engine  │  │         │  │ MT5 Terminal   │ │
│  │ - Strategies   │  │         │  │ - Execution    │ │
│  │ - Analysis     │  │         │  │ - Uptime       │ │
│  └────────────────┘  │         │  └────────────────┘ │
│         │            │         │         │            │
│  ┌──────▼──────────┐ │         │  ┌──────▼──────────┐ │
│  │ Trading Bridge  │ │         │  │ MQL5 EA        │ │
│  │ Python ↔ MQL5   │ │         │  │ PythonBridgeEA │ │
│  │ Port 5500       │ │         │  │ ZeroMQ Client  │ │
│  └─────────────────┘ │         │  └────────────────┘ │
└──────────────────────┘         └──────────────────────┘
         │                                   │
         └───────────────┬───────────────────┘
                         │
              ┌──────────▼──────────┐
              │   Graph Database     │
              │   (Relationship Map) │
              └──────────────────────┘
```

### Graph Database Structure

The system uses a graph-based relationship model to track connections between components:

```
                    ┌─────────────────┐
                    │  Main Controller │
                    │  (Orchestrator)  │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ VPS Services  │   │ Trading Bridge│   │ Cloud Sync    │
│               │   │               │   │               │
│ • Exness      │──►│ • Python      │──►│ • OneDrive   │
│ • Research    │   │ • MQL5        │   │ • Google     │
│ • Website     │   │ • ZeroMQ      │   │ • GitHub     │
│ • CI/CD       │   │ • Port 5500   │   │ • Dropbox    │
│ • MQL5 Forge  │   └───────────────┘   └───────────────┘
└───────────────┘
        │
        ▼
┌───────────────┐
│ Broker APIs   │
│               │
│ • Exness API  │
│ • Multi-Symbol│
│ • Risk Mgmt   │
└───────────────┘
```

### Connection Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONNECTION FLOW                              │
└─────────────────────────────────────────────────────────────────┘

[Python Strategy] 
      │
      │ Generate Signal
      ▼
[Signal Manager] ──► Queue & Validate
      │
      │ ZeroMQ (Port 5500)
      ▼
[MQL5 Bridge] ──► Receive & Process
      │
      │ Execute Trade
      ▼
[MT5 Terminal] ──► Order Execution
      │
      │ API Call
      ▼
[Broker API] ──► Exness/Other
      │
      │ Update Status
      ▼
[Graph DB] ──► Store Relationship
      │
      │ Log & Monitor
      ▼
[Background Service] ──► 24/7 Monitoring
```

### Component Relationships (Graph DB Model)

```
Nodes:
├── System
│   ├── Laptop (NuNa)
│   ├── VPS (Remote)
│   └── Cloud Services
│
├── Services
│   ├── Exness Service
│   ├── Research Service
│   ├── Website Service
│   ├── CI/CD Service
│   └── MQL5 Service
│
├── Trading Components
│   ├── Python Engine
│   ├── MQL5 Bridge
│   ├── Signal Manager
│   ├── Multi-Symbol Trader
│   └── Broker APIs
│
└── Data Stores
    ├── Configuration (JSON)
    ├── Logs (Files)
    ├── Trading Data (CSV/DB)
    └── Credentials (Windows Credential Manager)

Relationships:
├── Laptop ─[syncs]──► VPS
├── Python Engine ─[communicates]──► MQL5 Bridge
├── MQL5 Bridge ─[connects]──► MT5 Terminal
├── MT5 Terminal ─[executes]──► Broker API
├── Services ─[monitors]──► Trading Components
└── Graph DB ─[tracks]──► All Relationships
```

### Network Ports & Connections

| Component | Port | Protocol | Direction |
|-----------|------|----------|-----------|
| Trading Bridge | 5500 | TCP (ZeroMQ) | Bidirectional |
| Remote Desktop | 3389 | TCP (RDP) | Inbound |
| GitHub Sync | 443 | HTTPS | Outbound |
| Broker APIs | 443 | HTTPS | Outbound |
| OneDrive Sync | 443 | HTTPS | Outbound |

### Data Flow Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Strategy  │────►│   Signal    │────►│   Bridge   │
│  Analysis   │     │   Manager   │     │   Python   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              │ ZeroMQ
                                              ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Broker    │◄────│   MT5       │◄────│   Bridge   │
│   API       │     │   Terminal  │     │   MQL5     │
└─────────────┘     └─────────────┘     └─────────────┘
      │
      │ Store Results
      ▼
┌─────────────┐
│  Graph DB   │
│  (Relations)│
└─────────────┘
```

## 🔐 Making Repositories Private

See **SET-REPOS-PRIVATE.md** for instructions on making repositories private.

**Note**: This repository should be set to private for security. Use GitHub Settings → General → Danger Zone → Change visibility.

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

## Last Updated

**Last Repository Update**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

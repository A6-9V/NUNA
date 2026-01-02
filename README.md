# NUNA - Complete Drive Management & Windows Automation System

This repository combines **Google Drive cleanup tools** with the **A6-9V Windows automation system**, providing comprehensive drive management, cloud sync, and trading automation capabilities.

## 🎯 Core Features

### Drive Management Tools

#### Google Drive cleanup (safe-by-default)

Tools to **audit** your Google Drive, find **duplicate binary files**, and (optionally) move *selected* files to **Trash** with strong safety checks.

### Windows Automation System

Complete device skeleton structure, project blueprints, and setup scripts for the NuNa Windows 11 automation system, including the ZOLO-A6-9VxNUNA trading system.

## 📁 Project Structure

```
.
├── Python Drive Tools/
│   ├── gdrive_cleanup.py        # Google Drive audit/cleanup
│   └── dropbox_to_onedrive.py   # Dropbox to OneDrive migration
├── PowerShell Scripts/           # Windows automation scripts
├── trading-bridge/               # Trading Bridge & MQL.io System
├── vps-services/                 # VPS 24/7 Trading System Services
├── project-scanner/              # Project Discovery & Execution
├── system-setup/                 # System Configuration
├── storage-management/           # Storage and drive management
└── guidebook/                    # Documentation
```

---

## 🚀 Quick Start

### Option 1: Drive Management (Google Drive / Dropbox / OneDrive)

**Safety model**


- **Audit / duplicates** use **read-only** Drive scopes (`drive.metadata.readonly`).
- Nothing is ever permanently deleted.
- “Trash” requires:
  - a different OAuth scope (`drive`)
  - `--apply` (otherwise it’s a dry-run)
  - an **exact confirmation string** (`TRASH <n> FILES`)
  - an explicit list of file IDs you prepared yourself

## Setup

### 1) Create OAuth credentials

In Google Cloud Console:

- **APIs & Services → Library**: enable **Google Drive API**
- **APIs & Services → Credentials**: create **OAuth client ID**
  - Application type: **Desktop app**
  - Download JSON and save it as `./credentials.json` (repo root)

### 2) Install dependencies

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```


---

### Option 2: Complete Windows Device Setup

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
- ✅ All automation projects

### Option 3: VPS 24/7 Trading System

Start the complete 24/7 automated trading system:

```powershell
# Run as Administrator (fully automated, no user interaction)
.\auto-start-vps-admin.ps1
```

Or double-click: `AUTO-START-VPS.bat`

---

## 📚 Usage Guides

### Google Drive Tools

#### Audit: find largest files (read-only)

```bash
python3 gdrive_cleanup.py audit --top 25 --show-links
```

Export a full CSV/JSON inventory:

```bash
python3 gdrive_cleanup.py audit --csv gdrive-report.csv --json gdrive-report.json
```

### Find duplicates (read-only)

This uses Drive’s `md5Checksum`, which typically exists for **uploaded binary files** (photos, videos, PDFs, zips, etc.). Many Google Docs formats won’t have an MD5.

```bash
python3 gdrive_cleanup.py duplicates --show 20 --show-per-group 10
```

It also writes a review file by default:

- `gdrive-plan-<timestamp>.json`

### Trash selected files (carefully)

1) Create a small JSON containing the IDs you want to trash:

```json
{
  "fileIds": [
    "FILE_ID_1",
    "FILE_ID_2"
  ]
}
```

2) Dry-run first (no changes):

```bash
python3 gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES"
```

3) Apply (moves items to Trash):

```bash
python3 gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES" --apply
```

### Trash by search (example: delete all “pgoto”)

If you meant “delete everything matching **pgoto**”, this command will **move matching items to Trash** (not permanent delete).

1) Dry-run to see what would be trashed (prints the required confirmation string):

```bash
python3 gdrive_cleanup.py trash-query --name-contains pgoto --show 50 --ids-out pgoto_ids.json
```

2) Re-run with the exact confirm string it prints and `--apply`:

```bash
python3 gdrive_cleanup.py trash-query --name-contains pgoto --confirm "TRASH <n> FILES" --apply
```

## Optional filtering with Drive queries

All commands accept `--query`, which is passed to Drive’s `files.list(q=...)`. Examples:

- Only items in a folder:
  - `--query "'<FOLDER_ID>' in parents"`
- Only PDFs:
  - `--query "mimeType='application/pdf'"`
- Only large files (note: size is bytes):
  - `--query "size > 1073741824"`


---

### Windows Automation Features

- ✅ Configure Windows Account Sync
- ✅ Set up File Explorer preferences
- ✅ Configure default browser and apps
- ✅ Windows Defender exclusions for cloud folders
- ✅ Windows Firewall rules for cloud services
- ✅ Cloud sync service verification (OneDrive, Google Drive, Dropbox)
- ✅ Multi-remote repository support
- ✅ Automated git operations
- ✅ Auto-merge for pull requests
- ✅ GitHub Actions workflows

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

---

## 🔧 System Information

- **Device**: NuNa
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)
- **Architecture**: 64-bit x64-based processor

## 📦 Git Repositories

This workspace is connected to multiple repositories:

- **Primary (origin)**: https://github.com/A6-9V/NUNA
- **Secondary 1 (bridges3rd)**: https://github.com/A6-9V/I-bride_bridges3rd.git
- **Secondary 2 (drive-projects)**: https://github.com/A6-9V/my-drive-projects.git

---

## 🗄️ System Architecture

### Graph Database Architecture & Connection Diagram

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
```

### Network Ports & Connections

| Component | Port | Protocol | Direction |
|-----------|------|----------|-----------|
| Trading Bridge | 5500 | TCP (ZeroMQ) | Bidirectional |
| Remote Desktop | 3389 | TCP (RDP) | Inbound |
| GitHub Sync | 443 | HTTPS | Outbound |
| Broker APIs | 443 | HTTPS | Outbound |
| OneDrive Sync | 443 | HTTPS | Outbound |

---

## 🔒 Security

- This tool includes “Shared drives” results as well (`supportsAllDrives=true`). If you don’t have permission to trash an item, it will fail and be reported.
- The token cache (`token.json`) and OAuth secrets (`credentials.json`) are ignored by git via `.gitignore`.

## Dropbox → OneDrive import

If you have a Dropbox shared-folder link and want it copied into your OneDrive, use `dropbox_to_onedrive.py`.

### OneDrive setup (Microsoft Graph)

1) In Azure Portal → **App registrations** → **New registration**
   - Supported account types: pick what matches you (or use “Accounts in any organizational directory and personal Microsoft accounts”)
2) In the app → **Authentication**
   - Enable **Allow public client flows** (device-code login)
3) In the app → **API permissions** → **Microsoft Graph** → **Delegated permissions**
   - Add: `Files.ReadWrite.All`
   - Add: `User.Read`

Then copy the **Application (client) ID** and set it as an environment variable:

```bash
export ONEDRIVE_CLIENT_ID="YOUR_CLIENT_ID"
```

### Run the import

Dry-run (no uploads, just shows what will be uploaded):

```bash
python3 dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --dry-run
```

Upload into a named folder in your OneDrive root:

```bash
python3 dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --onedrive-folder "Dropbox Import"
```

The script will print a **device login code** and URL the first time; complete that in your browser to authorize OneDrive access.

## Optional: run a Windows VM locally (Docker/KVM)

If you need a **real Windows environment** (for example, to use Windows-only tooling alongside this repo), you can run a local Windows VM using the upstream project `dockur/windows`:

- Repo: `https://github.com/dockur/windows`

### Drive Tool Notes

- This tool includes "Shared drives" results as well (`supportsAllDrives=true`). If you don't have permission to trash an item, it will fail and be reported.
- The token cache (`token.json`) and OAuth secrets (`credentials.json`) are ignored by git via `.gitignore`.

### Windows VM (Optional)

If you need a **real Windows environment** (for example, to use Windows-only tooling alongside this repo), you can run a local Windows VM using the upstream project `dockur/windows`:

- Repo: `https://github.com/dockur/windows`

Notes:

- This requires a **Linux host with hardware virtualization** enabled and access to **KVM** (`/dev/kvm`).
- Follow the upstream README for the current recommended `docker run` / compose configuration and Windows version/ISO options.

### Windows Automation Notes

- This workspace is synchronized with OneDrive and Google Drive
- Duplicate files are excluded from version control
- All sensitive data is gitignored for security
- Complete device skeleton structure and blueprints included
- VPS 24/7 trading system fully automated

---

## License

This project is for personal use.

## Author

Lengkundee01 / A6-9V

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
│   ├── mql5-service.ps1             # MQL5 Forge integration
│   └── master-controller.ps1        # Master service controller
├── trading-bridge/                   # Trading Bridge & MQL.io System
│   ├── python/                      # Python trading components
│   │   ├── bridge/                  # MQL5 bridge
│   │   ├── brokers/                 # Broker APIs
│   │   ├── mql_io/                  # MQL.io service (NEW)
│   │   ├── services/                # Background services
│   │   └── trader/                  # Multi-symbol trader
│   ├── mql5/                        # MQL5 Expert Advisors
│   ├── config/                      # Configuration
│   └── MQL-IO-README.md             # MQL.io documentation
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

### MQL.io Service (NEW)

Start the MQL5 operations management service:

```powershell
.\start-mql-io-service.ps1
```

Or double-click: `START-MQL-IO-SERVICE.bat`

MQL.io provides:
- ✅ Expert Advisor monitoring and management
- ✅ Script execution tracking
- ✅ Indicator monitoring
- ✅ Operations logging
- ✅ API interface for programmatic access
- ✅ Auto-recovery (optional)

See `trading-bridge/MQL-IO-README.md` for complete documentation.

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
- ✅ Auto-merge for pull requests
- ✅ GitHub Actions workflows

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
- **AUTO-MERGE-SETUP-GUIDE.md** - Automatic PR merging setup
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

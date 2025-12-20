# Device Skeleton Structure - NuNa

Complete device structure blueprint for Windows 11 automation and setup system.

## Device Information

- **Device Name**: NuNa
- **Device ID**: 32680105-F98A-49B6-803C-8A525771ABA3
- **Product ID**: 00356-24782-61221-AAOEM
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)
- **Architecture**: 64-bit x64-based processor

## Workspace Structure

```
C:\Users\USER\OneDrive\
├── .cursor/                          # Cursor IDE Configuration
│   └── rules/                        # AI Assistant Rules
│       ├── powershell-standards/     # PowerShell coding standards
│       ├── system-configuration/     # System-specific information
│       ├── automation-patterns/      # Automation patterns
│       ├── security-tokens/          # Security and token management
│       └── github-desktop-integration/ # GitHub Desktop rules
│
├── Scripts/                          # PowerShell Automation Scripts
│   ├── Setup Scripts/
│   │   ├── auto-setup.ps1            # Automated Windows setup
│   │   ├── complete-windows-setup.ps1 # Complete system configuration
│   │   ├── setup-cloud-sync.ps1     # Cloud sync configuration
│   │   ├── setup-workspace.ps1      # Workspace verification
│   │   └── run-all-auto.ps1         # Master orchestrator
│   │
│   ├── Git Scripts/
│   │   ├── git-setup.ps1             # Git repository setup
│   │   ├── auto-git-push.ps1        # Automated git push
│   │   └── clone-repo.ps1            # Repository cloning
│   │
│   ├── Security Scripts/
│   │   ├── security-check.ps1        # Security validation
│   │   ├── plugin-protection.ps1     # Plugin security
│   │   └── run-security-check.ps1    # Security master script
│   │
│   ├── GitHub Desktop Scripts/
│   │   ├── github-desktop-setup.ps1  # GitHub Desktop configuration
│   │   └── check-github-desktop-updates.ps1 # Update checker
│   │
│   ├── Utility Scripts/
│   │   ├── open-settings.ps1         # Open Windows settings
│   │   ├── check-cloud-services.ps1  # Cloud service status
│   │   ├── run-cursor-admin.ps1      # Launch Cursor as admin
│   │   ├── run-vscode-admin.ps1      # Launch VSCode as admin
│   │   ├── launch-admin.ps1          # Admin launcher
│   │   └── debug-and-save.ps1        # Debug and validation
│   │
│   └── Batch Files/
│       ├── RUN-COMPLETE-SETUP.bat    # Complete setup launcher
│       ├── RUN-AUTO-SETUP.bat        # Auto setup launcher
│       ├── RUN-ME-AS-ADMIN.bat       # Admin batch launcher
│       └── run-as-admin.bat           # Admin runner
│
├── Documentation/                    # Project Documentation
│   ├── README.md                     # Main project documentation
│   ├── AGENTS.md                     # Cursor AI agent instructions
│   ├── SYSTEM-INFO.md                # System specifications
│   ├── AUTOMATION-RULES.md           # Automation patterns
│   ├── GITHUB-DESKTOP-RULES.md      # GitHub Desktop integration
│   ├── CURSOR-RULES-SETUP.md        # Cursor rules documentation
│   ├── MANUAL-SETUP-GUIDE.md        # Manual setup instructions
│   ├── DEBUG-SUMMARY.md              # Debug and troubleshooting
│   ├── WORKSPACE-SETUP.md           # Workspace setup guide
│   ├── DEVICE-SKELETON.md           # This file
│   └── PROJECT-BLUEPRINTS.md        # Project blueprints
│
├── Configuration/                    # Configuration Files
│   ├── .gitignore                    # Git exclusions
│   ├── .cursorignore                # Cursor indexing exclusions
│   ├── SETUP-INSTRUCTIONS.txt       # Setup instructions
│   └── elevate.vbs                  # UAC elevation helper
│
└── Security/                         # Security Files (gitignored)
    └── git-credentials.txt           # GitHub PAT fallback (never committed; prefer OAuth via GitHub CLI/Desktop)
```

## System Paths

### Standard Paths
- **Workspace**: `C:\Users\USER\OneDrive`
- **Program Files**: `C:\Program Files`
- **Program Files (x86)**: `C:\Program Files (x86)` (if applicable)
- **Local AppData**: `C:\Users\USER\AppData\Local`
- **AppData**: `C:\Users\USER\AppData\Roaming`
- **OneDrive**: `C:\Users\USER\OneDrive`

### Application Paths
- **GitHub Desktop**: `%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe`
- **Chrome**: `%PROGRAMFILES%\Google\Chrome\Application\chrome.exe`
- **Edge**: `%PROGRAMFILES%\Microsoft\Edge\Application\msedge.exe`
- **OneDrive**: `%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe`
- **Google Drive**: `%PROGRAMFILES%\Google\Drive File Stream\googledrivesync.exe`

## Cloud Services Configuration

### OneDrive
- **Account**: Lengkundee01@outlook.com
- **Path**: `C:\Users\USER\OneDrive`
- **Sync**: Enabled for all folders

### Google Drive
- **Account**: Lengkundee01@gmail.com
- **Path**: `%PROGRAMFILES%\Google\Drive File Stream\googledrivesync.exe`
- **Sync**: File Stream enabled

### Dropbox (if installed)
- **Path**: `%LOCALAPPDATA%\Dropbox\bin\Dropbox.exe`
- **Sync**: Enabled

## Git Configuration

### Repository Information
- **Primary Remote**: `https://github.com/Mouy-leng/Window-setup.git`
- **Secondary Remote 1**: `https://github.com/A6-9V/I-bride_bridges3rd.git`
- **Secondary Remote 2**: `https://github.com/A6-9V/my-drive-projects.git`
- **User**: Mouy-leng
- **Email**: Mouy-leng@users.noreply.github.com
- **Branch**: main

## Security Configuration

### Windows Defender Exclusions
- OneDrive folder
- Google Drive folder
- Dropbox folder (if installed)
- Workspace directory

### Windows Firewall Rules
- OneDrive sync
- Google Drive sync
- Dropbox sync (if installed)

### Windows Security (Controlled Folder Access)
- Cloud sync folders allowed
- Development tools allowed

## Development Tools

### IDEs
- **Cursor**: Primary IDE with AI assistance
- **VSCode**: Secondary IDE
- **GitHub Desktop**: Git GUI client

### Version Control
- **Git**: Command-line version control
- **GitHub Desktop**: GUI version control
- **GitHub CLI**: Command-line GitHub operations

## Automation Workflow

1. **Initial Setup**: `auto-setup.ps1` or `complete-windows-setup.ps1`
2. **Workspace Verification**: `setup-workspace.ps1`
3. **Security Check**: `run-security-check.ps1`
4. **Git Operations**: `auto-git-push.ps1`
5. **Master Orchestrator**: `run-all-auto.ps1`

## File Exclusions

### Git Ignored
- Personal directories: `Desktop/`, `Pictures/`, `documents/`
- Media files: `*.jpg`, `*.png`, `*.jpeg`, `*.bmp`
- Executables: `*.exe`
- Documents: `*.pdf`, `*.docx`, `*.xlsx`, `*.one`, `*.url`
- Security: `*credentials*`, `*.token`, `*.secret`
- System files: `Thumbs.db`, `desktop.ini`, `.DS_Store`

## Environment Variables

- `$env:USERPROFILE` → `C:\Users\USER`
- `$env:PROGRAMFILES` → `C:\Program Files`
- `$env:LOCALAPPDATA` → `C:\Users\USER\AppData\Local`
- `$env:APPDATA` → `C:\Users\USER\AppData\Roaming`
- `$env:OneDrive` → `C:\Users\USER\OneDrive`

## PowerShell Configuration

- **Version**: PowerShell 5.1 or later
- **Execution Policy**: `RemoteSigned`
- **Script Location**: `C:\Users\USER\OneDrive\`
- **Error Handling**: Try-catch blocks in all scripts
- **Output Format**: Color-coded status messages

## Network Configuration

### Accounts
- **Microsoft/Outlook**: Lengkundee01@outlook.com
- **Google/Gmail**: Lengkundee01@gmail.com
- **GitHub**: Mouy-leng

### Sync Settings
- Windows Account Sync: Enabled
- Browser Sync: Enabled (Chrome/Edge)
- Cloud Sync: Enabled (OneDrive, Google Drive)

## Maintenance

### Regular Tasks
- Run `setup-workspace.ps1` to verify structure
- Run `run-security-check.ps1` for security validation
- Run `check-github-desktop-updates.ps1` for updates
- Run `check-cloud-services.ps1` for cloud status

### Backup Strategy
- OneDrive sync for workspace
- Git repository for version control
- Cloud services for redundancy

---

**Created**: 2025-12-09  
**System**: NuNa (Windows 11 Home Single Language 25H2)  
**Last Updated**: 2025-12-09

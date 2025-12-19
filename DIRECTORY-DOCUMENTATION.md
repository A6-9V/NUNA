### Directory Document (Administrator / Owner)

- **Owner / Admin**: `lengkundee01@outlook.com` (administrator / admin, owner)
- **Workspace root**: `/workspace` (git repo)
- **Primary purpose**: Windows 11 (NuNa) automation + VPS/trading services + storage/project utilities
- **Last updated**: 2025-12-19

### Quick orientation

- **Most automation is Windows-first** (`*.ps1`, `*.bat`). On Linux, treat this repo primarily as a source of scripts/docs unless you’re explicitly running PowerShell Core.
- **Start points** (owner/admin):
  - `START-TRADING-SYSTEM-COMPLETE.ps1`, `QUICK-START-TRADING-SYSTEM.ps1` / `.bat`
  - `START-EVERYTHING.bat`, `run-all-auto.ps1`
  - `setup-*-*.ps1` and `verify-*-*.ps1` scripts for configuration and validation
- **Security baseline**: secrets/tokens must remain excluded via `.gitignore` (see `trading-bridge/config/*.example` for safe templates).

### Top-level layout (high signal)

```
/workspace/
├── .cursor/                      # Cursor rules that guide automation/security standards
├── .vscode/                      # Editor settings
├── project-scanner/              # Multi-drive project discovery/execution utilities
├── storage-management/           # Drive backup/sync/monitoring tools + guides
├── system-setup/                 # Device setup/registry/drive-role automation
├── trading-bridge/               # Python↔MQL5 bridge + broker config templates
├── vps-services/                 # Service-like scripts for 24/7 VPS operations
├── support-portal/               # Small JS/CSS portal (app/config/styles)
├── projects/                     # Active work area (notes/assets/projects)
├── Document,sheed,PDF, PICTURE/  # Mixed documentation/media workspace folder
├── TECHNO POVA 6 PRO/            # Device-specific exports/assets
└── *.ps1 / *.bat / *.md / *.txt  # Root orchestration scripts + documentation
```

### Directory-by-directory guide

### `.cursor/`

- **What it is**: Cursor AI rules and standards.
- **Key path**: `.cursor/rules/` (PowerShell standards, token security, trading security, GitHub Desktop integration).
- **Owner/admin notes**:
  - Treat these as “policy”: they govern safe script changes (especially tokens/credentials).

### `.vscode/`

- **What it is**: Workspace editor configuration.

### `project-scanner/`

- **What it is**: Discovers projects across drives and can execute/summarize them.
- **Key files**: `project-scanner.ps1`, `project-executor.ps1`, `run-all-projects.ps1`, `scanner-config.json`.
- **Owner/admin notes**:
  - Output/log directories are intentionally ignored by git (see `.gitignore`).

### `storage-management/`

- **What it is**: Storage/backup/sync utilities with production/sandbox flows.
- **Key subfolders**:
  - `production/`: operational scripts and guides
  - `sandbox/`: testing harnesses
  - `storage-tools/`: backup/monitor/cleanup utilities

### `system-setup/`

- **What it is**: End-to-end system setup helpers.
- **Key files**:
  - `complete-setup.ps1` (orchestrator)
  - `apply-registry-settings.ps1`, `apply-drive-roles.ps1`, `cleanup-all-drives.ps1`
  - `mcp-config.json`, `cursor-settings.json`

### `trading-bridge/`

- **What it is**: Trading bridge stack (Python packages + MQL5 expert/include), plus setup/security docs.
- **Key areas**:
  - `python/`: broker adapters, services, security credential manager, bridge logic
  - `mql5/`: `Experts/` and `Include/` integration
  - `config/`: **templates** only (`brokers.json.example`, `symbols.json.example`)
- **Owner/admin notes**:
  - Real configs are intentionally gitignored:
    - `trading-bridge/config/brokers.json`
    - `trading-bridge/config/symbols.json`
  - Keep secrets out of repo; use example files as a safe starting point.

### `vps-services/`

- **What it is**: “Service scripts” for always-on VPS operation.
- **Key files**: `master-controller.ps1`, `exness-service.ps1`, `trading-bridge-service.ps1`, `website-service.ps1`, `cicd-service.ps1`.

### `support-portal/`

- **What it is**: Lightweight web UI.
- **Files**: `app.js`, `config.js`, `styles.css`.

### `projects/`

- **What it is**: Active work area / experiments / notes.
- **Current content**: `Google AI Studio/` materials and images.

### `Document,sheed,PDF, PICTURE/`

- **What it is**: Mixed documentation/media staging folder.
- **Owner/admin notes**:
  - Large/media/personal files are often excluded by `.gitignore`; keep this folder tidy to avoid accidental commits.

### `TECHNO POVA 6 PRO/`

- **What it is**: Device-specific exports (phone/device artifacts).
- **Owner/admin notes**:
  - Treat as potentially sensitive; avoid committing private data.

### Root scripts and docs (what to use first)

- **Core docs**: `README.md`, `DEVICE-SKELETON.md`, `PROJECT-BLUEPRINTS.md`, `SYSTEM-INFO.md`, `VPS-SETUP-GUIDE.md`.
- **Common admin scripts**:
  - Setup: `complete-windows-setup.ps1`, `setup-*.ps1`, `system-setup/complete-setup.ps1`
  - Security: `security-check.ps1`, `run-security-check.ps1`
  - Trading: `setup-trading-system.ps1`, `verify-trading-system.ps1`, `START-TRADING-SYSTEM-COMPLETE.ps1`
  - Git/GitHub Desktop: `PUSH-TO-GITHUB.ps1`, `check-github-desktop-updates.ps1`, `github-desktop-setup.ps1`

### Security and owner/admin responsibilities

- **Never commit**: tokens, credentials, keys, broker configs, logs, data exports.
- **Use templates**: `trading-bridge/config/*.example` then create local real configs (gitignored).
- **Review `.gitignore`** before adding new tooling that produces logs/artifacts.

### Known artifact in this workspace

- `core` is a **Linux core dump** (`ELF ... core file ... from 'light-locker'`). It is not part of the project source; it’s safe to delete and should be ignored going forward.

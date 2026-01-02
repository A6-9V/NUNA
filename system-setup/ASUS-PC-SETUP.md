# ASUS PC Complete Setup Guide
**Comprehensive System Configuration for ASUS Devices**

## 📋 Table of Contents
1. [Initial Setup](#initial-setup)
2. [Drive Configuration & Roles](#drive-configuration--roles)
3. [Registry Settings](#registry-settings)
4. [MCP (Model Context Protocol) Setup](#mcp-setup)
5. [Cursor IDE Configuration](#cursor-ide-configuration)
6. [System Optimization](#system-optimization)
7. [Security & Permissions](#security--permissions)

---

## 🚀 Initial Setup

### 1. ASUS-Specific Drivers & Software

```powershell
# Install ASUS System Control Interface
# Download from: https://www.asus.com/support/download-center/

# Essential ASUS Software:
# - ASUS Armoury Crate (System Control)
# - ASUS AI Suite (Performance Tuning)
# - MyASUS (Support & Updates)
# - ASUS Live Update (Driver Updates)
```

### 2. BIOS/UEFI Configuration

**Recommended BIOS Settings:**
- **Fast Boot**: Enabled
- **Secure Boot**: Enabled (for security)
- **TPM**: Enabled (for Windows 11)
- **Virtualization**: Enabled (for WSL/Docker)
- **SATA Mode**: AHCI
- **USB Legacy Support**: Disabled (if not needed)

### 3. Windows 11 Optimization

```powershell
# Disable unnecessary startup programs
Get-CimInstance Win32_StartupCommand | Where-Object { $_.Command -like "*ASUS*" } | Select-Object Name, Command

# Optimize power settings for performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance
```

---

## 💾 Drive Configuration & Roles

### Drive Role Assignment

| Drive | Role | Purpose | Permissions |
|-------|------|---------|-------------|
| **C:** | OS & System | Windows, Programs, System Files | Admin Only |
| **D:** | Projects & Development | Code, Projects, Git Repos | User: Full Control |
| **F:** | Code Workspace | Active Development | User: Full Control |
| **G:** | Domain Controller | System Management | Admin: Full Control |
| **I:** | Backup & Storage | Archives, Backups | User: Read/Write |

### Setting Drive Permissions

```powershell
# D: Drive - Projects (Full User Access)
$acl = Get-Acl "D:\"
$permission = "BUILTIN\Users","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "D:\" $acl

# F: Drive - Code Workspace (Full User Access)
$acl = Get-Acl "F:\"
$permission = "BUILTIN\Users","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "F:\" $acl

# G: Drive - Domain Controller (Admin Only)
$acl = Get-Acl "G:\"
$permission = "BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "G:\" $acl

# I: Drive - Backup (Read/Write User Access)
$acl = Get-Acl "I:\"
$permission = "BUILTIN\Users","Modify","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "I:\" $acl
```

### Drive Labels & Organization

```powershell
# Set drive labels
Set-Volume -DriveLetter D -NewFileSystemLabel "PROJECTS"
Set-Volume -DriveLetter F -NewFileSystemLabel "CODE"
Set-Volume -DriveLetter G -NewFileSystemLabel "DOMAIN_CONTROLLER"
Set-Volume -DriveLetter I -NewFileSystemLabel "BACKUP"
```

---

## 🔧 Registry Settings

### Performance Optimizations

```powershell
# Registry path for system optimizations
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control"

# Disable unnecessary visual effects
Set-ItemProperty -Path "$regPath\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 1
Set-ItemProperty -Path "$regPath\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 1

# Optimize for performance
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

# Disable Windows Search indexing on non-OS drives (optional)
# This can improve performance on large drives
```

### ASUS-Specific Registry Tweaks

```powershell
# ASUS Power Management
$asusRegPath = "HKLM:\SOFTWARE\ASUS"

# Optimize ASUS services
Set-ItemProperty -Path "$asusRegPath\ASUS System Control Interface" -Name "AutoStart" -Value 0 -ErrorAction SilentlyContinue

# Disable unnecessary ASUS notifications
Set-ItemProperty -Path "HKCU:\Software\ASUS" -Name "ShowNotifications" -Value 0 -ErrorAction SilentlyContinue
```

### Developer-Friendly Registry Settings

```powershell
# Show file extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# Show hidden files
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Enable Developer Mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1
```

### Complete Registry Script

Save as `apply-registry-settings.ps1`:

```powershell
# Run as Administrator
Write-Host "Applying registry optimizations..." -ForegroundColor Cyan

# Performance
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Developer Mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1

Write-Host "Registry settings applied!" -ForegroundColor Green
```

---

## 🤖 MCP (Model Context Protocol) Setup

### What is MCP?

Model Context Protocol (MCP) is a protocol for connecting AI assistants to external data sources and tools.

### Installation

```powershell
# Install MCP Server (if using Node.js)
npm install -g @modelcontextprotocol/server

# Or install via Python
pip install mcp
```

### Configuration

Create `%APPDATA%\Cursor\User\globalStorage\mcp.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "D:\\"],
      "env": {}
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token-here"
      }
    },
    "drive-scanner": {
      "command": "powershell",
      "args": [
        "-ExecutionPolicy", "Bypass",
        "-File", "D:\\my-drive-projects\\project-scanner\\project-scanner.ps1"
      ],
      "env": {}
    }
  }
}
```

**Security note**: keep tokens local-only (never commit). Preferred: authenticate via GitHub CLI OAuth (`gh auth login`) and use `gh auth token` to obtain a token value for MCP if needed.

### Cursor Integration

1. Open Cursor Settings
2. Navigate to **Features** → **MCP**
3. Enable MCP servers
4. Configure server paths

### MCP Server for Drive Management

Create `D:\my-drive-projects\system-setup\mcp-drive-server.js`:

```javascript
// MCP Server for Drive Management
const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");

const server = new Server({
  name: "drive-manager",
  version: "1.0.0",
}, {
  capabilities: {
    tools: {},
  },
});

// Tool: List all drives
server.setRequestHandler("tools/list", async (request) => {
  return {
    tools: [
      {
        name: "list_drives",
        description: "List all available drives",
      },
      {
        name: "cleanup_drive",
        description: "Cleanup a specific drive",
      },
    ],
  };
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Drive Manager MCP Server running on stdio");
}

main().catch(console.error);
```

---

## 🎨 Cursor IDE Configuration

### Settings Location

**Windows**: `%APPDATA%\Cursor\User\settings.json`

### Recommended Settings

```json
{
  "editor.fontSize": 14,
  "editor.fontFamily": "'Cascadia Code', 'Fira Code', Consolas, monospace",
  "editor.fontLigatures": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/.venv": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/*.code-search": true
  },
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.cwd": "D:\\my-drive-projects",
  "workbench.startupEditor": "newUntitledFile",
  "workbench.colorTheme": "Default Light+",
  "extensions.autoUpdate": true,
  "mcp.enabled": true,
  "mcp.servers": {
    "filesystem": {
      "enabled": true,
      "path": "D:\\"
    }
  }
}
```

### Workspace Settings

Create `.vscode/settings.json` in your project root:

```json
{
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/venv/**": true,
    "**/.venv/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/*.code-search": true,
    "**/dist": true,
    "**/build": true
  },
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true
  }
}
```

### Keybindings

Create `keybindings.json`:

```json
[
  {
    "key": "ctrl+shift+p",
    "command": "workbench.action.quickOpen"
  },
  {
    "key": "ctrl+`",
    "command": "workbench.action.terminal.toggleTerminal"
  },
  {
    "key": "ctrl+shift+d",
    "command": "workbench.action.debug.start"
  }
]
```

### Extensions Recommendations

```json
{
  "recommendations": [
    "ms-powershell.powershell",
    "ms-python.python",
    "ms-vscode.vscode-typescript-next",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "github.copilot",
    "github.copilot-chat"
  ]
}
```

---

## ⚡ System Optimization

### Windows Services Optimization

```powershell
# Disable unnecessary services
$servicesToDisable = @(
    "Fax",
    "WSearch",  # Windows Search (if not needed)
    "TabletInputService",
    "XblAuthManager",
    "XblGameSave"
)

foreach ($service in $servicesToDisable) {
    Stop-Service -Name $service -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
}
```

### Startup Optimization

```powershell
# Check startup programs
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize

# Disable specific startup items (example)
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Get-ChildItem $startupPath | Where-Object { $_.Name -like "*unnecessary*" } | Remove-Item
```

### Memory & Performance

```powershell
# Clear system cache
Clear-DnsClientCache
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# Optimize drives
Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
    Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -ReTrim -ErrorAction SilentlyContinue
}
```

---

## 🔒 Security & Permissions

### User Account Setup

```powershell
# Create development user (if needed)
# New-LocalUser -Name "Developer" -Description "Development Account" -Password (ConvertTo-SecureString "Password123!" -AsPlainText -Force)

# Add to Administrators group (if needed)
# Add-LocalGroupMember -Group "Administrators" -Member "Developer"
```

### Firewall Rules

```powershell
# Allow development ports
New-NetFirewallRule -DisplayName "Development Ports" -Direction Inbound -LocalPort 3000,8000,8080,5000 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
```

### BitLocker (if enabled)

```powershell
# Check BitLocker status
Get-BitLockerVolume

# Enable BitLocker for specific drives (optional)
# Enable-BitLocker -MountPoint "D:" -EncryptionMethod XtsAes256 -UsedSpaceOnly
```

---

## 📝 Quick Setup Script

Save as `complete-asus-setup.ps1`:

```powershell
# Run as Administrator
Write-Host "=== ASUS PC Complete Setup ===" -ForegroundColor Cyan

# 1. Drive Permissions
Write-Host "Setting drive permissions..." -ForegroundColor Yellow
# (Include drive permission scripts from above)

# 2. Registry Settings
Write-Host "Applying registry settings..." -ForegroundColor Yellow
# (Include registry scripts from above)

# 3. System Optimization
Write-Host "Optimizing system..." -ForegroundColor Yellow
# (Include optimization scripts from above)

# 4. Cursor Configuration
Write-Host "Configuring Cursor IDE..." -ForegroundColor Yellow
# Copy settings.json to Cursor directory

Write-Host "Setup complete!" -ForegroundColor Green
```

---

## 🔗 Additional Resources

- **ASUS Support**: https://www.asus.com/support/
- **MCP Documentation**: https://modelcontextprotocol.io
- **Cursor Documentation**: https://cursor.sh/docs
- **Windows 11 Optimization**: https://docs.microsoft.com/en-us/windows

---

**Last Updated**: November 27, 2025  
**System**: ASUS Device with Windows 11  
**Drives**: C:, D:, F:, G:, I:


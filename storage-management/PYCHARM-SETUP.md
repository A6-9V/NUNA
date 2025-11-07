# PyCharm Project Setup for DC Sync Management
# Instructions for team members

## 🚀 PyCharm Setup Instructions

### 1. Open Project in PyCharm
```
File -> Open -> Navigate to "H:\My Drive\storage-management"
Select the folder and click OK
```

### 2. Configure Python Interpreter
```
File -> Settings -> Project -> Python Interpreter
Add New Interpreter -> System Interpreter
Select your Python installation (should detect automatically)
```

### 3. Install Required Packages
Open PyCharm terminal and run:
```bash
pip install jupyter notebook jupyterlab ipython
```

### 4. Configure Jupyter in PyCharm
```
File -> Settings -> Languages & Frameworks -> Jupyter
Server URL: http://localhost:8888
Token: (will be provided when starting Jupyter)
```

### 5. PowerShell Support
```
File -> Settings -> Plugins
Search for "PowerShell" and install
Restart PyCharm if prompted
```

## 📁 Project Structure Overview

```
storage-management/
├── sandbox/                    # Sandbox testing files
│   ├── DC-Sync-Sandbox.ps1    # Main sandbox script  
│   ├── DC-Sandbox-Testing.ipynb # Interactive notebook
│   └── DC-Sandbox-Launcher.ps1  # Quick launcher
├── production/                 # Production scripts
│   ├── DC-Sync.ps1            # Main DC sync script
│   ├── Transfer-Helper.ps1    # Transfer automation
│   └── documentation/         # Guides and docs
├── storage-tools/             # Original storage management
│   ├── backup-*.ps1          # Backup scripts
│   ├── monitor-storage.ps1   # Storage monitoring
│   └── master-control.ps1    # Central dashboard
└── config/                   # Configuration files
    ├── .env                  # Environment variables
    ├── .credentials         # Team credentials (SECURE)
    └── .gitignore           # Git ignore rules
```

## 🔧 PyCharm Features for This Project

### Jupyter Notebook Integration
- Open .ipynb files directly in PyCharm
- Run cells interactively
- Debug notebook code
- Variable explorer for data analysis

### PowerShell Script Support  
- Syntax highlighting for .ps1 files
- PowerShell terminal integration
- Script debugging capabilities
- Integrated version control

### Git Integration
- Built-in Git support
- Visual diff tools
- Commit and push from IDE
- Branch management

### Terminal Access
- Multiple terminal tabs
- PowerShell, CMD, and Python terminals
- Direct script execution
- Environment variable access

## 👥 Team Collaboration Features

### Shared Configuration
- Project settings sync across team
- Code style consistency
- Shared run configurations
- Plugin recommendations

### Version Control
- Git blame and history
- Merge conflict resolution
- Branch comparison tools
- Remote repository management

## 🎯 Quick Start Commands

### Start Jupyter from PyCharm Terminal:
```bash
cd "H:\My Drive\storage-management"
jupyter notebook --port=8888
```

### Run Sandbox Demo:
```powershell
.\DC-Sandbox-Launcher.ps1 -Action demo
```

### Open Interactive Notebook:
```
Right-click DC-Sandbox-Testing.ipynb -> Open With -> Jupyter
```

## 🔒 Security Notes

1. **Never commit .credentials file** - Contains sensitive team data
2. **Use .gitignore** - Prevents accidental commits of sensitive files  
3. **Environment variables** - Store API keys and passwords securely
4. **Local development** - Keep production credentials separate

## 📚 Recommended PyCharm Plugins

- **PowerShell** - For .ps1 file support
- **Jupyter** - Enhanced notebook support (usually included)
- **GitToolBox** - Advanced Git features
- **Rainbow Brackets** - Code readability
- **Markdown** - Documentation editing

## 🎮 Getting Started Workflow

1. **Open PyCharm** and load the project
2. **Start Jupyter server** from terminal
3. **Open DC-Sandbox-Testing.ipynb** 
4. **Run sandbox demo** to understand the process
5. **Use production scripts** when ready
6. **Commit changes** to Git regularly

Happy coding with PyCharm! 🎉
# Quick Start Guide

## Immediate Use (No Installation Required)

### Run Log Organizer Now
```powershell
.\organize-logs.ps1
```

This will automatically organize all log files into the proper directories.

## Setting Up Google Jules (Requires Node.js)

### Step 1: Install Node.js
Download and install from: https://nodejs.org/ (LTS version recommended)

### Step 2: Install Jules
```bash
npm install -g @google/jules
```

### Step 3: Authenticate
```bash
jules login
```

### Step 4: Connect GitHub
1. Visit https://jules.google.com
2. Sign in with Google
3. Connect GitHub account
4. Select this repository

### Step 5: Create GitHub Repository
```bash
# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

### Step 6: Delegate Tasks
```bash
jules remote new --repo YOUR_REPO_NAME --session "Set up automated daily log organization and maintenance"
```

## Schedule Automatic Organization (Windows Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task
3. Name: "MT5 Logs Organizer"
4. Trigger: Daily at 2:00 AM
5. Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "D:\Users\USERNAME\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Logs\organize-logs.ps1"`
   - Replace `USERNAME` with your Windows username

## Current Status

✅ Git repository initialized  
✅ Automation script created  
✅ Documentation complete  
⏳ Node.js installation needed for Jules  
⏳ GitHub repository setup needed for Jules  


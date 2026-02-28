# Setting Up Google Jules Agent CLI

This guide will help you install and configure Google Jules Agent CLI tools for
automated log management.

## Prerequisites

### 1. Install Node.js

Jules requires Node.js (v16 or higher). Download and install from:

- **Official Site**: https://nodejs.org/
- **Recommended**: Download the LTS (Long Term Support) version

After installation, verify:

```bash
node --version
npm --version

```bash

### 2. Install Jules CLI

Once Node.js is installed, run:

```bash
npm install -g @google/jules

```bash

Verify installation:

```bash
jules --version

```bash

### 3. Authenticate with Google

```bash
jules login

```bash

This will open a browser window for authentication.

### 4. Connect GitHub Repository

1. Visit [jules.google.com](https://jules.google.com)
2. Sign in with your Google account
3. Click "Connect to GitHub account"
4. Authorize Jules to access your repositories
5. Select the repositories you want Jules to manage

### 5. Initialize This Repository for Git

If you haven't already:

```bash
git init
git add README.md .gitignore organize-logs.ps1 setup-jules.md package.json
git commit -m "Initial setup: MT5 logs organization with Jules automation"

```bash

### 6. Create GitHub Repository

1. Go to GitHub and create a new repository
2. Add the remote:

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main

```bash

### 7. Delegate Tasks to Jules

Once everything is set up, you can delegate tasks:

```bash

# Organize logs automatically

jules remote new --repo YOUR_REPO_NAME --session "Create a scheduled task that runs organize-logs.ps1 daily to keep log files organized"

# Monitor and maintain log structure

jules remote new --repo YOUR_REPO_NAME --session "Set up automated monitoring to ensure log files are properly organized and archived when they get too old"

```bash

## Alternative: Use PowerShell Script (No Node.js Required)

If you prefer not to install Node.js, you can use the included PowerShell
script:

### Run Manually

```powershell
.\organize-logs.ps1

```bash

### Schedule with Task Scheduler

1. Open Task Scheduler (Windows)
2. Create Basic Task
3. Set trigger (e.g., daily at 2 AM)
4. Action: Start a program

   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "D:\Users\USERNAME\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Logs\organize-logs.ps1"`
   - **Note:** Replace `USERNAME` with your Windows username and verify your drive letter (typically C:\ or D:\)

## Troubleshooting

### Node.js not found

- Ensure Node.js is installed and added to PATH
- Restart terminal/command prompt after installation

### Jules authentication fails

- Clear browser cache and try again
- Check internet connection
- Verify Google account access

### Git repository issues

- Ensure Git is installed: `git --version`
- Check if directory is already a Git repo: `git status`

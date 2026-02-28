# Replit Integration Guide

This guide explains how to develop and deploy the NUNA MetaTrader 5 project using Replit.

## Overview

The NUNA project is available on Replit for cloud-based development and testing:

**Replit Project URL**: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS

## Features

- ☁️ Cloud-based development environment
- 🔄 Automatic syncing with GitHub and forge.mql5.io
- 🐍 Python 3.11 runtime with all dependencies
- 🔧 Integrated debugging tools
- 📦 Pre-configured environment variables
- 🚀 One-click deployment

## Getting Started

### 1. Access the Replit Project

Open the project in your browser:

```bash
https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS?v=1

```bash

### 2. Fork the Repl (Optional)

If you want your own copy:

1. Click the "Fork" button in Replit
2. The project will be copied to your Replit account
3. You can make changes without affecting the original

Fork URL parameters:

- `forkRepl=74fbf663-fcf3-40e5-b496-2295edb70b17`
- `forkContext=coverPage`

### 3. Configuration

The Replit environment is configured through:

- **`.replit`**: Main configuration file (run commands, ports, deployment)
- **`replit.nix`**: System dependencies and packages
- **`.env`**: Environment variables (automatically loaded)

## Development Workflow

### Running the Project

Click the "Run" button in Replit, or use the console:

```bash
python main.py

```bash

### Installing Dependencies

Dependencies are automatically installed from `requirements.txt`:

```bash
pip install -r requirements.txt

```bash

### Testing

Run the test suite:

```bash

# Run all tests
python -m unittest discover

# Run specific test
python -m unittest test_trading_data_manager.py

```bash

### Debugging

Replit provides integrated debugging:

1. Click on the Debug icon in the sidebar
2. Set breakpoints in your code
3. Start the debugger
4. Inspect variables and step through code

## Git Integration

### Connecting to GitHub

The Repl is connected to GitHub repository: `https://github.com/A6-9V/NUNA`

```bash

# Pull latest changes from GitHub
git pull origin main

# Commit changes
git add .
git commit -m "Your commit message"

# Push to GitHub
git push origin main

```bash

### Connecting to forge.mql5.io

The forge.mql5.io remote is already configured:

```bash

# Push to forge
git push forge main

# Pull from forge
git pull forge main

```bash

**Authentication Token**: `PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW`

### Syncing All Repositories

Use the sync script to update all remotes:

```bash
./scripts/sync-forge.sh

```bash

## Environment Variables

Configure the following secrets in Replit:

### Required Variables

Add these in the Replit "Secrets" tab (🔒 icon):

```env

# MetaTrader 5 Configuration
EXNESS_LOGIN=your_mt5_account
EXNESS_PASSWORD=your_mt5_password
EXNESS_SERVER=your_mt5_server

# Database Configuration
POSTGRES_PASSWORD=your_postgres_password
REDIS_PASSWORD=your_redis_password

# API Keys (if using external services)
FIREBASE_API_KEY=your_firebase_key
GOOGLE_API_KEY=your_google_key

```bash

### Optional Variables

```env

# Trading Configuration
SYMBOLS=EURUSD,GBPUSD,USDJPY
BRIDGE_PORT=5555
API_PORT=8000

# Logging
LOG_LEVEL=INFO
DEBUG=false

```bash

## Deployment

### Option 1: Replit Deployment

Deploy directly from Replit:

1. Click "Deploy" in the Replit interface
2. Choose deployment target (Replit hosting)
3. Configure custom domain (optional)
4. Deploy

### Option 2: Export to VPS

Export your Repl and deploy to a VPS:

```bash

# Download as ZIP or clone via Git
git clone https://github.com/A6-9V/NUNA
cd NUNA

# Deploy to VPS (see VPS_DEPLOYMENT.md)
./scripts/deploy-vps.sh

```bash

## Ports and Services

The Replit environment exposes the following ports:

| Service | Internal Port | External Port | Description |
|---------|--------------|---------------|-------------|
| API Server | 8000 | 80 | Main API endpoint |
| Bridge Service | 5555 | 5555 | MT5 bridge service |

Access services:

- **API**: `https://your-repl-name.repl.co/`
- **Bridge**: `your-repl-name.repl.co:5555`

## File Structure

The Replit environment includes:

```bash
NUNA/
├── .replit                 # Replit configuration
├── replit.nix             # System packages
├── main.py                # Entry point
├── requirements.txt       # Python dependencies
├── .env                   # Environment variables (Replit Secrets)
├── Experts/               # MQL5 Expert Advisors
├── Include/               # MQL5 include files
├── Scripts/               # Utility scripts
└── MQL5_Deployment_Package/ # MQL5 distribution files

```bash

## IDE Features

### Code Completion

Python language server is enabled for:

- Autocomplete
- Syntax highlighting
- Error detection
- Refactoring tools

### Terminal

Access the integrated terminal:

- Click "Shell" in the sidebar
- Run bash commands
- Execute Python scripts
- Use Git commands

### File Explorer

Navigate your project:

- Browse files in the left sidebar
- Create/delete files and folders
- Upload files
- Download project files

## Collaboration

### Multiplayer Mode

Invite collaborators to edit together:

1. Click "Invite" button
2. Share the invitation link
3. Collaborate in real-time

### GitHub Pull Requests

Create pull requests directly from Replit:

```bash

# Create a feature branch
git checkout -b feature/new-strategy

# Make changes and commit
git add .
git commit -m "Add new trading strategy"

# Push to GitHub
git push origin feature/new-strategy

```bash

Then create a PR on GitHub.

## Troubleshooting

### Repl Won't Start

1. Check the Console for errors
2. Verify all dependencies are installed:
   ```bash
   pip install -r requirements.txt
   ```
3. Check environment variables in Secrets

### Git Push Fails

1. Verify authentication:
   ```bash
   git remote -v
   ```
2. Update credentials if needed
3. Try force push (if safe):
   ```bash
   git push --force origin main
   ```

### Missing Dependencies

If packages are missing:

```bash

# Update replit.nix with required packages

# Then refresh the environment

```bash

### Port Already in Use

If port conflicts occur:

1. Stop the running process
2. Change port in `.replit` configuration
3. Update firewall rules if needed

## Performance Optimization

### Speed Up Repl Loading

1. Minimize unnecessary dependencies
2. Use `.gitignore` to exclude large files
3. Clear unused packages:
   ```bash
   pip uninstall unused-package
   ```

### Reduce Resource Usage

1. Stop unused services
2. Limit background processes
3. Use caching where possible

## Backup and Export

### Download Project

Download your entire Repl:

1. Click the menu (⋮) in Files
2. Select "Download as zip"
3. Extract and use locally

### Clone via Git

```bash
git clone https://github.com/A6-9V/NUNA
cd NUNA

```bash

## Best Practices

### 1. Use Secrets for Sensitive Data

Never hardcode credentials:

- Use Replit Secrets for API keys
- Use environment variables
- Keep `.env.example` updated

### 2. Regular Git Commits

Commit frequently:

```bash
git add .
git commit -m "Descriptive message"
git push

```bash

### 3. Test Before Deploying

Always test in Replit before pushing to production:

- Run unit tests
- Test API endpoints
- Verify MT5 connection

### 4. Keep Dependencies Updated

Regularly update packages:

```bash
pip list --outdated
pip install --upgrade package-name

```bash

## Resources

- **Replit Documentation**: https://docs.replit.com/
- **Replit Community**: https://replit.com/community
- **GitHub Repository**: https://github.com/A6-9V/NUNA
- **forge.mql5.io**: https://forge.mql5.io/LengKundee/NUNA

## Support

For help with:

- **Replit Issues**: Contact Replit support or visit their community
- **NUNA Project**: Open an issue on GitHub
- **MQL5 Integration**: See FORGE_MQL5_SETUP.md

---

**Last Updated**: 2026-02-05
**Replit Project**: @mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS
**GitHub**: A6-9V/NUNA

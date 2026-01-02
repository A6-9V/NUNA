# OS Application Support System

Complete infrastructure for remote device management, trading system support, and 24/7 automation.

## Target Device
- **Device**: Samsung A6 9V
- **Purpose**: Trading system support with real-time updates
- **Repository**: https://github.com/A6-9V/OS-application-support-.git

## Features

### 1. Remote Device Management
- Device connection management (ADB, SSH, VNC)
- Remote deployment of jobs and applications
- Device monitoring and health checks
- Automatic reconnection on failure

### 2. Trading System Support
- Real-time update service with WebSocket and REST API support
- Trading system manager (start/stop/restart/status)
- Job scheduler for automated trading operations
- Continuous monitoring and health checks

### 3. Security Features
- VPS security management and monitoring
- WiFi security scanning and protection
- App protection and integrity checking
- Continuous security monitoring

### 4. 24/7 Automation
- Master monitoring service
- Auto-restart on failure
- System health checks
- Automatic startup on boot (administrator level)

## Quick Start

### Initial Setup

1. **Run the master setup** (as administrator):
   ```powershell
   .\master-orchestrator.ps1 -Action setup -RunAsAdmin
   ```

   This will:
   - Create the project structure
   - Set up Git repository
   - Create all configuration files
   - Set up auto-startup

2. **Deploy to GitHub**:
   ```powershell
   .\deploy-os-application-support.ps1 -FullDeploy -RunAsAdmin
   ```

### Daily Operations

**Start the system:**
```powershell
.\master-orchestrator.ps1 -Action start
```

**Check status:**
```powershell
.\master-orchestrator.ps1 -Action status
```

**Deploy updates:**
```powershell
.\deploy-os-application-support.ps1 -FullDeploy -RunAsAdmin
```

**Update and restart:**
```powershell
.\master-orchestrator.ps1 -Action update
```

## Directory Structure

```
OS-application-support/
├── remote-device/          # Remote device management
│   ├── device-connect.ps1
│   ├── device-deploy.ps1
│   └── device-monitor.ps1
├── trading-system/          # Trading system support
│   ├── realtime-update-service.ps1
│   ├── trading-manager.ps1
│   ├── job-scheduler.ps1
│   └── jobs/               # Trading jobs
├── security/               # Security features
│   ├── vps-security.ps1
│   ├── wifi-security.ps1
│   ├── app-protection.ps1
│   └── security-monitor.ps1
├── monitoring/             # 24/7 monitoring
│   ├── master-monitor.ps1
│   ├── auto-restart.ps1
│   └── health-check.ps1
├── deployment/             # Deployment scripts
├── scripts/                # Utility scripts
├── config/                 # Configuration files
└── logs/                   # Log files
```

## Scripts

### Setup Scripts
- `setup-os-application-support.ps1` - Main setup script
- `setup-remote-device.ps1` - Remote device setup
- `setup-trading-system.ps1` - Trading system setup
- `setup-security.ps1` - Security setup
- `setup-monitoring.ps1` - Monitoring setup
- `setup-auto-startup-admin.ps1` - Auto-startup configuration

### Management Scripts
- `master-orchestrator.ps1` - Master control script
- `deploy-os-application-support.ps1` - Deployment script
- `startup-all.ps1` - Startup script (auto-generated)

## Auto-Startup

The system is configured to start automatically on boot with administrator privileges:

- **Task Name**: `OS-Application-Support-Startup`
- **Trigger**: At system startup
- **Run Level**: Highest (Administrator)
- **Status**: Check with `setup-auto-startup-admin.ps1 -Check`

To remove auto-startup:
```powershell
.\setup-auto-startup-admin.ps1 -Remove
```

## GitHub Integration

### Repository URLs
- **HTTPS**: https://github.com/A6-9V/OS-application-support-.git
- **SSH**: git@github.com:A6-9V/OS-application-support-.git

### Remotes
- `origin` - HTTPS remote (for pushing)
- `upstream` - SSH remote (for pulling)

### Deployment Workflow

1. **Pull latest changes**:
   ```powershell
   .\deploy-os-application-support.ps1 -PullFromGitHub -RunAsAdmin
   ```

2. **Make changes** (edit scripts, add features)

3. **Deploy changes**:
   ```powershell
   .\deploy-os-application-support.ps1 -FullDeploy -RunAsAdmin
   ```

## Security

- All credentials and tokens are stored securely
- Never commit sensitive information to git
- Security monitoring runs 24/7
- VPS and WiFi security checks are automated

## Monitoring

The system includes comprehensive monitoring:

- **Device Monitoring**: Checks device connectivity and health
- **Trading System Monitoring**: Monitors trading system status
- **Security Monitoring**: Continuous security checks
- **Health Checks**: System resource monitoring (CPU, memory, disk)

## Troubleshooting

### System won't start
1. Check administrator privileges
2. Run: `.\master-orchestrator.ps1 -Action status`
3. Check logs in `OS-application-support/logs/`

### Auto-startup not working
1. Check scheduled task: `.\setup-auto-startup-admin.ps1 -Check`
2. Re-run setup: `.\setup-auto-startup-admin.ps1`

### Git deployment fails
1. Check repository path exists
2. Verify Git credentials
3. Check network connectivity

## Support

For issues or questions:
- Check logs in `OS-application-support/logs/`
- Review system status: `.\master-orchestrator.ps1 -Action status`
- Run health check: `.\monitoring\health-check.ps1 -FullCheck`

## License

This system is designed for the Samsung A6 9V device and trading system support.

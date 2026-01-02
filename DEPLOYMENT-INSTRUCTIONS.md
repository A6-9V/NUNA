# Deployment Instructions for OS Application Support

## Quick Start

### 1. Initial Setup (Run Once)

Open PowerShell as Administrator and run:

```powershell
cd "C:\Users\USER\OneDrive"
.\quick-start-os-application-support.ps1
```

This will:
- Create the complete directory structure
- Set up all scripts and configurations
- Configure Git repository
- Set up auto-startup
- Deploy to GitHub

### 2. Manual Setup (If Quick Start Fails)

Run these scripts in order:

```powershell
# 1. Main setup
.\setup-os-application-support.ps1

# 2. Remote device setup
.\setup-remote-device.ps1

# 3. Trading system setup
.\setup-trading-system.ps1

# 4. Security setup
.\setup-security.ps1

# 5. Monitoring setup
.\setup-monitoring.ps1

# 6. Auto-startup setup (as admin)
.\setup-auto-startup-admin.ps1

# 7. Deploy to GitHub
.\deploy-os-application-support.ps1 -FullDeploy -RunAsAdmin
```

## Git Repository Setup

The repository is configured with:
- **HTTPS Remote (origin)**: https://github.com/A6-9V/OS-application-support-.git
- **SSH Remote (upstream)**: git@github.com:A6-9V/OS-application-support-.git

### First Time Push

If the repository doesn't exist on GitHub yet:

1. Create the repository on GitHub: https://github.com/A6-9V/OS-application-support-
2. Then run:
   ```powershell
   cd "C:\Users\USER\OneDrive\OS-application-support"
   git push -u origin main
   ```

### Regular Deployment

```powershell
.\deploy-os-application-support.ps1 -FullDeploy -RunAsAdmin
```

This will:
- Pull latest changes from GitHub
- Stage all changes
- Commit with timestamp
- Push to both HTTPS and SSH remotes

## Daily Operations

### Start System
```powershell
.\master-orchestrator.ps1 -Action start
```

### Check Status
```powershell
.\master-orchestrator.ps1 -Action status
```

### Stop System
```powershell
.\master-orchestrator.ps1 -Action stop
```

### Restart System
```powershell
.\master-orchestrator.ps1 -Action restart
```

### Update and Restart
```powershell
.\master-orchestrator.ps1 -Action update
```

## Auto-Startup Configuration

The system is configured to start automatically on boot with administrator privileges.

### Check Auto-Startup Status
```powershell
.\setup-auto-startup-admin.ps1 -Check
```

### Remove Auto-Startup
```powershell
.\setup-auto-startup-admin.ps1 -Remove
```

### Re-enable Auto-Startup
```powershell
.\setup-auto-startup-admin.ps1
```

## Remote Device Connection (Samsung A6-9V)

### Connect via ADB
```powershell
cd "C:\Users\USER\OneDrive\OS-application-support\remote-device"
.\device-connect.ps1 -UseADB -DeviceIP "192.168.x.x" -DevicePort "5555"
```

### Deploy to Device
```powershell
.\device-deploy.ps1 -DeployApp -JobPath "path\to\app" -DeviceIP "192.168.x.x"
```

### Monitor Device
```powershell
.\device-monitor.ps1 -DeviceIP "192.168.x.x" -Continuous
```

## Trading System

### Start Trading System
```powershell
cd "C:\Users\USER\OneDrive\OS-application-support\trading-system"
.\trading-manager.ps1 start
```

### Check Status
```powershell
.\trading-manager.ps1 status
```

### Deploy Job
```powershell
.\trading-manager.ps1 deploy -JobName "job-name"
```

### Start Real-Time Updates
```powershell
.\realtime-update-service.ps1 -UpdateInterval 1 -EnableWebSocket -EnableREST
```

## Security

### VPS Security Check
```powershell
cd "C:\Users\USER\OneDrive\OS-application-support\security"
.\vps-security.ps1 -CheckConnection -VPSHost "your-vps-host"
```

### WiFi Security Scan
```powershell
.\wifi-security.ps1 -ScanNetworks -CheckSecurity
```

### Security Monitoring
```powershell
.\security-monitor.ps1 -Continuous
```

## Monitoring

### Master Monitor
```powershell
cd "C:\Users\USER\OneDrive\OS-application-support\monitoring"
.\master-monitor.ps1 -StartAll
```

### Health Check
```powershell
.\health-check.ps1 -FullCheck -ExportReport
```

### Auto-Restart Service
```powershell
.\auto-restart.ps1 -ServiceName "service-name" -Continuous
```

## Troubleshooting

### System Won't Start
1. Check administrator privileges
2. Run: `.\master-orchestrator.ps1 -Action status`
3. Check logs in `OS-application-support\logs\`

### Git Push Fails
1. Verify repository exists on GitHub
2. Check network connectivity
3. Verify Git credentials
4. Try: `git push origin main --force` (if safe to do so)

### Auto-Startup Not Working
1. Check task: `.\setup-auto-startup-admin.ps1 -Check`
2. Re-run setup: `.\setup-auto-startup-admin.ps1`
3. Check Windows Event Viewer for errors

### Device Connection Fails
1. Ensure device is on same network
2. Enable USB debugging on device
3. Check firewall settings
4. Verify ADB is installed

## File Structure

```
OS-application-support/
├── remote-device/          # Remote device management
├── trading-system/          # Trading system support
│   └── jobs/               # Trading jobs
├── security/               # Security features
├── monitoring/             # 24/7 monitoring
├── deployment/             # Deployment scripts
├── scripts/                # Utility scripts
├── config/                 # Configuration files
├── logs/                   # Log files
├── startup-all.ps1         # Auto-startup script
├── README.md               # Main documentation
└── .gitignore             # Git ignore rules
```

## Next Steps

1. **Configure Device IP**: Update device connection scripts with your Samsung A6-9V IP address
2. **Set Up Trading Jobs**: Add trading jobs to `trading-system\jobs\`
3. **Configure VPS**: Set up VPS connection details in security scripts
4. **Test Auto-Startup**: Restart computer and verify system starts automatically
5. **Monitor Logs**: Check `logs\` directory for system activity

## Support

For issues:
- Check logs: `OS-application-support\logs\`
- Run health check: `.\monitoring\health-check.ps1 -FullCheck`
- Check system status: `.\master-orchestrator.ps1 -Action status`

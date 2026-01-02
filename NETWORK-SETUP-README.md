# Network Mapping Setup Guide

Complete guide for setting up network drive mappings and UNC paths.

## Quick Start

### 1. Configure Network Locations

Edit `network-config.json` and add your network resources:

```json
{
  "mappings": [
    {
      "drive_letter": "Z:",
      "unc_path": "\\\\SERVER-NAME\\SharedFolder",
      "description": "Main Network Share",
      "persistent": true
    }
  ],
  "unc_paths": [
    {
      "name": "VPS-Share",
      "path": "\\\\VPS-IP\\Share",
      "description": "VPS Network Share"
    }
  ],
  "network_resources": [
    {
      "name": "Network-PC",
      "ip_address": "192.168.1.100",
      "description": "Local Network PC",
      "ports": [445, 3389]
    }
  ]
}
```

### 2. Run Setup

```powershell
.\setup-network-mapping.ps1
```

### 3. Quick Map (if config exists)

```powershell
.\map-network-drives.ps1
```

## Configuration Options

### Drive Mappings

- **drive_letter**: Drive letter to assign (e.g., "Z:")
- **unc_path**: UNC path to network share (e.g., "\\SERVER\Share")
- **persistent**: Keep mapping after reboot (true/false)
- **credentials**: Store in Windows Credential Manager

### UNC Paths

- **name**: Friendly name for shortcut
- **path**: UNC path to network location
- **description**: Description of the share

### Network Resources

- **name**: Friendly name
- **ip_address**: IP address or hostname
- **ports**: Ports to test (445=SMB, 3389=RDP, etc.)

## Usage Examples

### Map a Network Drive

```powershell
# Add to network-config.json, then:
.\setup-network-mapping.ps1
```

### Test Network Connection

The setup script automatically tests network resources and reports port status.

### Access Network Share

After mapping, access via:
- Drive letter: `Z:\`
- UNC path: `\\SERVER\Share`
- Shortcut: `Network-Shortcuts\VPS-Share.lnk`

## Troubleshooting

### Cannot Access Network Share

1. Check network connectivity: `Test-NetConnection -ComputerName SERVER-NAME -Port 445`
2. Verify credentials in Windows Credential Manager
3. Check firewall settings
4. Ensure SMB is enabled on target server

### Drive Already Mapped

The script will skip drives that are already mapped. To remap:
```powershell
Remove-PSDrive -Name Z
.\map-network-drives.ps1
```

### Credentials Required

Store credentials in Windows Credential Manager:
```powershell
cmdkey /add:SERVER-NAME /user:USERNAME /pass:PASSWORD
```

## Integration

### Auto-Start on Boot

Add to startup script:
```powershell
.\map-network-drives.ps1
```

### With Code Cleanup

Run both together:
```powershell
.\setup-network-and-cleanup.ps1
```

## Security Notes

- Credentials stored in Windows Credential Manager (secure)
- Network paths tested before mapping
- Firewall rules may need adjustment
- Use VPN for remote network access


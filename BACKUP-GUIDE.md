# USB Backup Guide - U&I/yy/mm/dd Structure

## Quick Start

Run the backup script to create a backup with the structure: `U&I/yy/mm/dd/`

```powershell
cd C:\Users\USER\my-drive-projects
.\backup-to-usb.ps1
```

## Auto-Detect USB Drive

The script will automatically detect USB drives:

```powershell
.\backup-to-usb.ps1 -AutoDetect
```

## Specify USB Drive

If you have multiple USB drives, specify the drive letter:

```powershell
.\backup-to-usb.ps1 -UsbDrive "E:"
```

## Backup Structure

The backup creates the following structure on your USB drive:

```
USB Drive (E:)
└── U&I/
    └── 25/          # Year (yy)
        └── 12/      # Month (MM)
            └── 20/  # Day (dd)
                └── my-drive-projects/
                    ├── [all project files]
                    ├── backup-log_2025-12-20_HH-mm-ss.txt
                    └── backup-info.txt
```

## What Gets Backed Up

- ✅ All project files
- ✅ Documentation
- ✅ Scripts
- ✅ Configuration files

## What Gets Excluded

- ❌ `.git` directory (version control)
- ❌ `node_modules` (dependencies)
- ❌ `__pycache__` (Python cache)
- ❌ `*.log` files
- ❌ `*.tmp` files
- ❌ `.DS_Store`, `Thumbs.db` (system files)

## Backup Logs

Each backup creates:
- **backup-log_TIMESTAMP.txt** - Detailed log of the backup process
- **backup-info.txt** - Summary information about the backup

## Example Output

```
========================================
  USB Backup Script - U&I/yy/mm/dd
========================================

[INFO] Date format: 25/12/20
[OK] Found USB drive: E:
[INFO] Creating backup directory structure...
  Base: E:\U&I
  Path: E:\U&I\25\12\20

[INFO] Starting backup...
  Source: C:\Users\USER\my-drive-projects
  Destination: E:\U&I\25\12\20\my-drive-projects

[OK] Backup completed!
  Files copied: 1234
```

## Notes

- The script preserves the directory structure
- Multiple backups on the same day will be in the same folder
- Each backup includes a timestamped log file
- USB drive must have sufficient free space


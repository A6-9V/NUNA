---
description: "System-specific configuration for NuNa device running Windows 11 Home Single Language 25H2"
alwaysApply: true
---

# System Configuration

This project is configured for the following system:

## Device Information

- **Device Name**: NuNa
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Architecture**: 64-bit x64-based processor
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)
- **Installation Date**: 12/9/2025

## System Paths

When writing scripts, use these standard paths:

- **Program Files**: `$env:PROGRAMFILES` → `C:\Program Files`
- **Program Files (x86)**: Use `(Get-Item "Env:ProgramFiles(x86)").Value` with try-catch (may not exist on 64-bit systems)
- **Local AppData**: `$env:LOCALAPPDATA` → `C:\Users\USER\AppData\Local`
- **AppData**: `$env:APPDATA` → `C:\Users\USER\AppData\Roaming`
- **OneDrive**: `C:\Users\USER\OneDrive`
- **Script Location**: `C:\Users\USER\OneDrive\`

## GitHub Desktop Paths

GitHub Desktop is checked in these locations (in order):
1. `$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe` (Primary on Windows 11)
2. `$env:PROGRAMFILES\GitHub Desktop\GitHubDesktop.exe`
3. `%PROGRAMFILES(X86)%\GitHub Desktop\GitHubDesktop.exe` (with error handling)

## PowerShell Configuration

- **Version**: PowerShell 5.1 or later (Windows 11 default)
- **Execution Policy**: `RemoteSigned` (required for script execution)
- **Script Compatibility**: All scripts tested on this system configuration

## Important Notes

- This is a 64-bit system - ProgramFiles(x86) may not always be applicable
- GitHub Desktop typically installs to `%LOCALAPPDATA%\GitHubDesktop\` on Windows 11
- Always use proper environment variable access for cross-compatibility
- Handle missing environment variables gracefully with try-catch blocks

## References

- See `SYSTEM-INFO.md` for complete system details
- See `AUTOMATION-RULES.md` for automation patterns

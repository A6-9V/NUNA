# System Information

This document contains the system specifications and configuration for the NuNa device.

## Device Information

- **Device Name**: NuNa
- **Device ID**: 32680105-F98A-49B6-803C-8A525771ABA3
- **Product ID**: 00356-24782-61221-AAOEM

## Hardware Specifications

- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **Installed RAM**: 8.00 GB (7.63 GB usable)
- **System Type**: 64-bit operating system, x64-based processor
- **Pen and Touch**: No pen or touch input is available for this display

## Operating System

- **Edition**: Windows 11 Home Single Language
- **Version**: 25H2
- **OS Build**: 26220.7344
- **Experience**: Windows Feature Experience Pack 1000.26100.306.0
- **Installed On**: 12/9/2025

## System Paths

### Standard Installation Paths
- **Program Files**: `C:\Program Files`
- **Program Files (x86)**: `C:\Program Files (x86)` (if applicable)
- **Local AppData**: `C:\Users\USER\AppData\Local`
- **AppData**: `C:\Users\USER\AppData\Roaming`
- **OneDrive**: `C:\Users\USER\OneDrive`

### GitHub Desktop Paths
The system checks for GitHub Desktop in the following locations:
- `%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe`
- `%PROGRAMFILES%\GitHub Desktop\GitHubDesktop.exe`
- `%PROGRAMFILES(X86)%\GitHub Desktop\GitHubDesktop.exe` (64-bit systems may not have this)

## PowerShell Configuration

- **PowerShell Version**: PowerShell 5.1 or later (Windows 11 default)
- **Execution Policy**: Should be set to `RemoteSigned` for script execution
- **Script Location**: `C:\Users\USER\OneDrive\`

## Script Compatibility

All automation scripts are tested and configured for:
- ✅ Windows 11 Home Single Language
- ✅ 64-bit x64 architecture
- ✅ PowerShell 5.1+
- ✅ 8GB RAM system

## Notes

- This is a 64-bit system, so ProgramFiles(x86) may not be applicable for all applications
- GitHub Desktop typically installs to `%LOCALAPPDATA%\GitHubDesktop\` on Windows 11
- All scripts use proper environment variable access for cross-compatibility

---

**Last Updated**: 2025-12-09
**System**: NuNa (Windows 11 Home Single Language 25H2)

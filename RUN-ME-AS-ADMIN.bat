@echo off
title Cloud Sync Setup - Run as Administrator
color 0A
echo.
echo ========================================
echo   Cloud Sync Security Configuration
echo ========================================
echo.
echo This script will:
echo   1. Close all File Explorer windows
echo   2. Configure Windows Defender exclusions
echo   3. Set up Windows Firewall rules
echo   4. Configure Windows Security settings
echo   5. Verify cloud sync services
echo.
echo Press Ctrl+C to cancel, or
pause
echo.
echo Requesting administrator privileges...
echo.
powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0setup-cloud-sync.ps1"



@echo off
title Complete Windows Setup - Lengkundee01
color 0B
echo.
echo ========================================
echo   Complete Windows Setup & Configuration
echo   For: Lengkundee01@gmail.com
echo        Lengkundee01@outlook.com
echo ========================================
echo.
echo This will configure:
echo   - Windows Settings and Profile
echo   - Account Sync
echo   - Browser Defaults
echo   - Default Apps
echo   - Security Settings
echo   - Cloud Sync (OneDrive, Dropbox, Google Drive)
echo.
echo Press Ctrl+C to cancel, or
pause
echo.
echo Requesting administrator privileges...
echo.
powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0complete-windows-setup.ps1"


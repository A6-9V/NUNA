@echo off
REM Quick launcher for Remote Desktop setup
REM Auto-elevates to Administrator

echo ========================================
echo   Remote Desktop Setup Launcher
echo ========================================
echo.
echo This will enable Remote Desktop on your computer.
echo.
pause

powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList @('-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', '%~dp0setup-remote-desktop.ps1')"

timeout /t 3 /nobreak >nul





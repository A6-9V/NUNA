@echo off
echo ========================================
echo   Firewall Configuration for Port 5500
echo   MetaTrader Exness Trading Bridge
echo ========================================
echo.
echo This will request administrator privileges...
echo.

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0setup-firewall-port-5500.ps1\"' -Verb RunAs"

pause


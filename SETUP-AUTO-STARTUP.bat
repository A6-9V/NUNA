@echo off
REM Auto-Setup Startup Configuration (Restart Only)
REM Automatically elevates to admin and runs setup

cd /d "C:\Users\USER\OneDrive"
powershell.exe -ExecutionPolicy Bypass -File "setup-auto-startup-restart-only.ps1"

pause

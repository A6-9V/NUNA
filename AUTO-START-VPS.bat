@echo off
REM Auto-Start VPS System - Fully Automated (No User Interaction)
REM This script automatically elevates to admin and starts everything

cd /d "C:\Users\USER\OneDrive"
powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "auto-start-vps-admin.ps1"

REM Script runs in background - no pause needed
exit

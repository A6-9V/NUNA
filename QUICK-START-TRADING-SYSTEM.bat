@echo off
REM Quick Start Trading System - Double-click to run
REM Automatically elevates to admin and starts everything

cd /d "C:\Users\USER\OneDrive"
powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "QUICK-START-TRADING-SYSTEM.ps1"

REM Script runs in background - no pause needed
exit


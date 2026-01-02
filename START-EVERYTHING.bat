@echo off
REM Start Everything - Trading System
REM Double-click to start all trading system components

cd /d "C:\Users\USER\OneDrive"

echo Starting Trading System...
echo.

REM Start simple version (no admin required)
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "QUICK-START-SIMPLE.ps1"

REM Wait a moment
timeout /t 3 /nobreak >nul

REM Check status
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "check-trading-status.ps1"

echo.
echo Trading system is starting...
echo Check status anytime with: check-trading-status.ps1
echo.
pause


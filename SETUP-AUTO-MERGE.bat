@echo off
REM Setup Auto-Merge for Repository
REM Run as Administrator for best results

echo.
echo ========================================
echo   Auto-Merge Setup
echo ========================================
echo.
echo Starting auto-merge configuration...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup-auto-merge.ps1"

echo.
echo Press any key to exit...
pause > nul

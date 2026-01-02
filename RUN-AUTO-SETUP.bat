@echo off
title Automated Windows Setup
color 0A
echo.
echo ========================================
echo   Automated Windows Setup
echo   Running with intelligent defaults...
echo ========================================
echo.
echo This will run automatically without prompts.
echo Making intelligent decisions based on your system.
echo.
pause
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0run-all-auto.ps1"
pause



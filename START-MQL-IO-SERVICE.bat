@echo off
REM Start MQL.io Service
REM Quick launcher for MQL.io service

echo [INFO] Starting MQL.io Service...
powershell -ExecutionPolicy Bypass -File "%~dp0start-mql-io-service.ps1"
pause

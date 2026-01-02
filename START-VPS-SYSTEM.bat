@echo off
REM ========================================
REM   Starting VPS Trading System
REM   24/7 Automated Trading Setup
REM   All output will be saved to log file
REM ========================================

cd /d "C:\Users\USER\OneDrive"

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Generate timestamp for log filename
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set logfile=logs\vps-system-startup-%datetime:~0,8%-%datetime:~8,6%.log

REM Redirect all output to log file (both stdout and stderr)
echo ======================================== >> "%logfile%"
echo   Starting VPS Trading System >> "%logfile%"
echo   24/7 Automated Trading Setup >> "%logfile%"
echo ======================================== >> "%logfile%"
echo. >> "%logfile%"
echo Log started: %date% %time% >> "%logfile%"
echo. >> "%logfile%"
echo Requesting administrator privileges... >> "%logfile%"
echo. >> "%logfile%"

REM Run PowerShell script and capture all output
powershell.exe -ExecutionPolicy Bypass -File "start-vps-system.ps1" >> "%logfile%" 2>&1

REM Add completion timestamp
echo. >> "%logfile%"
echo ======================================== >> "%logfile%"
echo Log completed: %date% %time% >> "%logfile%"
echo ======================================== >> "%logfile%"

REM Save agent output summary
powershell.exe -ExecutionPolicy Bypass -File "save-agent-output.ps1" >> "%logfile%" 2>&1

echo.
echo ========================================
echo   All output saved to:
echo   %logfile%
echo ========================================
echo.
echo   Agent activity log: logs\ai-agent-activity.log
echo   Session summary: logs\agent-session-summary.log
echo.

pause

@echo off
:: Batch file to run the PowerShell script as Administrator
:: This will prompt for administrator privileges

echo Requesting administrator privileges...
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0setup-cloud-sync.ps1\"' -Verb RunAs"
pause


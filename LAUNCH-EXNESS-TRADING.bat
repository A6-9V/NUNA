@echo off
echo ========================================
echo   Exness Trading Launcher
echo   GitHub Repository + MT5 Terminal
echo ========================================
echo.

cd /d "C:\Users\USER\OneDrive"
powershell.exe -ExecutionPolicy Bypass -File "launch-exness-trading.ps1" -Account 405347405 -Server "Exness-MT5Real8" -Profile "405347405" -PromptForPassword -SkipRepoSetup -SkipFolderOpen

pause

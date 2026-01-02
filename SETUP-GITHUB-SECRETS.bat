@echo off
REM Setup GitHub Secrets - Windows Batch Wrapper
REM This script runs the PowerShell setup script with administrator privileges

echo ========================================
echo GitHub Secrets Setup
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with administrator privileges
    echo.
) else (
    echo [INFO] This script requires administrator privileges for GitHub CLI
    echo [INFO] Please run it directly from PowerShell with the required parameters
    echo.
    echo Usage:
    echo   .\setup-github-secrets.ps1 -ClientId "YOUR_CLIENT_ID" -ClientSecret "YOUR_CLIENT_SECRET"
    echo.
    echo Or set the credentials in a secure way and then run this script.
    echo.
    pause
    exit /b 1
)

REM Check if credentials are provided as environment variables
if not defined OAUTH_CLIENT_ID (
    echo [ERROR] OAUTH_CLIENT_ID environment variable is not set
    echo.
    echo Please set the credentials before running this script:
    echo   $env:OAUTH_CLIENT_ID = "your-client-id"
    echo   $env:OAUTH_CLIENT_SECRET = "your-client-secret"
    echo   .\SETUP-GITHUB-SECRETS.bat
    echo.
    echo Or run the PowerShell script directly:
    echo   .\setup-github-secrets.ps1 -ClientId "your-id" -ClientSecret "your-secret"
    echo.
    pause
    exit /b 1
)

if not defined OAUTH_CLIENT_SECRET (
    echo [ERROR] OAUTH_CLIENT_SECRET environment variable is not set
    echo.
    echo Please set the credentials before running this script:
    echo   $env:OAUTH_CLIENT_ID = "your-client-id"
    echo   $env:OAUTH_CLIENT_SECRET = "your-client-secret"
    echo   .\SETUP-GITHUB-SECRETS.bat
    echo.
    echo Or run the PowerShell script directly:
    echo   .\setup-github-secrets.ps1 -ClientId "your-id" -ClientSecret "your-secret"
    echo.
    pause
    exit /b 1
)

REM Run the PowerShell script with environment variables
echo [INFO] Starting GitHub Secrets setup...
echo [INFO] Note: Using -ExecutionPolicy Bypass for script execution
echo.

powershell -ExecutionPolicy Bypass -Command "& '%~dp0setup-github-secrets.ps1' -ClientId $env:OAUTH_CLIENT_ID -ClientSecret $env:OAUTH_CLIENT_SECRET"

REM Check result
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Setup completed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [ERROR] Setup encountered errors
    echo ========================================
)

echo.
echo Press any key to exit...
pause >nul

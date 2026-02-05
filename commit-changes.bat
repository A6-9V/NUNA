@echo off
echo ========================================
echo EXNESS Docker - Commit Changes
echo ========================================
echo.

REM Navigate to script directory
cd /d "%~dp0"

REM Initialize git if needed
if not exist ".git" (
    echo Initializing git repository...
    git init
)

REM Add all files
echo Adding files to staging...
git add -A

REM Show status
echo.
echo Files to be committed:
git status --short

REM Commit
echo.
echo Committing changes...
git commit -m "Complete EXNESS Docker Project Restructure

Security ^& Environment:
- Enhanced env.template with all configuration variables and 23+ symbols
- Removed hardcoded credentials from scripts and documentation
- Updated docker-compose.yml to use environment variables only
- Fixed duplicate entries and missing postgres image

Documentation:
- Created comprehensive MIGRATION-GUIDE.md
- Removed hardcoded credentials from all docs
- Updated README.md with new structure

Scripts:
- Updated setup-env.ps1 to handle env.template
- Removed credentials from START-NOW.bat
- All scripts reference correct paths

Configuration:
- Support for 30+ trading symbols
- Hybrid symbols loading (env var + JSON)
- Environment-based configuration throughout"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Commit successful!
    echo.
    echo To push to remote:
    echo   git remote add origin ^<your-repo-url^>
    echo   git push -u origin main
    echo.
) else (
    echo.
    echo [WARNING] Commit failed or no changes to commit
    echo   Check git status for details
    echo.
)

echo ========================================
pause


@echo off
echo ========================================
echo NUNA Repository Setup
echo ========================================
echo.

echo Checking Python installation...
python --version
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    pause
    exit /b 1
)

echo.
echo Creating virtual environment...
if exist .venv (
    echo Virtual environment already exists, skipping...
) else (
    python -m venv .venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo Virtual environment created successfully!
)

echo.
echo Activating virtual environment...
call .venv\Scripts\activate.bat

echo.
echo Upgrading pip...
python -m pip install --upgrade pip

echo.
echo Installing requirements...
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install requirements
    pause
    exit /b 1
)

echo.
echo Verifying installation...
python -c "import google.auth; import msal; import requests; print('All packages imported successfully!')"
if errorlevel 1 (
    echo WARNING: Some packages may not be installed correctly
) else (
    echo.
    echo ========================================
    echo Setup completed successfully!
    echo ========================================
    echo.
    echo To activate the virtual environment in the future, run:
    echo   .venv\Scripts\activate.bat
    echo.
)

pause

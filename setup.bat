@echo off
rem This script automates the setup of the Python environment for this project.

echo "--- Setting up Python virtual environment ---"

rem Check if python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo "Error: python is not installed. Please install Python 3 to continue."
    exit /b 1
)

rem Create a virtual environment if it doesn't already exist
if exist ".venv" (
    echo "Virtual environment '.venv' already exists. Skipping creation."
) else (
    echo "Creating virtual environment '.venv'..."
    python -m venv .venv
)

rem Activate the virtual environment and install dependencies
echo "--- Activating virtual environment and installing dependencies ---"
call .venv\Scripts\activate.bat
pip install -r requirements.txt

echo ""
echo "--- Setup complete! ---"
echo "To activate the virtual environment in your current shell, run:"
echo ".venv\Scripts\activate.bat"

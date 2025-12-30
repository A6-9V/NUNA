#!/bin/bash
# This script automates the setup of the Python environment for this project.

set -e

echo "--- Setting up Python virtual environment ---"

# Check if python3 is installed
if ! command -v python3 &> /dev/null
then
    echo "Error: python3 is not installed. Please install Python 3 to continue."
    exit 1
fi

# Create a virtual environment if it doesn't already exist
if [ -d ".venv" ]; then
    echo "Virtual environment '.venv' already exists. Skipping creation."
else
    echo "Creating virtual environment '.venv'..."
    python3 -m venv .venv
fi

# Activate the virtual environment and install dependencies
echo "--- Activating virtual environment and installing dependencies ---"
source .venv/bin/activate
pip install -r requirements.txt

echo ""
echo "--- Setup complete! ---"
echo "To activate the virtual environment in your current shell, run:"
echo "source .venv/bin/activate"

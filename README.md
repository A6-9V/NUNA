# NUNA - MQL5 Trading Robots

[![CI](https://github.com/A6-9V/NUNA/actions/workflows/ci.yml/badge.svg)](https://github.com/A6-9V/NUNA/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

```bash
git clone https://github.com/A6-9V/NUNA.git
```

This repository contains a collection of MQL5 trading robots (Expert Advisors) and Python utilities for managing trading data and Google Drive files.

## Robots

*   **DarkCloud PiercingLine CCI**: This robot uses the Dark Cloud Cover and Piercing Line candlestick patterns in conjunction with the Commodity Channel Index (CCI) to identify trading opportunities.
*   **HangingMan Hammer CCI**: This robot uses the Hanging Man and Hammer candlestick patterns in conjunction with the Commodity Channel Index (CCI) to identify trading opportunities.
*   **DarkCloud PiercingLine RSI**: This robot uses the Dark Cloud Cover and Piercing Line candlestick patterns in conjunction with the Relative Strength Index (RSI) to identify trading opportunities.

## Common Parameters

All robots share a common set of input parameters for configuration.

### Indicator Parameters
*   `InpAverBodyPeriod`: Period for calculating the average candlestick size (default: 12).
*   `InpMAPeriod`: Trend MA period (default: 5).
*   `InpPrice`: Price type to use for calculations (default: `PRICE_CLOSE`).

### Specific Indicator Parameters
*   `InpPeriodCCI` (for CCI-based robots): CCI period (default: 37).
*   `InpPeriodRSI` (for RSI-based robots): RSI period (default: 37).

### Trade Parameters
*   `InpDuration`: Position holding time in bars (default: 10).
*   `InpSL`: Stop Loss in points (default: 200).
*   `InpTP`: Take Profit in points (default: 200).
*   `InpSlippage`: Slippage in points (default: 10).

### Money Management
*   `InpLot`: Lot size for trades (default: 0.1).

### Expert ID
*   `InpMagicNumber`: A unique number to identify trades opened by a specific EA.
    *   `DarkCloud PiercingLine CCI`: 120500
    *   `HangingMan Hammer CCI`: 124100
    *   `DarkCloud PiercingLine RSI`: 120700

## Python Utilities

This repository also includes Python utilities for file management and automation.

### Setup

#### Option 1: Using Docker (Recommended)

```bash
# Build the Docker image
docker build -t nuna-tools .

# Or use docker-compose
docker-compose up -d
```

#### Option 2: Local Installation

```bash
# Using bash (Linux/Mac)
./setup.sh

# Or manually
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### Tools

#### Google Drive Cleanup (`gdrive_cleanup.py`)
Audit, find duplicates, and clean up Google Drive files.

```bash
# Local usage
python gdrive_cleanup.py audit --top 50

# Docker usage
docker run --rm -v $(pwd)/credentials.json:/app/credentials.json nuna-tools python gdrive_cleanup.py audit --top 50

# Find duplicates
python gdrive_cleanup.py duplicates --show 10

# Move files to trash (requires confirmation with actual count)
python gdrive_cleanup.py trash-query --name-contains "old" --apply --confirm "TRASH 5 FILES"
```

#### Trading Data Manager (`trading_data_manager.py`)
Manage trading logs and reports with automated CSV to XLSX conversion.

```bash
# Local usage
python trading_data_manager.py init

# Docker usage
docker run --rm -v $(pwd)/data:/data nuna-tools python trading_data_manager.py init --root /data

# Convert CSV files and organize (dry-run)
python trading_data_manager.py run

# Apply changes
python trading_data_manager.py run --apply
```

### Docker Deployment

#### Using Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

#### Manual Docker Commands

```bash
# Build image
docker build -t nuna-tools .

# Run with mounted credentials
docker run --rm \
  -v $(pwd)/credentials.json:/app/credentials.json \
  -v $(pwd)/data:/data \
  nuna-tools python gdrive_cleanup.py audit --top 20

# Run tests in container
docker run --rm nuna-tools python -m unittest discover -s . -p "test_*.py"
```

## Development

### Running Tests

```bash
python -m unittest discover -s . -p "test_*.py" -v
```

### CI/CD

The repository uses GitHub Actions for continuous integration and deployment:
- **CI Workflow**: Python syntax checking, unit tests, CLI smoke tests, Docker build & test
- **Deploy Workflow**: Automated Docker image building and publishing to GitHub Container Registry

See [`.github/workflows/ci.yml`](.github/workflows/ci.yml) and [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) for details.

#### Deployment to VPS

To deploy on your VPS:

```bash
# Pull the latest image
docker pull ghcr.io/a6-9v/nuna:main

# Run with docker-compose
docker-compose up -d
```

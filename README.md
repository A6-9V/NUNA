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
# Audit largest files
python gdrive_cleanup.py audit --top 50

# Find duplicates
python gdrive_cleanup.py duplicates --show 10

# Move files to trash (requires confirmation with actual count)
python gdrive_cleanup.py trash-query --name-contains "old" --apply --confirm "TRASH 5 FILES"
```

#### Trading Data Manager (`trading_data_manager.py`)
Manage trading logs and reports with automated CSV to XLSX conversion.

```bash
# Initialize folder structure
python trading_data_manager.py init

# Convert CSV files and organize (dry-run)
python trading_data_manager.py run

# Apply changes
python trading_data_manager.py run --apply
```

## Development

### Running Tests

```bash
python -m unittest discover -s . -p "test_*.py" -v
```

### CI/CD

The repository uses GitHub Actions for continuous integration:
- Python syntax checking
- Unit tests
- CLI smoke tests

See [`.github/workflows/ci.yml`](.github/workflows/ci.yml) for details.

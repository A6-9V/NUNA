# Trading Bridge System

Complete automated trading system with Python-MQL5 bridge, multi-broker API support, and multi-symbol trading.

## Overview

This system provides:
- **Python Trading Engine** - Strategy analysis and signal generation
- **MQL5 Bridge** - ZeroMQ-based communication between Python and MQL5
- **MQL.io Service** - Comprehensive MQL5 operations management
- **Multi-Broker Support** - Trade on Exness and other brokers with API access
- **Multi-Symbol Trading** - Manage trading across multiple symbols simultaneously
- **Background Service** - Runs 24/7 without user interaction
- **Auto-Start** - Automatically starts on system boot

## Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   LAPTOP (NuNa) │◄───────►│   VPS (Remote)   │
│                 │  Sync   │                 │
│  - Python Code  │         │  - MT5 Terminal │
│  - Strategy     │         │  - Execution    │
│  - Analysis     │         │  - Uptime       │
│  - MQL.io       │         │                 │
└─────────────────┘         └─────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
              ┌──────▼──────┐
              │   Bridge    │
              │ Python↔MQL5│
              └─────────────┘
```

## Quick Start

### 1. Setup Directory Structure

```powershell
.\setup-trading-drive.ps1
```

### 2. Install Python Dependencies

```powershell
cd trading-bridge
pip install -r requirements.txt
```

### 3. Configure Brokers

Copy `config/brokers.json.example` to `config/brokers.json` and configure your broker API keys.

**IMPORTANT**: `brokers.json` is gitignored - never commit it!

### 4. Configure Symbols

Copy `config/symbols.json.example` to `config/symbols.json` and configure your trading symbols.

### 5. Security Check

```powershell
.\security-check-trading.ps1
```

### 6. Start System

```powershell
.\start-trading-system-admin.ps1
```

### 7. Start MQL.io Service (Optional - NEW)

```powershell
.\start-mql-io-service.ps1
```

Or use the batch file:
```
START-MQL-IO-SERVICE.bat
```

### 8. Setup Auto-Start (Optional)

```powershell
.\setup-trading-auto-start.ps1
```

## Directory Structure

```
trading-bridge/
├── python/
│   ├── bridge/          # MQL5 bridge
│   ├── brokers/         # Broker API implementations
│   ├── mql_io/          # MQL.io service
│   ├── strategies/      # Trading strategies
│   ├── trader/          # Multi-symbol trader
│   ├── services/        # Background services
│   ├── security/        # Credential management
│   └── utils/           # Utilities (log parser, etc.)
├── mql5/
│   ├── Experts/         # MQL5 Expert Advisors
│   └── Include/         # MQL5 includes
├── config/              # Configuration (gitignored)
├── logs/                # Logs (gitignored)
└── data/                # Trading data (gitignored)
```

## Components

### Python Bridge
- **mql5_bridge.py** - ZeroMQ server for Python side
- **signal_manager.py** - Trade signal queue and validation

### MQL.io Service (NEW)
- **mql_io_service.py** - MQL5 operations management service
- **api_handler.py** - RESTful API interface
- **operations_manager.py** - State and operations management
- See `MQL-IO-README.md` for detailed documentation

### Broker APIs
- **base_broker.py** - Abstract base class
- **exness_api.py** - Exness broker implementation
- **broker_factory.py** - Broker factory pattern

### Multi-Symbol Trader
- **multi_symbol_trader.py** - Manages trading across symbols

### Background Service
- **background_service.py** - Main service that runs 24/7

### Utilities
- **log_parser.py** - Parse MT5 mobile app logs
- **parse_mt5_log.py** - CLI tool for log parsing
- See `python/utils/LOG_PARSER_README.md` for details

## Configuration

See `CONFIGURATION.md` for detailed setup instructions.

## Security

See `SECURITY.md` for security best practices.

## Troubleshooting

1. **Python service not starting**: Check Python installation and dependencies
2. **Bridge connection failed**: Verify port 5500 is not in use and firewall is configured
3. **Broker API errors**: Check API keys in Windows Credential Manager
4. **MQL5 EA not receiving signals**: Verify EA is attached to chart and bridge is running

## Telegram Notifications (Optional)

The Python background service can send Telegram alerts on:
- Service start
- Minimal-mode warnings (missing modules)
- Startup errors
- Service stop

### Configure secrets (recommended)

Store these keys via Windows Credential Manager (preferred) or environment variables:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

Because the system uses the `TradingBridge_` prefix internally, the environment variable fallback names are:
- `TRADINGBRIDGE_TELEGRAM_BOT_TOKEN`
- `TRADINGBRIDGE_TELEGRAM_CHAT_ID`

### Quick env-var setup (example)

```powershell
# User-level
setx TRADINGBRIDGE_TELEGRAM_BOT_TOKEN "PASTE_TOKEN_HERE"
setx TRADINGBRIDGE_TELEGRAM_CHAT_ID "PASTE_CHAT_ID_HERE"
```

Restart the service after setting them.

## Logs

All logs are in `trading-bridge/logs/`:
- `mql5_bridge_YYYYMMDD.log` - Bridge communication
- `trading_service_YYYYMMDD.log` - Service operations
- `orchestrator_YYYYMMDD.log` - Orchestrator monitoring

## Support

For issues or questions:
1. Check log files
2. Run security check: `.\security-check-trading.ps1`
3. Verify configuration files
4. Check service status


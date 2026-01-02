# MQL.io Quick Start Guide

## What is MQL.io?

MQL.io is a comprehensive service for managing and monitoring MQL5 operations, providing enhanced control over Expert Advisors, scripts, and indicators in the trading system.

## Installation

Already included! No additional installation needed if you have the trading-bridge system.

## Quick Start

### 1. Start the Service

**Option A: PowerShell**
```powershell
.\start-mql-io-service.ps1
```

**Option B: Batch File**
```
START-MQL-IO-SERVICE.bat
```

**Option C: Python Direct**
```bash
cd trading-bridge/python
python -m mql_io.mql_io_service
```

### 2. Configure (Optional)

Copy and edit the configuration:
```powershell
cd trading-bridge/config
copy mql_io.json.example mql_io.json
notepad mql_io.json
```

### 3. Verify Installation

Run the test suite:
```bash
cd trading-bridge/python
python -m mql_io.test_mql_io
```

## Basic Usage

### Python API

```python
from mql_io import MQLIOService

# Create and start service
service = MQLIOService()
service.start()

# Get status
status = service.get_status()
print(f"Service running: {status['running']}")

# Get Expert Advisors
eas = service.get_expert_advisors()

# Execute a script
result = service.execute_script("MyScript")

# Get operations log
logs = service.get_operations_log(limit=50)
```

### Integration with Trading Bridge

```python
from bridge.mql5_bridge import MQL5Bridge
from mql_io import MQLIOService

# Initialize bridge
bridge = MQL5Bridge(port=5500)

# Initialize MQL.io with bridge
mql_io = MQLIOService(bridge=bridge)

# Start both
bridge.start()
mql_io.start()
```

## Key Features

1. **Expert Advisor Monitoring** - Real-time EA status tracking
2. **Script Execution** - Execute and track MQL5 scripts
3. **Indicator Monitoring** - Monitor indicator calculations
4. **Operations Logging** - Comprehensive operation history
5. **API Interface** - RESTful API for programmatic access
6. **Auto-Recovery** - Automatic recovery from EA errors (optional)

## Configuration Options

| Setting | Default | Description |
|---------|---------|-------------|
| `monitor_interval` | 10 | Monitoring interval in seconds |
| `log_retention_days` | 30 | Days to retain operation logs |
| `max_operations_log` | 1000 | Max operations in memory |
| `auto_restart_eas` | false | Auto-restart failed EAs |

## Common Operations

### Monitor Expert Advisors

```python
from mql_io import MQLIOService

service = MQLIOService()
eas = service.get_expert_advisors()

for ea_name, ea_info in eas.items():
    print(f"EA: {ea_name}")
    print(f"  Status: {ea_info['status']}")
```

### Execute Scripts

```python
result = service.execute_script(
    "AnalysisScript",
    parameters={"symbol": "EURUSD", "timeframe": "H1"}
)

if result['status'] == 'success':
    print("Script executed successfully")
```

### View Operations Log

```python
logs = service.get_operations_log(limit=100)

for log in logs:
    print(f"[{log['timestamp']}] {log['type']}: {log['message']}")
```

## API Endpoints

The API handler provides these endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/status` | GET | Service status |
| `/expert-advisors` | GET | EA information |
| `/execute-script` | POST | Execute script |
| `/operations-log` | GET | Operations log |
| `/indicator` | GET | Indicator value |

## Logging

Logs are stored in:
- `trading-bridge/logs/mql_io_service_YYYYMMDD.log`
- `trading-bridge/logs/mql_io_operations_YYYYMMDD.log`

## Troubleshooting

### Service won't start
1. Check Python installation: `python --version`
2. Install dependencies: `pip install -r trading-bridge/requirements.txt`
3. Check logs in `trading-bridge/logs/`

### Import errors
1. Ensure you're in the correct directory: `cd trading-bridge/python`
2. Check Python path includes the directory
3. Verify all files exist in `trading-bridge/python/mql_io/`

### Bridge connection issues
1. Verify MQL5 bridge is running on port 5500
2. Check firewall settings
3. Ensure ZeroMQ is installed: `pip install pyzmq`

## Next Steps

- Read the complete documentation: `trading-bridge/MQL-IO-README.md`
- Configure your settings in `config/mql_io.json`
- Integrate with your existing trading system
- Set up auto-start (optional)

## Support Files

- **MQL-IO-README.md** - Complete documentation
- **start-mql-io-service.ps1** - PowerShell launcher
- **START-MQL-IO-SERVICE.bat** - Quick launcher
- **config/mql_io.json.example** - Configuration template
- **test_mql_io.py** - Test suite

## Security

MQL.io follows the same security practices as the trading bridge:
- Configuration files are gitignored
- State files are gitignored
- Logs are excluded from version control
- No credentials in code

## Performance

- **CPU**: Minimal (< 1% typical)
- **Memory**: ~50MB base + operation logs
- **Disk**: Logs rotate automatically
- **Network**: Only when communicating with bridge

## Updates

MQL.io is part of the trading-bridge system. Updates are included with trading-bridge updates.

## Version

Current version: 1.0.0

Last updated: 2024-12-24

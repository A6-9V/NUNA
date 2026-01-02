# MQL.io - MQL5 Operations Management Service

MQL.io is a comprehensive service for managing and monitoring MQL5 operations, providing enhanced control over Expert Advisors, scripts, and indicators.

## Features

### Core Features
- **Expert Advisor Management** - Monitor and control EAs in real-time
- **Script Execution** - Execute and track MQL5 scripts
- **Indicator Monitoring** - Monitor indicator calculations and values
- **Operations Logging** - Comprehensive operation history and logging
- **API Interface** - RESTful API for programmatic access
- **Auto-Recovery** - Automatic recovery from EA errors (optional)

### Architecture Integration
MQL.io integrates seamlessly with the existing trading bridge:

```
┌─────────────────┐
│  Python Engine  │
│  - Strategies   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│   MQL.io        │────►│  MQL5 Bridge    │
│   Service       │     │  (Port 5500)    │
└─────────────────┘     └────────┬────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Operations     │     │  MT5 Terminal   │
│  Manager        │     │  + EAs          │
└─────────────────┘     └─────────────────┘
```

## Installation

MQL.io is included in the trading bridge Python package. No additional installation required.

### Dependencies

All dependencies are included in the main `requirements.txt`:
```
pyzmq>=25.1.0
requests>=2.31.0
python-dotenv>=1.0.0
```

## Configuration

### 1. Copy Configuration Template

```powershell
cd trading-bridge/config
copy mql_io.json.example mql_io.json
```

### 2. Edit Configuration

Edit `config/mql_io.json` with your preferences:

```json
{
  "monitor_interval": 10,
  "enabled_features": {
    "ea_monitoring": true,
    "script_tracking": true,
    "indicator_monitoring": true
  }
}
```

### Configuration Options

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `monitor_interval` | int | Monitoring interval in seconds | 10 |
| `log_retention_days` | int | Days to retain operation logs | 30 |
| `max_operations_log` | int | Maximum operations in memory | 1000 |
| `auto_restart_eas` | bool | Auto-restart failed EAs | false |
| `enabled_features` | object | Feature toggles | See example |

## Usage

### Starting MQL.io Service

#### As Standalone Service

```python
from mql_io import MQLIOService

# Create service instance
service = MQLIOService()

# Start service
service.start()

# Keep running
while service.running:
    time.sleep(1)
```

#### Integrated with Trading Bridge

```python
from bridge.mql5_bridge import MQL5Bridge
from mql_io import MQLIOService

# Initialize bridge
bridge = MQL5Bridge(port=5500)

# Initialize MQL.io with bridge
mql_io = MQLIOService(bridge=bridge)

# Start both services
bridge.start()
mql_io.start()
```

### API Operations

#### Get Service Status

```python
status = service.get_status()
print(f"Running: {status['running']}")
print(f"Expert Advisors: {status['expert_advisors']}")
```

#### Monitor Expert Advisors

```python
eas = service.get_expert_advisors()
for ea_name, ea_info in eas.items():
    print(f"EA: {ea_name}, Status: {ea_info['status']}")
```

#### Execute Script

```python
result = service.execute_script("MyScript", {"param1": "value1"})
if result['status'] == 'success':
    print("Script executed successfully")
```

#### Get Operations Log

```python
logs = service.get_operations_log(limit=50)
for log in logs:
    print(f"[{log['type']}] {log['message']}")
```

### API Handler Usage

```python
from mql_io import MQLIOAPIHandler

# Create API handler
api_handler = MQLIOAPIHandler(service)

# Route API requests
response = api_handler.route_request("/status", "GET")
print(response)
```

## Operations Manager

The Operations Manager handles state persistence and coordination:

```python
from mql_io.operations_manager import MQLIOOperationsManager

# Create manager
manager = MQLIOOperationsManager()

# Register EA
manager.register_ea("MyEA", {"symbol": "EURUSD", "timeframe": "H1"})

# Update EA status
manager.update_ea_status("MyEA", "running")

# Log operation
manager.log_operation("TRADE", {"action": "open", "symbol": "EURUSD"})

# Get operations
ops = manager.get_operations(limit=100)
```

## Integration Examples

### With Background Service

Integrate MQL.io into the existing background service:

```python
# In background_service.py
from mql_io import MQLIOService

class BackgroundTradingService:
    def __init__(self, bridge_port: int = 5500):
        self.bridge_port = bridge_port
        self.bridge = None
        self.mql_io = None  # Add MQL.io
        
    def start(self):
        # Initialize bridge
        self.bridge = MQL5Bridge(port=self.bridge_port)
        
        # Initialize MQL.io
        self.mql_io = MQLIOService(bridge=self.bridge)
        self.mql_io.start()
        
        # Continue with existing logic...
```

### With Multi-Symbol Trader

```python
# Enhanced trader with MQL.io
from mql_io import MQLIOService

class EnhancedMultiSymbolTrader:
    def __init__(self, bridge, broker_manager, mql_io):
        self.bridge = bridge
        self.broker_manager = broker_manager
        self.mql_io = mql_io
        
    def execute_trade(self, symbol, action):
        # Execute trade
        result = self._do_trade(symbol, action)
        
        # Log with MQL.io
        self.mql_io._log_operation(
            f"Trade: {action} {symbol}",
            "TRADE"
        )
```

## PowerShell Scripts

### Start MQL.io Service

```powershell
# start-mql-io-service.ps1
cd trading-bridge/python
python -m mql_io.mql_io_service
```

### Check MQL.io Status

```powershell
# check-mql-io-status.ps1
cd trading-bridge/python
python -c "from mql_io import MQLIOService; s = MQLIOService(); print(s.get_status())"
```

## Logging

MQL.io creates its own log files:

```
trading-bridge/
└── logs/
    ├── mql_io_service_YYYYMMDD.log    # Service logs
    └── mql_io_operations_YYYYMMDD.log  # Operations logs
```

### Log Levels

- **INFO** - Normal operations
- **WARNING** - Non-critical issues
- **ERROR** - Errors requiring attention
- **DEBUG** - Detailed debugging information

## Security

### Best Practices

1. **Configuration Security** - Keep `mql_io.json` in `.gitignore`
2. **API Access** - Limit API access to localhost by default
3. **Log Security** - Logs are excluded from version control
4. **State Files** - State files stored in `data/mql_io/` (gitignored)

### Protected Files

The following are automatically gitignored:
- `config/mql_io.json`
- `logs/mql_io_*.log`
- `data/mql_io/*`

## Troubleshooting

### Service Won't Start

1. Check Python dependencies: `pip install -r requirements.txt`
2. Verify configuration file exists: `config/mql_io.json`
3. Check logs: `logs/mql_io_service_*.log`

### Bridge Connection Issues

1. Verify MQL5 bridge is running on port 5500
2. Check firewall settings
3. Ensure ZeroMQ is installed: `pip install pyzmq`

### EA Monitoring Not Working

1. Verify `ea_monitoring` is enabled in config
2. Check bridge connection
3. Verify EAs are running in MT5 terminal

## API Reference

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/status` | GET | Get service status |
| `/expert-advisors` | GET | Get EA information |
| `/execute-script` | POST | Execute MQL5 script |
| `/operations-log` | GET | Get operations log |
| `/indicator` | GET | Get indicator value |

### Response Format

All API responses follow this format:

```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2024-12-24T07:20:00.000000"
}
```

## Performance

### Resource Usage

- **CPU**: Minimal (< 1% typical)
- **Memory**: ~50MB base + operation logs
- **Disk**: Logs rotate automatically
- **Network**: Only when communicating with bridge

### Optimization Tips

1. Adjust `monitor_interval` based on needs
2. Set appropriate `log_retention_days`
3. Limit `max_operations_log` for memory efficiency
4. Disable unused features in `enabled_features`

## Future Enhancements

Planned features:
- [ ] WebSocket real-time updates
- [ ] Web dashboard interface
- [ ] Advanced EA auto-recovery
- [ ] Performance metrics collection
- [ ] Multi-terminal support
- [ ] Cloud sync for operation logs

## Support

For issues or questions:
1. Check logs in `trading-bridge/logs/`
2. Review configuration in `config/mql_io.json`
3. Run diagnostics: `python -m mql_io.mql_io_service --check`

## License

Part of the A6-9V trading system project.

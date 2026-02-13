# NUNA MQL5 Integration Hub - Quick Reference

## 🚀 Quick Start

### Start the Service

```bash
# Install dependencies
pip install -r requirements.txt

# Start the service
python main.py
```

The service will start:
- **API Server**: http://localhost:8000
- **Bridge Server**: localhost:5555

## 🌐 API Quick Reference

### Essential Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API information |
| `/health` | GET | Service health status |
| `/system` | GET | System information |
| `/symbols` | GET | List all symbols |
| `/symbols/{symbol}` | GET | Get specific symbol |
| `/config` | GET | Configuration |
| `/docs` | GET | Interactive docs |

### Quick Examples

```bash
# Check health
curl http://localhost:8000/health

# List symbols
curl http://localhost:8000/symbols

# Get EURUSD config
curl http://localhost:8000/symbols/EURUSD

# View API docs in browser
open http://localhost:8000/docs
```

## 🔌 Bridge Server Quick Reference

### Connection

```python
import socket
import json

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(('localhost', 5555))
```

### Commands

```python
# Ping
sock.send(b'{"command":"ping"}\n')

# Get status
sock.send(b'{"command":"status"}\n')

# List symbols
sock.send(b'{"command":"symbols"}\n')

# Read response
response = json.loads(sock.recv(4096).decode())
```

## 📊 Key Features (v2.0.0)

### Enhanced API
- ✅ Multiple REST endpoints
- ✅ Comprehensive health checks
- ✅ System information
- ✅ Symbol management
- ✅ Interactive documentation (Swagger/ReDoc)
- ✅ Global error handling

### Improved Bridge Server
- ✅ JSON-based protocol
- ✅ Multi-threaded client handling
- ✅ Connection pooling
- ✅ Command-based interface
- ✅ Better error handling
- ✅ Timeout management

### Better Logging
- ✅ Structured logging
- ✅ Detailed startup information
- ✅ Connection tracking
- ✅ Error tracing

## 🔧 Configuration

### Environment Variables

```env
# Server Ports
API_PORT=8000
BRIDGE_PORT=5555

# Logging
LOG_LEVEL=INFO

# MT5
MT5_TERMINAL_PATH=/mt5
MT5_ACCOUNT=your_account
MT5_SERVER=your_server

# Symbols
SYMBOLS=EURUSD,GBPUSD,USDJPY
```

### Symbols File

`symbols.json`:
```json
{
  "symbols": [
    {
      "symbol": "EURUSD",
      "enabled": true,
      "risk_percent": 1.0
    }
  ]
}
```

## 📚 Documentation

- **Complete API Reference**: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- **Replit Integration**: [REPLIT_INTEGRATION.md](REPLIT_INTEGRATION.md)
- **Main README**: [README.md](README.md)

## 🧪 Testing

```bash
# Run component tests
python test_integration_hub.py

# Check Python syntax
python -m py_compile main.py

# Test API (requires running server)
curl http://localhost:8000/health
```

## 🌍 Deployment

### Replit
- URL: https://mql-5-integration-hub--genxapitrading.replit.app
- Auto-deploys from GitHub
- Configured in `.replit`

### Docker
```bash
docker-compose up -d
docker-compose logs -f trading-bridge
```

### VPS
```bash
# See VPS_DEPLOYMENT.md for details
./scripts/deploy-vps.sh
```

## 💡 Common Tasks

### Check Service Status
```bash
curl http://localhost:8000/health | jq
```

### List All Symbols
```bash
curl http://localhost:8000/symbols | jq '.symbols[].symbol'
```

### Get System Info
```bash
curl http://localhost:8000/system | jq
```

### Test Bridge Connection
```python
import socket, json
s = socket.socket()
s.connect(('localhost', 5555))
s.recv(1024)  # Welcome message
s.send(b'{"command":"ping"}\n')
print(s.recv(1024))  # Response
s.close()
```

## 🔍 Troubleshooting

### Port Already in Use
```bash
# Change ports in .env
API_PORT=8001
BRIDGE_PORT=5556
```

### MT5 Not Connected
This is normal in cloud/development environments. The service will still work for API operations.

### Module Not Found
```bash
pip install -r requirements.txt
```

### View Logs
```bash
# If running in foreground, logs appear in console
# If using Docker:
docker-compose logs -f trading-bridge
```

## 🔗 Links

- **GitHub**: https://github.com/A6-9V/NUNA
- **Replit**: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS
- **MQL5 Forge**: https://forge.mql5.io/LengKundee/NUNA
- **API Docs**: http://localhost:8000/docs (when running)

## 📝 Version

**Current Version**: 2.0.0  
**Last Updated**: 2026-02-13

## ✨ What's New in 2.0.0

- Enhanced REST API with 7+ endpoints
- Improved bridge server with JSON protocol
- Interactive API documentation
- Better error handling and logging
- System information endpoints
- Symbol management API
- Multi-threaded connection handling
- Comprehensive health checks

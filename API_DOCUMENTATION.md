# NUNA MQL5 Integration Hub API Documentation

## Overview

The NUNA MQL5 Integration Hub provides a comprehensive REST API and bridge service for MetaTrader 5 integration. This service enables seamless communication between MT5 terminals, trading applications, and external services.

**Version**: 2.0.0

## Architecture

The hub consists of two main components:

1. **REST API Server** (Port 8000) - FastAPI-based HTTP/REST interface
2. **Bridge Server** (Port 5555) - TCP socket server for direct MT5 communication

## API Endpoints

### Base URL

- Local: `http://localhost:8000`
- Replit: `https://mql-5-integration-hub--genxapitrading.replit.app`

### 1. Root Endpoint

**GET /** - API information and available endpoints

```bash
curl http://localhost:8000/
```

**Response:**
```json
{
  "name": "NUNA MQL5 Integration Hub",
  "version": "2.0.0",
  "description": "MetaTrader 5 Trading Bridge API",
  "endpoints": {
    "health": "/health",
    "system": "/system",
    "symbols": "/symbols",
    "config": "/config",
    "docs": "/docs"
  },
  "timestamp": "2026-02-13T16:30:00.000000"
}
```

### 2. Health Check

**GET /health** - Comprehensive health status of all services

```bash
curl http://localhost:8000/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-13T16:30:00.000000",
  "services": {
    "mt5_terminal": {
      "connected": true,
      "path": "/mt5"
    },
    "bridge_server": {
      "enabled": true,
      "port": 5555
    },
    "api_server": {
      "enabled": true,
      "port": 8000
    }
  },
  "symbols_loaded": 33
}
```

**Status Values:**
- `healthy` - All systems operational
- `degraded` - Some systems unavailable (e.g., MT5 not connected)

### 3. System Information

**GET /system** - Detailed system and environment information

```bash
curl http://localhost:8000/system
```

**Response:**
```json
{
  "platform": {
    "system": "Linux",
    "release": "5.15.0",
    "version": "#1 SMP",
    "machine": "x86_64",
    "processor": "x86_64",
    "python_version": "3.11.0"
  },
  "environment": {
    "mt5_build": "5572",
    "vps_provider": "EXNESS",
    "vps_region": "SINGAPORE",
    "terminal_name": "NUNA"
  },
  "configuration": {
    "bridge_port": 5555,
    "api_port": 8000,
    "log_level": "INFO"
  },
  "timestamp": "2026-02-13T16:30:00.000000"
}
```

### 4. Symbols Management

**GET /symbols** - List all configured trading symbols

```bash
curl http://localhost:8000/symbols
```

**Response:**
```json
{
  "count": 33,
  "symbols": [
    {
      "symbol": "EURUSD",
      "broker": "EXNESS_DEMO",
      "enabled": true,
      "risk_percent": 1.0,
      "max_positions": 1,
      "min_lot_size": 0.01,
      "max_lot_size": 10.0,
      "description": "Euro vs US Dollar"
    }
  ],
  "timestamp": "2026-02-13T16:30:00.000000"
}
```

**GET /symbols/{symbol}** - Get specific symbol configuration

```bash
curl http://localhost:8000/symbols/EURUSD
```

**Response:**
```json
{
  "symbol": "EURUSD",
  "config": {
    "symbol": "EURUSD",
    "broker": "EXNESS_DEMO",
    "enabled": true,
    "risk_percent": 1.0,
    "max_positions": 1,
    "min_lot_size": 0.01,
    "max_lot_size": 10.0,
    "description": "Euro vs US Dollar"
  },
  "timestamp": "2026-02-13T16:30:00.000000"
}
```

**Error Response (404):**
```json
{
  "detail": "Symbol INVALID not found"
}
```

### 5. Configuration

**GET /config** - Get current configuration (non-sensitive data only)

```bash
curl http://localhost:8000/config
```

**Response:**
```json
{
  "account": {
    "terminal_name": "NUNA",
    "mql5_profile": "LengKundee",
    "ea_name": "EXNESS_GenX_Trader"
  },
  "network": {
    "bridge_port": 5555,
    "api_port": 8000
  },
  "integrations": {
    "replit_project": "genxdbxfx3",
    "github_repo": "A6-9V/NUNA",
    "mql5_repo": "https://forge.mql5.io/LengKundee/A6-9V-GenX_FX.main.git"
  },
  "symbols_count": 33,
  "timestamp": "2026-02-13T16:30:00.000000"
}
```

### 6. Interactive Documentation

**GET /docs** - Swagger UI interactive API documentation

```bash
# Open in browser
http://localhost:8000/docs
```

**GET /redoc** - ReDoc alternative documentation

```bash
# Open in browser
http://localhost:8000/redoc
```

## Bridge Server Protocol

The Bridge Server provides a TCP socket interface for direct communication with MT5 Expert Advisors.

### Connection

```python
import socket
import json

# Connect to bridge
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(('localhost', 5555))

# Receive welcome message
welcome = sock.recv(4096)
print(json.loads(welcome.decode()))
# {"status": "connected", "service": "NUNA MQL5 Bridge", "version": "2.0.0"}
```

### Supported Commands

#### 1. Ping

Test connection:

```python
request = {"command": "ping"}
sock.send(json.dumps(request).encode() + b"\n")

response = json.loads(sock.recv(4096).decode())
# {"status": "ok", "command": "ping", "message": "pong"}
```

#### 2. Status

Get bridge status:

```python
request = {"command": "status"}
sock.send(json.dumps(request).encode() + b"\n")

response = json.loads(sock.recv(4096).decode())
# {
#   "status": "ok",
#   "command": "status",
#   "mt5_connected": true,
#   "symbols_count": 33
# }
```

#### 3. Symbols

List available symbols:

```python
request = {"command": "symbols"}
sock.send(json.dumps(request).encode() + b"\n")

response = json.loads(sock.recv(4096).decode())
# {
#   "status": "ok",
#   "command": "symbols",
#   "symbols": ["EURUSD", "GBPUSD", "USDJPY", ...]
# }
```

#### Unknown Command

```python
request = {"command": "unknown"}
sock.send(json.dumps(request).encode() + b"\n")

response = json.loads(sock.recv(4096).decode())
# {
#   "status": "unknown_command",
#   "command": "unknown",
#   "message": "Unknown command: unknown"
# }
```

### Error Handling

Invalid JSON:
```python
sock.send(b"invalid json\n")

response = json.loads(sock.recv(4096).decode())
# {"status": "error", "message": "Invalid JSON format"}
```

## Usage Examples

### Python

```python
import requests

# Check API health
response = requests.get('http://localhost:8000/health')
print(response.json())

# Get all symbols
response = requests.get('http://localhost:8000/symbols')
symbols = response.json()
print(f"Total symbols: {symbols['count']}")

# Get specific symbol
response = requests.get('http://localhost:8000/symbols/EURUSD')
eurusd = response.json()
print(f"EURUSD config: {eurusd}")
```

### MQL5

```mql5
// Connect to bridge server
int socket = SocketCreate();
if(SocketConnect(socket, "localhost", 5555, 1000))
{
   Print("Connected to NUNA Bridge");
   
   // Send ping command
   string request = "{\"command\":\"ping\"}\n";
   SocketSend(socket, request);
   
   // Receive response
   string response = "";
   SocketReceive(socket, response, 100);
   Print("Response: ", response);
   
   SocketClose(socket);
}
```

### JavaScript/Node.js

```javascript
const net = require('net');

// Connect to bridge
const client = net.createConnection({ port: 5555 }, () => {
  console.log('Connected to NUNA Bridge');
  
  // Send command
  const request = JSON.stringify({ command: 'status' }) + '\n';
  client.write(request);
});

// Handle response
client.on('data', (data) => {
  const response = JSON.parse(data.toString());
  console.log('Response:', response);
  client.end();
});
```

### cURL

```bash
# Check health
curl http://localhost:8000/health | jq

# Get system info
curl http://localhost:8000/system | jq

# Get all symbols
curl http://localhost:8000/symbols | jq '.symbols[] | .symbol'

# Get specific symbol
curl http://localhost:8000/symbols/EURUSD | jq
```

## Configuration

### Environment Variables

Configure the service via environment variables in `.env`:

```env
# API Configuration
API_PORT=8000
BRIDGE_PORT=5555
LOG_LEVEL=INFO

# MT5 Configuration
MT5_TERMINAL_PATH=/mt5
MT5_ACCOUNT=your_account
MT5_SERVER=your_server

# Symbols
SYMBOLS=EURUSD,GBPUSD,USDJPY,AUDUSD

# Identity
TERMINAL_NAME=NUNA
MQL5_PROFILE=LengKundee
EA_NAME=EXNESS_GenX_Trader
```

### Symbols Configuration

Configure symbols in `symbols.json`:

```json
{
  "symbols": [
    {
      "symbol": "EURUSD",
      "broker": "EXNESS_DEMO",
      "enabled": true,
      "risk_percent": 1.0,
      "max_positions": 1,
      "min_lot_size": 0.01,
      "max_lot_size": 10.0,
      "description": "Euro vs US Dollar"
    }
  ]
}
```

## Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 404 | Resource not found (e.g., symbol not configured) |
| 500 | Internal server error |

## Logging

The service logs all operations:

```
2026-02-13 16:30:00 - __main__ - INFO - Starting NUNA MQL5 Integration Hub Service...
2026-02-13 16:30:00 - __main__ - INFO - ✓ Loaded 33 trading symbols
2026-02-13 16:30:00 - __main__ - INFO - ✓ MT5 terminal connection available
2026-02-13 16:30:01 - __main__ - INFO - Enhanced bridge server listening on port 5555
2026-02-13 16:30:01 - __main__ - INFO - Starting API server on port 8000
```

## Security Considerations

1. **No Authentication Required** - Currently open for local development
2. **Non-Sensitive Data Only** - API endpoints do not expose passwords or keys
3. **Environment Variables** - Sensitive data stored in `.env` (git-ignored)
4. **Network Binding** - Binds to `0.0.0.0` for Docker compatibility

For production:
- Add authentication (API keys, JWT)
- Enable HTTPS/TLS
- Restrict network access
- Add rate limiting

## Deployment

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start service
python main.py
```

### Docker

```bash
# Build and start
docker-compose up -d

# Check logs
docker-compose logs -f trading-bridge
```

### Replit

The service is deployed on Replit:
- URL: `https://mql-5-integration-hub--genxapitrading.replit.app`
- Configured via `.replit` and `replit.nix`
- Auto-deploys on push to GitHub

## Monitoring

Monitor service health:

```bash
# Health check
curl http://localhost:8000/health

# System metrics
curl http://localhost:8000/system

# Check logs
tail -f logs/nuna.log
```

## Support

- **GitHub**: https://github.com/A6-9V/NUNA
- **MQL5 Forge**: https://forge.mql5.io/LengKundee/NUNA
- **Replit**: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS

## Version History

### 2.0.0 (2026-02-13)
- Enhanced API with multiple endpoints
- Improved bridge server with JSON protocol
- Better error handling and logging
- Interactive API documentation
- System information endpoints
- Symbol management API

### 1.0.0 (Initial Release)
- Basic bridge server
- Simple health check
- MT5 terminal connection

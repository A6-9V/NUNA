# EXNESS Docker Setup

## 📓 Knowledge Base
- **NotebookLM**: [Access here](https://notebooklm.google.com/notebook/e8f4c29d-9aec-4d5f-8f51-2ca168687616)
- **Note**: This notebook is available for reading and writing. AI agents must read it before starting work.


Docker containerization setup for EXNESS MetaTrader 5 terminal with supporting services.

## 🌐 Cloud Development & Repository Integration

**Multiple Development Environments:**
- 💻 **GitHub**: https://github.com/A6-9V/NUNA (Primary repository)
- ☁️ **Replit**: https://replit.com/@mouy-leng/httpsgithubcomA6-9VMetatrader5EXNESS (Cloud IDE)
- 📦 **Forge MQL5**: https://forge.mql5.io/LengKundee/NUNA (MQL5 community)

**Quick Links:**
- [Replit Integration Guide](REPLIT_INTEGRATION.md) - Develop in the cloud
- [Forge MQL5 Setup Guide](FORGE_MQL5_SETUP.md) - Sync with MQL5 community

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Services](#services)
- [Documentation](#documentation)
- [Directory Structure](#directory-structure)
- [Management](#management)
- [Troubleshooting](#troubleshooting)

## Architecture

This Docker setup provides:
- **Trading Bridge Service**: Connects Docker services to your native MT5 installation
- **PostgreSQL**: Trade history and data storage
- **Redis**: Caching and real-time data
- **InfluxDB**: Time-series metrics storage
- **Grafana**: Monitoring and visualization dashboard

See [Architecture Documentation](docs/ARCHITECTURE.md) for detailed system overview.

## Prerequisites

1. **Docker Desktop** installed and running
   - Download from: https://www.docker.com/products/docker-desktop
   - Ensure Docker Desktop is running before launching

2. **MT5 Terminal** installed at:
   - `D:\Users\lengk\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075`

## Quick Start

### Step 1: Configure Environment

```powershell
# Copy environment template
Copy-Item env.template .env

# Or use the setup script
.\scripts\setup-env.ps1

# Edit with your credentials
notepad .env
```

### Step 2: Launch Services

**Option A: PowerShell Script (Recommended)**
```powershell
.\scripts\launch-docker.ps1
```

**Option B: Batch File**
```powershell
.\scripts\launch-docker.bat
```

**Option C: Manual**
```powershell
docker-compose up -d
```

**Option D: VS Code Tasks (Recommended for VS Code Users)**
```
Press Ctrl+Shift+P (or Cmd+Shift+P on Mac)
Type "Tasks: Run Task"
Select "Start Project"
```

Available VS Code tasks:
- **Start Project**: Start all Docker services (default build task: Ctrl+Shift+B)
- **Stop Project**: Stop all Docker services
- **Full Project Setup**: Complete setup including Python environment, validation, and Docker startup
- **Setup Python Environment**: Initialize Python virtual environment and install dependencies
- **Validate Environment**: Validate environment configuration
- **Check Docker Status**: View status of all containers
- **View Docker Logs**: Stream logs from all containers
- **Restart Docker Services**: Restart all containers
- **Rebuild Docker Containers**: Rebuild all containers from scratch

### Step 3: Verify Services

```powershell
docker-compose ps
```

You should see 5 containers running:
- ✅ exness-trading-bridge
- ✅ exness-postgres
- ✅ exness-redis
- ✅ exness-influxdb
- ✅ exness-grafana

## Configuration

### Environment Variables

All configuration is managed through the `.env` file. See [Configuration Guide](docs/CONFIGURATION.md) for detailed information.

**Required Variables**:
- `EXNESS_LOGIN` - Your MT5 account number
- `EXNESS_PASSWORD` - Your MT5 account password
- `EXNESS_SERVER` - MT5 server name
- `MT5_PATH` - Path to MT5 terminal directory

**Optional Variables**:
- `SYMBOLS` - Comma-separated list of trading symbols (33+ supported)
- `BRIDGE_PORT` - Bridge port (default: 5555)
- `API_PORT` - API port (default: 8000)

### Symbols Configuration

**Method 1: Environment Variable** (Simple)
```env
SYMBOLS=EURUSD,GBPUSD,USDJPY,AUDUSD
```

**Method 2: JSON Configuration** (Detailed)
Edit `config/symbols.json` for per-symbol risk management settings.

**Method 3: Hybrid** (Recommended)
Use both - env var for quick list, JSON for detailed settings.

See [Configuration Guide](docs/CONFIGURATION.md) for more details.

## Services

Once launched, the following services are available:

| Service | URL | Credentials |
|---------|-----|-------------|
| Trading Bridge API | http://localhost:8000 | - |
| Trading Bridge Port | localhost:5555 | - |
| Grafana Dashboard | http://localhost:3000 | admin/admin |
| PostgreSQL | localhost:5432 | exness_user/exness_password |
| Redis | localhost:6379 | - |
| InfluxDB | http://localhost:8086 | admin/adminpassword |

## Documentation

- [Quick Start Guide](docs/QUICK-START.md) - Step-by-step setup instructions
- [Demo Account Setup](docs/DEMO-SETUP.md) - Demo account configuration
- [Architecture](docs/ARCHITECTURE.md) - System architecture and design
- [Configuration Guide](docs/CONFIGURATION.md) - Detailed configuration reference
- [Migration Guide](docs/MIGRATION-GUIDE.md) - **NEW**: Guide for migrating to restructured project
- [MQL5 Git Setup](docs/MQL5-GIT-SETUP.md) - Git repository configuration
- [VPS Deployment](VPS_DEPLOYMENT.md) - **NEW**: Automated VPS deployment guide
- [VPS Hosting](VPS_HOSTING.md) - VPS configuration and management
- [Forge MQL5 Setup](FORGE_MQL5_SETUP.md) - **NEW**: forge.mql5.io integration and sync
- [Replit Integration](REPLIT_INTEGRATION.md) - **NEW**: Cloud development with Replit

## Directory Structure

```
exness-docker/
├── docker/
│   └── trading-bridge/
│       ├── Dockerfile
│       └── requirements.txt
├── config/
│   ├── brokers.json
│   ├── symbols.json
│   └── mt5-demo.json
├── scripts/
│   ├── launch-docker.ps1
│   ├── setup-env.ps1
│   ├── check-status.ps1
│   └── *.bat files
├── docs/
│   ├── QUICK-START.md
│   ├── DEMO-SETUP.md
│   ├── ARCHITECTURE.md
│   ├── CONFIGURATION.md
│   └── MIGRATION-GUIDE.md
├── bridge/
│   ├── __init__.py
│   └── main.py
├── logs/
├── data/
├── init-db/
├── grafana/
│   └── provisioning/
├── docker-compose.yml
├── env.template
├── .gitignore
└── README.md
```

## Management

### View Logs
```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f trading-bridge
```

### Stop Services
```powershell
.\scripts\stop-docker.ps1
# or
docker-compose down
```

### Restart Services
```powershell
docker-compose restart
```

### Rebuild Containers
```powershell
docker-compose build --no-cache
docker-compose up -d
```

### Check Status
```powershell
.\scripts\check-status.ps1
# or
docker-compose ps
```

## Connecting MT5 EA to Docker

1. **Ensure Docker services are running**:
   ```powershell
   docker-compose ps
   ```

2. **Configure your MT5 EA**:
   - BridgePort: `5555` (or value from `BRIDGE_PORT` env var)
   - BrokerName: `EXNESS_DEMO` (or your broker name)
   - AutoExecute: `true`

3. **Attach EA to chart** in MT5 terminal

## Troubleshooting

### Docker not running
- Start Docker Desktop
- Verify with: `docker ps`

### Port already in use
- Check what's using the port: `netstat -ano | findstr :5555`
- Change port in `.env` file

### MT5 path not found
- Verify MT5 installation path
- Update `MT5_PATH` in `.env` file

### Container fails to start
- Check logs: `docker-compose logs trading-bridge`
- Verify `.env` file exists and is configured
- Ensure Docker has enough resources allocated

### Configuration issues
- Verify `.env` file exists in root directory
- Check all required environment variables are set
- Review [Configuration Guide](docs/CONFIGURATION.md)

## Health Checks

Check service health:
```powershell
# API health check
curl http://localhost:8000/health

# Container health
docker-compose ps
```

## Data Persistence

All data is stored in Docker volumes:
- `postgres-data`: Database data
- `redis-data`: Cache data
- `influxdb-data`: Time-series data
- `grafana-data`: Grafana configuration

To remove all data:
```powershell
docker-compose down -v
```

## Security

- **Never commit `.env` file** to version control
- Credentials are stored in `.env` (git-ignored)
- Use strong passwords for database services
- Restrict network access to exposed ports

## Next Steps

1. Configure EXNESS credentials in `.env`
2. Set up Grafana dashboards for monitoring
3. Connect your MT5 EA to the bridge service
4. Configure trading strategies and risk management
5. Review [Architecture Documentation](docs/ARCHITECTURE.md)

---

**Note**: This setup connects to your native MT5 installation. The MT5 terminal itself runs on Windows, while supporting services run in Docker containers.

**Last Updated**: 2025-12-29

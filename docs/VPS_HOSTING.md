# VPS Hosting Configuration

This document tracks the VPS hosting configuration for NUNA MQL5 Trading Robots.

## Active VPS Servers

### VPS Singapore 09

**Status:** Active  
**Start Date:** 2026.01.18  
**End Date:** 2026.02.18

| Property | Value |
|----------|-------|
| **VPS ID** | #6773048 |
| **VPS Name** | VPS Singapore 09 |
| **Client** | Kea MOUYLENG |
| **Account** | mql5_internal |
| **Tariff** | #4 |
| **Monthly Cost** | $15.00 |
| **Order ID** | 15740071 |
| **Start Date** | 2026.01.18 |
| **End Date** | 2026.02.18 |

#### MT5 Account Details

| Property | Value |
|----------|-------|
| **MT5 Account** | 411534497 |
| **Account Name** | Exness MT5_Auto-Trad |
| **Server** | Exness-MT5Real8 |
| **Log Path** | D:\Users\USERNAME\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Logs\hosting.6773048.terminal |

**Note:** Replace `USERNAME` with your Windows username and verify your drive letter (typically C:\ or D:\).

#### Server Details

- **Location:** Singapore
- **Purpose:** MQL5 Trading Robot hosting
- **Services:** Running automated trading strategies 24/7
- **Trading Platform:** MetaTrader 5 (MT5)
- **Broker:** Exness

#### Deployment

**🚀 Automated Deployment Available!**

For detailed deployment instructions, see
[VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md).

**Quick Setup:**

1. **Automated Deployment via GitHub Actions:**
   - Configure GitHub Secrets (VPS_HOST, VPS_USER, VPS_SSH_KEY)
   - Enable VPS_DEPLOYMENT_ENABLED variable
   - Push to main branch - automatic deployment!

2. **Manual Deployment Script:**
   ```bash
   export VPS_HOST="your-vps-ip"
   export VPS_USER="your-username"
   ./scripts/deploy-vps.sh
   ```

3. **Direct VPS Deployment:**
   ```bash

   # On your VPS

   cd /opt/nuna
   docker pull ghcr.io/a6-9v/nuna:main
   docker-compose -f docker-compose.vps.yml up -d
   ```

For complete setup instructions, troubleshooting, and monitoring, see:

- [VPS Deployment Guide](VPS_DEPLOYMENT.md) - Comprehensive deployment documentation
- [CI/CD Documentation](CI_CD_DOCUMENTATION.md) - Automated deployment workflows

#### Legacy Manual Deployment

To deploy the NUNA trading robots to VPS Singapore 09 (manual method):

1. **Connect to the VPS:**
   - For Windows VPS: Use Remote Desktop Connection (RDP)
   - For Linux VPS: Use SSH
   - Connection details should be provided by the VPS hosting provider
2. Install MetaTrader 5 platform if not already installed
3. Deploy trading robots from the repository:

   - Copy Expert Advisors from `Experts/` directory
   - Copy Indicators from `Indicators/` directory
   - Copy Include files from `Include/` directory
4. Configure the VPS Monitor indicator (`Logs/Indicators/Downloads/VPS
Monitor.mq5`) to monitor the VPS status

#### Docker Deployment (Alternative)

For containerized deployment:

```bash

# Pull the latest image

docker pull ghcr.io/a6-9v/nuna:main

# Run with docker-compose

docker-compose -f docker-compose.vps.yml up -d

```bash

See [VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md) for complete Docker deployment guide.

---

## VPS Management

### Adding a New VPS

To document a new VPS server:

1. Add a new section under "Active VPS Servers"
2. Include all relevant details (ID, name, client, account, tariff, cost, etc.)
3. Document deployment procedures specific to that VPS

### Deactivating a VPS

When deactivating a VPS:

1. Update the status to "Inactive"
2. Add deactivation date
3. Move to an "Inactive VPS Servers" section
4. Keep records for reference

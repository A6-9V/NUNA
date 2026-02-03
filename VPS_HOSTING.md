# VPS Hosting Configuration

This document tracks the VPS hosting configuration for NUNA MQL5 Trading Robots.

## Active VPS Servers

### VPS Singapore 09

**Status:** Active  
**Start Date:** 2026.01.18

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

#### Server Details

- **Location:** Singapore
- **Purpose:** MQL5 Trading Robot hosting
- **Services:** Running automated trading strategies 24/7

#### Deployment

To deploy the NUNA trading robots to VPS Singapore 09:

1. Connect to the VPS via Remote Desktop or SSH
2. Install MetaTrader 5 platform if not already installed
3. Deploy trading robots from the repository:
   - Copy Expert Advisors from `Experts/` directory
   - Copy Indicators from `Indicators/` directory
   - Copy Include files from `Include/` directory
4. Configure the VPS Monitor indicator (`Logs/Indicators/Downloads/VPS Monitor.mq5`) to monitor the VPS status

#### Docker Deployment (Alternative)

For containerized deployment:

```bash
# Pull the latest image
docker pull ghcr.io/a6-9v/nuna:main

# Run with docker-compose
docker-compose up -d
```

See [README.md](README.md) for more deployment details.

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

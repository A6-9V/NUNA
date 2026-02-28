# Environment Configuration Guide

This document explains the environment configuration structure for NUNA
VPS/Terminal setup.

## Overview

The NUNA project uses environment variables to manage VPS, MetaTrader, and
service configurations. Configuration is organized into three logical files plus
a combined option:

1. **`.env.vps.example`** - VPS provider, network, and hardware configuration
2. **`.env.mt5.example`** - MetaTrader 5 and Expert Advisor configuration
3. **`.env.secrets.example`** - Services, integrations, and sensitive
credentials
4. **`.env.example`** - Combined file containing all configurations

## Quick Start

### Option 1: Separate Configuration Files (Recommended)

For better organization and security:

```bash

# Copy example files and fill in your values

cp .env.vps.example .env.vps
cp .env.mt5.example .env.mt5
cp .env.secrets.example .env.secrets

# Edit each file with your actual values

nano .env.vps      # or your preferred editor
nano .env.mt5
nano .env.secrets

```bash

### Option 2: Single Combined File

For simpler setup:

```bash

# Copy the combined example file

cp .env.example .env

# Edit with your actual values

nano .env

```bash

## Configuration Categories

### 1. VPS Configuration (`.env.vps.example`)

#### VPS Provider Settings

- **VPS_PROVIDER**: VPS hosting provider (e.g., EXNESS)
- **VPS_SERVICE**: Service type (e.g., MetaTrader_VPS)
- **VPS_REGION**: Primary data center region
- **VPS_NODE**: Specific VPS node identifier
- **VPS_TARIFF**: Tariff plan number
- **VPS_EXECUTION_LATENCY_MS**: Average execution latency
- **VPS_BACKUP_REGION**: Backup data center region
- **VPS_BACKUP_NODE**: Backup VPS node

#### Account Identity

- **TERMINAL_NAME**: Trading terminal name
- **OWNER_NAME**: Account owner name
- **MQL5_PROFILE**: MQL5 community profile name
- **MQL5_INTERNAL_USER**: Internal MQL5 user identifier

#### Billing Information (Reference Only)

- **VPS_PAYMENT_DATE**: Last payment date (YYYY-MM-DD)
- **VPS_PAYMENT_AMOUNT**: Payment amount
- **VPS_PAYMENT_CURRENCY**: Payment currency
- **VPS_PAYMENT_ID**: Payment transaction ID

#### Network Configuration

- **CLIENT_PUBLIC_IP**: Public IP address
- **LAN_IPV4**: Local IPv4 address
- **LAN_GATEWAY**: Default gateway
- **DNS_PRIMARY**: Primary DNS server
- **DNS_SECONDARY**: Secondary DNS server
- **DNS_IPV6_PRIMARY**: Primary IPv6 DNS
- **DNS_IPV6_SECONDARY**: Secondary IPv6 DNS

#### Hardware Information

- **GPU**: Graphics processor model
- **OPENCL_VERSION**: OpenCL version
- **CPU_ARCH**: CPU architecture (X64/X86)
- **NETWORK_ADAPTER**: Network adapter model
- **WIFI_PROTOCOL**: Wi-Fi protocol version
- **WIFI_BAND**: Wi-Fi frequency band

### 2. MetaTrader Configuration (`.env.mt5.example`)

#### MetaTrader 5 Settings

- **MT5_BUILD**: MetaTrader 5 build number
- **MT5_PATH**: Installation path (use %APPDATA% for Windows)

#### Expert Advisor

- **EA_NAME**: Expert Advisor name
- **EA_STATUS**: Compilation status
- **EA_ERRORS**: Number of compilation errors
- **EA_WARNINGS**: Number of compilation warnings

#### TLS/Security

- **TLS_PROVIDER**: TLS certificate provider
- **TLS_CERT_DOMAIN**: Certificate domain
- **TLS_VALID_UNTIL**: Certificate expiration date
- **TLS_KEY_SIZE**: Key size in bits
- **TLS_HASH**: Hash algorithm

### 3. Services & Integrations (`.env.secrets.example`)

⚠️ **CRITICAL**: This file contains sensitive credentials. Never commit to
version control!

#### Docker Hub

- **DOCKER_TOKEN**: Docker Hub personal access token
  - Get from: https://hub.docker.com/settings/security

#### GitHub

- **GITHUB_TOKEN**: GitHub personal access token
  - Get from: https://github.com/settings/tokens
  - Required scopes: `repo`, `read:packages`

#### Firebase

- **FIREBASE_PROJECT**: Firebase project ID
- **FIREBASE_SERVICE_ACCOUNT**: Service account email

#### Storage & Repositories

- **GOOGLE_DRIVE_ROOT**: Root folder name in Google Drive
- **GOOGLE_DRIVE_URL**: Shared folder URL
- **DROPBOX_URL**: Dropbox shared link
- **MQL5_REPO**: MQL5 repository URL
- **REPLIT_PROJECT**: Replit project name

## Security Best Practices

### 1. Never Commit Actual Credentials

```bash

# ✅ These files are safe to commit (examples with placeholders)

.env.example
.env.vps.example
.env.mt5.example
.env.secrets.example

# ❌ These files should NEVER be committed (contain real values)

.env
.env.vps
.env.mt5
.env.secrets

```bash

The `.gitignore` file is already configured to exclude actual `.env*` files.

### 2. Secure Storage

- Store actual credentials in a password manager (e.g., 1Password, Bitwarden)
- Use environment-specific credentials (dev, staging, production)
- Rotate credentials regularly
- Limit access based on principle of least privilege

### 3. Docker Secrets

For Docker deployments, use Docker secrets instead of environment variables:

```bash

# Create a secret

echo "your_token_here" | docker secret create github_token -

# Use in docker-compose.yml

services:
  app:
    secrets:

      - github_token

```bash

### 4. VPS Deployment

When deploying to VPS:

```bash

# Copy example file

cp .env.example .env

# Edit with production values (use nano, vim, or secure file transfer)

nano .env

# Set restrictive permissions

chmod 600 .env

```bash

## Usage in Applications

### Python

```python
import os
from dotenv import load_dotenv

# Load from specific file

load_dotenv('.env.vps')
load_dotenv('.env.mt5')
load_dotenv('.env.secrets')

# Or load from single .env file

load_dotenv()

# Access variables

vps_provider = os.getenv('VPS_PROVIDER')
mt5_build = os.getenv('MT5_BUILD')
github_token = os.getenv('GITHUB_TOKEN')

```bash

### Docker

```dockerfile

# In Dockerfile

ENV VPS_PROVIDER=${VPS_PROVIDER}
ENV MT5_BUILD=${MT5_BUILD}

```bash

```yaml

# In docker-compose.yml

services:
  app:
    env_file:

      - .env.vps
      - .env.mt5
      - .env.secrets

    # Or single file


    # env_file: .env

```bash

### Shell Scripts

```bash

# Load environment variables

source .env.vps
source .env.mt5
source .env.secrets

# Or from single file

source .env

# Use variables

echo "VPS: $VPS_PROVIDER at $VPS_REGION"
echo "MT5 Build: $MT5_BUILD"

```bash

## Validation

NUNA includes a validation script to check your configuration:

```bash

# Validate your configuration

python validate_env.py

```bash

The script will:

- ✅ Check if all required variables are present
- ⚠️ Warn about placeholder values that need to be replaced
- ❌ Report missing configuration files

**Example output:**

```bash
Detected: Combined configuration file
============================================================
NUNA Environment Configuration Validator
============================================================

✓ Found .env file

------------------------------------------------------------
✅ All required variables are present

⚠️  Warning: Found placeholder values that should be replaced:
  ⚠️  DOCKER_TOKEN contains placeholder value: dckr_pat_YOUR_TOKEN_HERE
  ⚠️  GITHUB_TOKEN contains placeholder value: ghp_YOUR_TOKEN_HERE

------------------------------------------------------------
⚠️  Configuration validation passed with warnings
   Please replace placeholder values with actual credentials.

```bash

### Manual Validation

You can also validate manually:

```bash

# Check if required variables are set

python -c "
import os
from dotenv import load_dotenv

load_dotenv('.env.vps')
load_dotenv('.env.mt5')
load_dotenv('.env.secrets')

required = ['VPS_PROVIDER', 'MT5_BUILD', 'GITHUB_TOKEN']
missing = [var for var in required if not os.getenv(var)]

if missing:
    print(f'Missing variables: {missing}')
else:
    print('All required variables are set!')
"

```bash

## Troubleshooting

### Issue: Variables not loading

**Solution**: Ensure you're loading the correct file and path:

```python

# Use absolute path

load_dotenv('/absolute/path/to/.env')

# Or relative to script location

from pathlib import Path
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path)

```bash

### Issue: Variables overwriting each other

**Solution**: Load in correct order (most specific last):

```python
load_dotenv('.env')           # Base
load_dotenv('.env.vps')       # Override with VPS-specific
load_dotenv('.env.secrets')   # Override with secrets

```bash

### Issue: Permission denied on VPS

**Solution**: Set correct file permissions:

```bash
chmod 600 .env*
chown $(whoami):$(whoami) .env*

```bash

## Integration Examples

### With Trading Data Manager

```python

# trading_data_manager.py

from dotenv import load_dotenv
import os

load_dotenv('.env.vps')
load_dotenv('.env.mt5')

# Use VPS-aware paths

mt5_path = os.getenv('MT5_PATH')
terminal_name = os.getenv('TERMINAL_NAME')

```bash

### With Google Drive Cleanup

```python

# gdrive_cleanup.py

from dotenv import load_dotenv
import os

load_dotenv('.env.secrets')

# Use credentials safely

drive_root = os.getenv('GOOGLE_DRIVE_ROOT')

```bash

### With Docker Deployment

```yaml

# docker-compose.yml

version: '3.8'

services:
  nuna:
    image: ghcr.io/a6-9v/nuna:main
    env_file:

      - .env.vps
      - .env.mt5
      - .env.secrets
    environment:

      - TERMINAL_NAME=${TERMINAL_NAME}
      - MT5_BUILD=${MT5_BUILD}
    volumes:

      - ./data:/data

```bash

## Migration from Old Configuration

If you have existing configuration files:

```bash

# Backup existing config

cp old_config.ini old_config.ini.backup

# Extract and map to new .env format


# (Manual process - review each value)

# Test new configuration

python trading_data_manager.py --dry-run

```bash

## References

- [12-Factor App Environment Variables](https://12factor.net/config)
- [Docker Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Python dotenv Documentation](https://pypi.org/project/python-dotenv/)
- [VPS_HOSTING.md](VPS_HOSTING.md) - VPS-specific configuration
- [README.md](README.md) - General project documentation

## Support

For issues or questions about environment configuration:

1. Check this guide first
2. Review the example files
3. Verify `.gitignore` is protecting your secrets
4. Open an issue on GitHub (never include actual credentials in issues!)

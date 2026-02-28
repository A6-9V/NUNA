# VPS Deployment Guide

This guide provides instructions for deploying NUNA to a VPS (Virtual Private
Server).

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Methods](#deployment-methods)
  - [Automated Deployment (GitHub Actions)](#automated-deployment-github-actions)
  - [Manual Deployment](#manual-deployment)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## Overview

NUNA can be deployed to a VPS for continuous operation. The deployment uses
Docker containers to ensure consistency and ease of management.

### Supported VPS Providers

- Any Linux VPS with Docker support
- MetaTrader VPS (with Docker installation)
- AWS EC2, DigitalOcean, Linode, Vultr, etc.

---

## Prerequisites

### VPS Requirements

- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **RAM**: Minimum 2GB, 4GB+ recommended
- **Storage**: Minimum 20GB
- **Docker**: Version 20.10+ (will be installed automatically if not present)
- **SSH Access**: SSH key-based authentication configured

### Local Requirements

- SSH client
- Git (for cloning repository)
- Docker (optional, for local testing)

---

## Deployment Methods

### Automated Deployment (GitHub Actions)

Automated deployment is triggered on every push to the `main` branch.

#### Setup Steps

1. **Generate SSH Key Pair** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "nuna-vps-deployment" -f ~/.ssh/nuna_vps
   ```

2. **Add Public Key to VPS**:
   ```bash
   ssh-copy-id -i ~/.ssh/nuna_vps.pub user@your-vps-host
   ```

3. **Configure GitHub Secrets**:
   
   Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository
secret`

   Add the following secrets:
   
   | Secret Name | Description | Example |
   |-------------|-------------|---------|
   | `VPS_HOST` | VPS hostname or IP address | `203.147.134.90` or `vps.example.com` |
   | `VPS_USER` | SSH username | `root` or `ubuntu` |
   | `VPS_SSH_KEY` | Private SSH key content | Contents of `~/.ssh/nuna_vps` |
   | `VPS_DEPLOY_PATH` | Deployment directory on VPS (optional) | `/opt/nuna` (default) |

4. **Enable Automated Deployment**:
   
   Go to: `Settings` → `Secrets and variables` → `Actions` → `Variables`
   
   Add a new variable:

   - **Name**: `VPS_DEPLOYMENT_ENABLED`
   - **Value**: `true`

5. **Trigger Deployment**:
   
   Push to the `main` branch or manually trigger the workflow:
   ```bash
   git push origin main
   ```

#### Deployment Workflow

The automated deployment performs the following steps:

1. ✅ Builds Docker image and pushes to GitHub Container Registry
2. ✅ Connects to VPS via SSH
3. ✅ Creates deployment directory
4. ✅ Copies configuration files
5. ✅ Installs Docker and Docker Compose (if needed)
6. ✅ Pulls latest Docker image
7. ✅ Stops existing containers
8. ✅ Starts new containers
9. ✅ Verifies deployment

---

### Manual Deployment

If you prefer manual control or don't have GitHub Actions access, you can deploy
manually.

#### Option 1: Using the Deployment Script

1. **Clone the repository on your local machine**:
   ```bash
   git clone https://github.com/A6-9V/NUNA.git
   cd NUNA
   ```

2. **Set environment variables**:
   ```bash
   export VPS_HOST="your-vps-ip"
   export VPS_USER="your-username"
   export VPS_DEPLOY_PATH="/opt/nuna"
   export DOCKER_IMAGE="ghcr.io/a6-9v/nuna:main"
   export COMPOSE_FILE="docker-compose.vps.yml"
   ```

3. **Run the deployment script**:
   ```bash
   chmod +x scripts/deploy-vps.sh
   ./scripts/deploy-vps.sh
   ```

#### Option 2: Direct VPS Deployment

1. **SSH into your VPS**:
   ```bash
   ssh user@your-vps-host
   ```

2. **Create deployment directory**:
   ```bash
   sudo mkdir -p /opt/nuna
   cd /opt/nuna
   ```

3. **Install Docker** (if not already installed):
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

4. **Install Docker Compose** (if not already installed):
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

5. **Download configuration files**:
   ```bash

   # Download docker-compose file

   curl -o docker-compose.yml https://raw.githubusercontent.com/A6-9V/NUNA/main/docker-compose.vps.yml

   # Download example environment file

   curl -o .env https://raw.githubusercontent.com/A6-9V/NUNA/main/.env.vps.example
   ```

6. **Edit environment file**:
   ```bash
   nano .env
   ```
   
   Configure your settings based on the example file.

7. **Pull Docker image and start services**:
   ```bash
   docker pull ghcr.io/a6-9v/nuna:main
   docker-compose up -d
   ```

8. **Verify deployment**:
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

---

## Configuration

### Environment Variables

Create a `.env` file on your VPS with the following variables:

```bash

# VPS Configuration

VPS_PROVIDER=YOUR_PROVIDER
VPS_REGION=YOUR_REGION
TZ=UTC

# Database Configuration (optional)

POSTGRES_DB=nuna_trading
POSTGRES_USER=nuna_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_PORT=5432

# Redis Configuration (optional)

REDIS_PORT=6379

# Logging

LOG_LEVEL=INFO

```bash

### Docker Compose Configuration

The `docker-compose.vps.yml` file is optimized for VPS deployment and includes:

- **nuna-tools**: Main application container
- **postgres**: PostgreSQL database (optional)
- **redis**: Redis cache (optional)

To use a custom compose file:

```bash
docker-compose -f docker-compose.vps.yml up -d

```bash

---

## Monitoring

### Check Container Status

```bash
docker-compose ps

```bash

### View Logs

```bash

# All containers

docker-compose logs -f

# Specific container

docker-compose logs -f nuna-tools

```bash

### Resource Usage

```bash

# Container stats

docker stats

# Disk usage

docker system df

```bash

### Health Checks

```bash

# Check if containers are healthy

docker-compose ps

# Detailed inspection

docker inspect nuna-tools

```bash

---

## Management Commands

### Start Services

```bash
docker-compose up -d

```bash

### Stop Services

```bash
docker-compose down

```bash

### Restart Services

```bash
docker-compose restart

```bash

### Update to Latest Version

```bash

# Pull latest image

docker pull ghcr.io/a6-9v/nuna:main

# Recreate containers with new image

docker-compose up -d --force-recreate

```bash

### Remove Everything (including volumes)

```bash
docker-compose down -v

```bash

---

## Troubleshooting

### Container Won't Start

1. **Check logs**:
   ```bash
   docker-compose logs nuna-tools
   ```

2. **Verify environment variables**:
   ```bash
   docker-compose config
   ```

3. **Check available resources**:
   ```bash
   free -h
   df -h
   ```

### Port Conflicts

If you get port conflict errors:

1. **Check what's using the port**:
   ```bash
   sudo netstat -tulpn | grep :5432
   ```

2. **Change port in .env file**:
   ```bash
   POSTGRES_PORT=5433
   ```

3. **Restart services**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### SSH Connection Issues

1. **Test SSH connection**:
   ```bash
   ssh -v user@your-vps-host
   ```

2. **Verify SSH key permissions**:
   ```bash
   chmod 600 ~/.ssh/nuna_vps
   ```

3. **Check SSH agent**:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/nuna_vps
   ```

### Deployment Script Fails

1. **Run with verbose output**:
   ```bash
   bash -x scripts/deploy-vps.sh
   ```

2. **Check environment variables**:
   ```bash
   echo $VPS_HOST
   echo $VPS_USER
   ```

3. **Test SSH connection manually**:
   ```bash
   ssh $VPS_USER@$VPS_HOST "echo 'Connection successful'"
   ```

### Docker Permission Denied

If you get permission errors:

```bash

# Add user to docker group

sudo usermod -aG docker $USER

# Log out and log back in, or run:

newgrp docker

# Test docker without sudo

docker ps

```bash

---

## Security Best Practices

1. **Use SSH Key Authentication**: Never use password-based SSH authentication
2. **Firewall Configuration**: Only open necessary ports
   ```bash
   sudo ufw allow 22/tcp  # SSH
   sudo ufw enable
   ```
3. **Regular Updates**: Keep your system and Docker updated
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
4. **Secure Secrets**: Use strong passwords for databases
5. **Monitor Logs**: Regularly check logs for suspicious activity
6. **Backup Data**: Backup your data volumes regularly

---

## Backup and Restore

### Backup

```bash

# Backup volumes

docker-compose down
sudo tar -czf /backup/nuna-data-$(date +%Y%m%d).tar.gz /var/lib/docker/volumes/

# Backup configuration

tar -czf /backup/nuna-config-$(date +%Y%m%d).tar.gz /opt/nuna/.env /opt/nuna/docker-compose.yml

```bash

### Restore

```bash

# Restore volumes

sudo tar -xzf /backup/nuna-data-20260205.tar.gz -C /

# Restore configuration

tar -xzf /backup/nuna-config-20260205.tar.gz -C /opt/nuna/

# Start services

docker-compose up -d

```bash

---

## Next Steps

1. ✅ Complete VPS setup
2. ✅ Configure automated deployment
3. ✅ Monitor logs and metrics
4. 📊 Set up Grafana dashboards (optional)
5. 🔔 Configure alerts for system health

---

## Support

For issues or questions:

- **GitHub Issues**: [A6-9V/NUNA Issues](https://github.com/A6-9V/NUNA/issues)
- **Documentation**: [VPS_HOSTING.md](VPS_HOSTING.md)
- **CI/CD Documentation**: [CI_CD_DOCUMENTATION.md](CI_CD_DOCUMENTATION.md)

---

**Last Updated**: 2026-02-05

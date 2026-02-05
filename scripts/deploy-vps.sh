#!/bin/bash
# VPS Deployment Script for NUNA
# This script automates deployment to VPS servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}NUNA VPS Deployment Script${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if required environment variables are set
if [ -z "$VPS_HOST" ]; then
    echo -e "${RED}Error: VPS_HOST environment variable is not set${NC}"
    exit 1
fi

if [ -z "$VPS_USER" ]; then
    echo -e "${RED}Error: VPS_USER environment variable is not set${NC}"
    exit 1
fi

if [ -z "$VPS_DEPLOY_PATH" ]; then
    echo -e "${YELLOW}Warning: VPS_DEPLOY_PATH not set, using default: /opt/nuna${NC}"
    VPS_DEPLOY_PATH="/opt/nuna"
fi

# Set default values
DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/a6-9v/nuna:main}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

echo -e "${GREEN}Deployment Configuration:${NC}"
echo "  VPS Host: $VPS_HOST"
echo "  VPS User: $VPS_USER"
echo "  Deploy Path: $VPS_DEPLOY_PATH"
echo "  Docker Image: $DOCKER_IMAGE"
echo "  Compose File: $COMPOSE_FILE"
echo ""

# Function to execute commands on VPS
execute_remote() {
    ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "$@"
}

# Function to copy files to VPS
copy_to_vps() {
    scp -o StrictHostKeyChecking=no "$1" "$VPS_USER@$VPS_HOST:$2"
}

echo -e "${GREEN}Step 1: Checking VPS connection...${NC}"
if execute_remote "echo 'Connection successful'"; then
    echo -e "${GREEN}✓ VPS connection established${NC}"
else
    echo -e "${RED}✗ Failed to connect to VPS${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Step 2: Creating deployment directory...${NC}"
execute_remote "sudo mkdir -p $VPS_DEPLOY_PATH"
execute_remote "sudo chown -R $VPS_USER:$VPS_USER $VPS_DEPLOY_PATH"
echo -e "${GREEN}✓ Deployment directory ready${NC}"

echo ""
echo -e "${GREEN}Step 3: Copying deployment files...${NC}"
# Copy docker-compose file
if [ -f "$COMPOSE_FILE" ]; then
    copy_to_vps "$COMPOSE_FILE" "$VPS_DEPLOY_PATH/"
    echo -e "${GREEN}✓ Docker compose file copied${NC}"
fi

# Copy .env file if it exists
if [ -f ".env" ]; then
    copy_to_vps ".env" "$VPS_DEPLOY_PATH/"
    echo -e "${GREEN}✓ Environment file copied${NC}"
elif [ -f ".env.vps.example" ]; then
    echo -e "${YELLOW}! No .env file found, copying .env.vps.example${NC}"
    copy_to_vps ".env.vps.example" "$VPS_DEPLOY_PATH/.env"
fi

# Copy config directory if it exists
if [ -d "config" ]; then
    execute_remote "mkdir -p $VPS_DEPLOY_PATH/config"
    scp -r -o StrictHostKeyChecking=no config/* "$VPS_USER@$VPS_HOST:$VPS_DEPLOY_PATH/config/"
    echo -e "${GREEN}✓ Configuration files copied${NC}"
fi

echo ""
echo -e "${GREEN}Step 4: Installing Docker (if needed)...${NC}"
if execute_remote "command -v docker &> /dev/null"; then
    echo -e "${GREEN}✓ Docker already installed${NC}"
else
    echo -e "${YELLOW}Installing Docker...${NC}"
    execute_remote "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    execute_remote "sudo usermod -aG docker $VPS_USER"
    echo -e "${GREEN}✓ Docker installed${NC}"
fi

echo ""
echo -e "${GREEN}Step 5: Installing Docker Compose (if needed)...${NC}"
if execute_remote "command -v docker-compose &> /dev/null || docker compose version &> /dev/null"; then
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
else
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    execute_remote "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    execute_remote "sudo chmod +x /usr/local/bin/docker-compose"
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
fi

echo ""
echo -e "${GREEN}Step 6: Pulling latest Docker image...${NC}"
execute_remote "cd $VPS_DEPLOY_PATH && docker pull $DOCKER_IMAGE"
echo -e "${GREEN}✓ Docker image pulled${NC}"

echo ""
echo -e "${GREEN}Step 7: Stopping existing containers...${NC}"
execute_remote "cd $VPS_DEPLOY_PATH && (docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true)"
echo -e "${GREEN}✓ Existing containers stopped${NC}"

echo ""
echo -e "${GREEN}Step 8: Starting new containers...${NC}"
execute_remote "cd $VPS_DEPLOY_PATH && (docker-compose up -d || docker compose up -d)"
echo -e "${GREEN}✓ Containers started${NC}"

echo ""
echo -e "${GREEN}Step 9: Checking container status...${NC}"
execute_remote "cd $VPS_DEPLOY_PATH && (docker-compose ps || docker compose ps)"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${GREEN}To view logs, run:${NC}"
echo "  ssh $VPS_USER@$VPS_HOST 'cd $VPS_DEPLOY_PATH && docker-compose logs -f'"
echo ""
echo -e "${GREEN}To check status, run:${NC}"
echo "  ssh $VPS_USER@$VPS_HOST 'cd $VPS_DEPLOY_PATH && docker-compose ps'"

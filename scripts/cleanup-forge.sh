#!/bin/bash
# ================================================================
# Cleanup Script: Reset forge.mql5.io to Clean State
# ================================================================
# This script resets the forge.mql5.io repository to a clean state
# by force-pushing the current main branch.
#
# Usage:
#   ./scripts/cleanup-forge.sh [--force]
#
# WARNING: This will overwrite the forge.mql5.io repository history!
# ================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}═══════════════════════════════════════════════════${NC}"
echo -e "${RED}     NUNA - Forge MQL5 Cleanup Script${NC}"
echo -e "${RED}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will reset forge.mql5.io to a clean state!${NC}"
echo -e "${YELLOW}⚠️  All history on forge will be overwritten with the current state.${NC}"
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Confirm unless --force flag is provided
if [ "$1" != "--force" ]; then
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${BLUE}Cleanup cancelled.${NC}"
        exit 0
    fi
fi

# Check if forge remote exists
if ! git remote | grep -q "^forge$"; then
    echo -e "${YELLOW}⚠️  Forge remote not found. Adding it now...${NC}"
    git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git
    echo -e "${GREEN}✓ Forge remote added${NC}"
fi

echo ""
echo -e "${BLUE}Starting cleanup process...${NC}"
echo ""

# Step 1: Verify we're on a clean state
echo -e "${YELLOW}→ Step 1: Checking repository state...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}✗ Repository has uncommitted changes${NC}"
    echo -e "${YELLOW}  Please commit or stash your changes first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Repository is clean${NC}"

# Step 2: Fetch latest from origin
echo -e "${YELLOW}→ Step 2: Fetching latest from GitHub...${NC}"
if git fetch origin; then
    echo -e "${GREEN}✓ Fetched successfully${NC}"
else
    echo -e "${RED}✗ Failed to fetch from GitHub${NC}"
    exit 1
fi

# Step 3: Ensure we're on main branch
echo -e "${YELLOW}→ Step 3: Switching to main branch...${NC}"
if git checkout main; then
    echo -e "${GREEN}✓ On main branch${NC}"
else
    echo -e "${RED}✗ Failed to checkout main branch${NC}"
    exit 1
fi

# Step 4: Pull latest from origin
echo -e "${YELLOW}→ Step 4: Pulling latest changes...${NC}"
if git pull origin main; then
    echo -e "${GREEN}✓ Updated to latest version${NC}"
else
    echo -e "${RED}✗ Failed to pull latest changes${NC}"
    exit 1
fi

# Step 5: Force push to forge (clean state)
echo -e "${YELLOW}→ Step 5: Force pushing to forge.mql5.io...${NC}"
echo -e "${RED}   This will overwrite the forge repository!${NC}"
if git push forge main --force; then
    echo -e "${GREEN}✓ Successfully reset forge to clean state${NC}"
else
    echo -e "${RED}✗ Failed to push to forge${NC}"
    exit 1
fi

# Step 6: Push all branches (optional)
echo ""
read -p "Do you want to push all other branches as well? (yes/no): " -r
echo
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}→ Pushing all branches...${NC}"
    if git push forge --all --force; then
        echo -e "${GREEN}✓ All branches pushed${NC}"
    else
        echo -e "${YELLOW}⚠️  Some branches failed to push${NC}"
    fi
    
    echo -e "${YELLOW}→ Pushing all tags...${NC}"
    if git push forge --tags --force; then
        echo -e "${GREEN}✓ All tags pushed${NC}"
    else
        echo -e "${YELLOW}⚠️  Some tags failed to push${NC}"
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Forge cleanup completed successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "The forge.mql5.io repository has been reset to match GitHub."
echo ""
echo -e "Repository URLs:"
echo -e "  GitHub:     ${BLUE}https://github.com/A6-9V/NUNA${NC}"
echo -e "  Forge MQL5: ${BLUE}https://forge.mql5.io/LengKundee/NUNA${NC}"
echo ""

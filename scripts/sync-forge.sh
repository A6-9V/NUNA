#!/bin/bash
# ================================================================
# Sync Script: Push to forge.mql5.io
# ================================================================
# This script synchronizes the local repository with forge.mql5.io
# 
# Usage:
#   ./scripts/sync-forge.sh [branch]
#   
# Examples:
#   ./scripts/sync-forge.sh           # Sync current branch
#   ./scripts/sync-forge.sh main      # Sync main branch
#   ./scripts/sync-forge.sh --all     # Sync all branches
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

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     NUNA - Forge MQL5 Sync Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Check if forge remote exists
if ! git remote | grep -q "^forge$"; then
    echo -e "${YELLOW}⚠️  Forge remote not found. Adding it now...${NC}"
    git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git
    echo -e "${GREEN}✓ Forge remote added${NC}"
fi

# Get current branch if no argument provided
BRANCH="${1:-$(git branch --show-current)}"

if [ "$BRANCH" = "--all" ]; then
    echo -e "${BLUE}Syncing all branches to forge...${NC}"
    echo ""
    
    # Push all branches
    echo -e "${YELLOW}→ Pushing all branches...${NC}"
    if git push forge --all; then
        echo -e "${GREEN}✓ All branches pushed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to push all branches${NC}"
        exit 1
    fi
    
    # Push all tags
    echo -e "${YELLOW}→ Pushing all tags...${NC}"
    if git push forge --tags; then
        echo -e "${GREEN}✓ All tags pushed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to push tags${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}Syncing branch: ${YELLOW}$BRANCH${NC}"
    echo ""
    
    # Fetch latest from forge
    echo -e "${YELLOW}→ Fetching latest from forge...${NC}"
    if git fetch forge; then
        echo -e "${GREEN}✓ Fetched successfully${NC}"
    else
        echo -e "${RED}✗ Fetch failed${NC}"
        exit 1
    fi
    
    # Push to forge
    echo -e "${YELLOW}→ Pushing to forge...${NC}"
    if git push forge "$BRANCH"; then
        echo -e "${GREEN}✓ Pushed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Push failed. You may need to force push.${NC}"
        echo -e "${YELLOW}   Run: git push forge $BRANCH --force${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Sync completed successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "Repository URLs:"
echo -e "  GitHub:     ${BLUE}https://github.com/A6-9V/NUNA${NC}"
echo -e "  Forge MQL5: ${BLUE}https://forge.mql5.io/LengKundee/NUNA${NC}"
echo ""

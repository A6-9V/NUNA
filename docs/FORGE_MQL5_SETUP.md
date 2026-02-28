# Forge MQL5 Setup Guide

This guide explains how to set up and maintain the integration between GitHub
(A6-9V/NUNA) and forge.mql5.io (LengKundee/NUNA).

## Overview

The NUNA project is synchronized between two repositories:

- **GitHub**: https://github.com/A6-9V/NUNA (Primary repository)
- **Forge MQL5**: https://forge.mql5.io/LengKundee/NUNA.git (MQL5 community integration)

## Prerequisites

- Git installed on your system
- Access to the NUNA repository
- forge.mql5.io account credentials (token authentication)

## Initial Setup

### 1. Add Forge Remote

The forge.mql5.io remote has already been configured with the following command:

```bash
git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git

```bash

### 2. Verify Remote Configuration

Check that both remotes are configured:

```bash
git remote -v

```bash

Expected output:

```bash
forge   https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git (fetch)
forge   https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git (push)
origin  https://github.com/A6-9V/NUNA (fetch)
origin  https://github.com/A6-9V/NUNA (push)

```bash

## Authentication

### Token-Based Authentication

The forge.mql5.io repository uses token-based authentication. The token is
embedded in the remote URL:

- **Token**: `PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW`
- **Repository**: `forge.mql5.io/LengKundee/NUNA.git`

**Security Note**: The token is stored in the Git configuration. Keep your `.git/config` file secure and never commit it to the repository.

## Syncing Code

### Push to Forge

To push your changes to forge.mql5.io:

```bash

# Push the main branch
git push forge main

# Push all branches
git push forge --all

# Push with tags
git push forge --tags

```bash

### Push to Both Remotes

To push to both GitHub and forge.mql5.io simultaneously:

```bash

# Push to origin (GitHub)
git push origin main

# Push to forge (MQL5)
git push forge main

```bash

Or use the convenience script:

```bash
./scripts/sync-forge.sh

```bash

### Pull from Forge

To fetch updates from forge.mql5.io:

```bash

# Fetch updates
git fetch forge

# Merge changes from forge
git merge forge/main

# Or pull directly
git pull forge main

```bash

## Clean State Reset

If you need to reset forge.mql5.io to a clean state:

### Option 1: Force Push (Clean Slate)

```bash

# Force push the current main branch to forge
git push forge main --force

# Or push all branches with force
git push forge --all --force

```bash

### Option 2: Delete and Re-create Remote

```bash

# Remove the forge remote
git remote remove forge

# Re-add the forge remote
git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git

# Push to re-populate
git push forge main

```bash

### Option 3: Use Cleanup Script

```bash

# Run the forge cleanup script
./scripts/cleanup-forge.sh

```bash

## Branch Management

### Syncing Specific Branches

```bash

# Push a specific branch
git push forge feature-branch

# Delete a remote branch
git push forge --delete old-branch

# Rename a branch on forge
git push forge new-branch-name
git push forge --delete old-branch-name

```bash

## MQL5 Deployment Package

The MQL5-specific files are located in:

```bash
MQL5_Deployment_Package/
└── Experts/
    └── NunaEA.mq5

```bash

These files are automatically synced to forge.mql5.io and are accessible to the
MQL5 community.

## Troubleshooting

### Authentication Errors

If you encounter authentication errors:

1. Verify the token is correct in the remote URL:

```bash
git remote get-url forge
```

2. Update the token if needed:

```bash
git remote set-url forge https://NEW_TOKEN@forge.mql5.io/LengKundee/NUNA.git
```

### Push Rejected

If your push is rejected:

```bash

# Fetch and merge first
git fetch forge
git merge forge/main

# Or rebase
git pull forge main --rebase

# Then push
git push forge main

```bash

### Connection Issues

If you can't connect to forge.mql5.io:

1. Check your internet connection
2. Verify the forge.mql5.io service is available
3. Try using SSH instead of HTTPS (if supported)

## Best Practices

### 1. Always Test Locally First

Before pushing to forge.mql5.io:

- Test your code locally
- Run all tests
- Verify MQL5 Expert Advisors compile correctly

### 2. Keep Remotes in Sync

Regularly sync between GitHub and forge:

```bash

# Pull from GitHub
git pull origin main

# Push to forge
git push forge main

```bash

### 3. Use Descriptive Commit Messages

Both GitHub and forge.mql5.io communities benefit from clear commit messages:

```bash
git commit -m "feat: Add new trading strategy indicator"
git commit -m "fix: Resolve order execution timing issue"
git commit -m "docs: Update strategy parameters documentation"

```bash

### 4. Tag Releases

Use semantic versioning for releases:

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
git push forge v1.0.0

```bash

## Automated Sync (CI/CD)

Consider setting up automated syncing using GitHub Actions:

```yaml
name: Sync to Forge MQL5

on:
  push:
    branches: [ main ]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:

      - uses: actions/checkout@v3
      - name: Sync to forge
        run: |
          git remote add forge https://${{ secrets.FORGE_TOKEN }}@forge.mql5.io/LengKundee/NUNA.git
          git push forge main

```bash

## Resources

- **forge.mql5.io Documentation**: https://forge.mql5.io/docs
- **MQL5 Community**: https://www.mql5.com/
- **Git Documentation**: https://git-scm.com/doc

## Support

For issues related to:

- **GitHub repository**: Open an issue at https://github.com/A6-9V/NUNA/issues
- **forge.mql5.io**: Contact MQL5 support
- **Token issues**: Contact repository administrator (LengKundee)

---

**Last Updated**: 2026-02-05
**Repository**: A6-9V/NUNA
**Forge Repository**: LengKundee/NUNA

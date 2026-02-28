# GitHub Token Configuration Guide

## Overview

This guide documents the GitHub Personal Access Token (PAT) configuration for the NUNA project.

## Token Information

- **Token**: `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` *(Updated 2026-02-05)*
- **Purpose**: Repository access, CI/CD workflows, secrets management
- **Type**: Personal Access Token (classic)

⚠️ **Security Note**: This token is documented here for initial setup. In production:

- Store in environment variables
- Use GitHub Secrets for CI/CD
- Never hardcode in source code
- Rotate every 90 days

## Token Permissions

Ensure the token has the following scopes:

### Required Scopes

- ✅ **repo** - Full control of private repositories
  - repo:status
  - repo_deployment
  - public_repo
  - repo:invite
  - security_events

- ✅ **workflow** - Update GitHub Action workflows

- ✅ **write:packages** - Upload packages to GitHub Package Registry
  - read:packages

- ✅ **admin:org** - Full control of orgs and teams (if using organization)
  - read:org

### Optional Scopes

- **admin:repo_hook** - Full control of repository hooks
- **notifications** - Access notifications
- **delete_repo** - Delete repositories (use with caution)

## Configuration Files

The GitHub token is configured in the following files:

1. **`.env.example`** - Example environment configuration
2. **`.env.secrets.example`** - Secrets template file
3. **`.env`** - Actual environment file (not committed)

## Usage

### Environment Variable

Set the token as an environment variable:

```bash
export GITHUB_TOKEN=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

```bash

### In .env File

Add to your `.env` file:

```env
GITHUB_TOKEN=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

```bash

### In Python Scripts

```python
import os

github_token = os.getenv('GITHUB_TOKEN')

# Use with GitHub API
import requests

headers = {
    'Authorization': f'token {github_token}',
    'Accept': 'application/vnd.github.v3+json'
}

response = requests.get('https://api.github.com/user', headers=headers)

```bash

### In GitHub Actions

The token is available as a secret:

```yaml
name: Example Workflow

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:

      - uses: actions/checkout@v3
      
      - name: Use GitHub Token
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh api user

```bash

### With Git Commands

```bash

# Clone repository using token
git clone https://${GITHUB_TOKEN}@github.com/A6-9V/NUNA.git

# Set remote URL with token  
git remote set-url origin https://${GITHUB_TOKEN}@github.com/A6-9V/NUNA.git

# Push with token
git push https://${GITHUB_TOKEN}@github.com/A6-9V/NUNA.git main

```bash

**Example with actual token** (for initial setup only):

```bash
git clone https://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@github.com/A6-9V/NUNA.git

```bash

## GitHub Secrets Setup

### Repository Secrets

To add the token as a repository secret:

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `GITHUB_TOKEN`
4. Value: `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` (use your actual token)
5. Click **Add secret**

### Environment Secrets

For environment-specific secrets:

1. Go to **Settings** → **Environments**
2. Select or create an environment (e.g., `production`, `staging`)
3. Add secret with the token value

### Organization Secrets

For organization-wide access:

1. Go to **Organization Settings** → **Secrets and variables** → **Actions**
2. Click **New organization secret**
3. Configure repository access
4. Add the token

## Security Best Practices

### ⚠️ Important Security Notes

1. **Never Commit Tokens**
   - The actual `.env` file is git-ignored
   - Never commit tokens to version control
   - Rotate tokens if exposed

2. **Limit Token Scope**

   - Use only required permissions
   - Create separate tokens for different purposes
   - Use fine-grained tokens when possible

3. **Token Rotation**

   - Rotate tokens periodically (every 90 days recommended)
   - Update all configurations after rotation
   - Revoke old tokens after successful rotation

4. **Access Control**

   - Limit who has access to tokens
   - Use organization secrets for team access
   - Monitor token usage in audit logs

5. **Environment Variables**

   - Use environment variables, not hardcoded values
   - Use secrets management tools (e.g., Vault, AWS Secrets Manager)
   - Never log token values

## Token Verification

### Verify Token Validity

```bash

# Check token authentication (replace with your token)
curl -H "Authorization: token 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" \
     https://api.github.com/user

# Using GitHub CLI
echo "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" | gh auth login --with-token
gh auth status

```bash

### Check Token Scopes

```bash

# View token scopes (replace with your token)
curl -I -H "Authorization: token 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" \
     https://api.github.com/user | grep -i x-oauth-scopes

```bash

### Test Repository Access

```bash

# Test read access
gh repo view A6-9V/NUNA

# Test write access (dry run)
gh repo edit A6-9V/NUNA --description "Test access"

```bash

## Troubleshooting

### Authentication Failed

**Error**: `remote: Invalid username or password`

**Solutions**:
1. Verify token is correct
2. Check token hasn't expired
3. Verify token has required scopes
4. Regenerate token if compromised

### Permission Denied

**Error**: `Permission denied (publickey)`

**Solutions**:
1. Use HTTPS with token instead of SSH
2. Verify token has `repo` scope
3. Check repository access permissions

### Token Expired

**Error**: `Bad credentials`

**Solutions**:
1. Generate new token
2. Update all configurations
3. Update GitHub secrets
4. Test new token

## Token Management

### Generate New Token

1. Go to: https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. Set expiration (recommend 90 days)
4. Select required scopes
5. Click **Generate token**
6. Copy token immediately (won't be shown again)

### Rotate Token

When rotating the token:

1. **Generate New Token**
   ```bash
   # Store old token as backup
   OLD_TOKEN=$GITHUB_TOKEN
   ```

2. **Update Configurations**
   ```bash
   # Update .env file
   sed -i 's/GITHUB_TOKEN=.*/GITHUB_TOKEN=NEW_TOKEN/' .env
   
   # Update environment variables
   export GITHUB_TOKEN=NEW_TOKEN
   ```

3. **Update GitHub Secrets**

   - Update repository secrets
   - Update environment secrets
   - Update organization secrets

4. **Verify New Token**
   ```bash
   # Test new token
   gh auth status
   git pull
   ```

5. **Revoke Old Token**

   - Go to: https://github.com/settings/tokens
   - Find old token
   - Click **Revoke**

### Monitor Token Usage

Check token usage in GitHub audit log:

1. Go to **Settings** → **Security** → **Audit log**
2. Filter by token activity
3. Review for unauthorized access

## Integration Examples

### CI/CD Pipeline

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:

      - uses: actions/checkout@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Deploy
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          ./scripts/deploy.sh

```bash

### Docker Build

```yaml

- name: Login to GitHub Container Registry
  uses: docker/login-action@v2
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v4
  with:
    push: true
    tags: ghcr.io/a6-9v/nuna:latest

```bash

### Package Release

```yaml

- name: Publish Package
  run: |
    npm config set //npm.pkg.github.com/:_authToken=${{ secrets.GITHUB_TOKEN }}
    npm publish

```bash

## Support

### GitHub Token Issues

- **Documentation**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- **Token Settings**: https://github.com/settings/tokens
- **GitHub Support**: https://support.github.com/

### Repository Issues

- **Issue Tracker**: https://github.com/A6-9V/NUNA/issues
- **Security Issues**: Report privately to repository maintainers

## References

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub API Authentication](https://docs.github.com/en/rest/overview/authenticating-to-the-rest-api)
- [Token Security Best Practices](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation)

---

**Last Updated**: 2026-02-05  
**Token Configured**: 2026-02-05  
**Next Review**: 2026-05-05 (90 days)

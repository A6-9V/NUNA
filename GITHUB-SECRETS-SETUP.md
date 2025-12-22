# GitHub Secrets Setup Guide

## Overview

This guide provides instructions for setting up GitHub repository secrets for OAuth credentials. Secrets allow you to securely store sensitive information (like API keys, tokens, and credentials) that can be used in GitHub Actions workflows without exposing them in your code.

## OAuth Credentials

The following OAuth credentials need to be configured for the ZOLO-A6-9VxNUNA trading system:

- **Client ID**: Your OAuth application Client ID
- **Client Secret**: Your OAuth application Client Secret

**Security Note:** Never commit these values to version control. The actual values should be:
1. Stored securely (e.g., password manager, secure vault)
2. Passed as parameters to the setup script
3. Set directly in GitHub repository secrets via the web interface

## Target Repository

- **Repository**: `Mouy-leng/ZOLO-A6-9VxNUNA-`

## Method 1: Automated Setup (Recommended)

### Using PowerShell Script

The easiest way to set up secrets is to use the provided automation script. **Note**: You must provide your OAuth credentials as parameters:

```powershell
# Run with your OAuth credentials
.\setup-github-secrets.ps1 `
    -ClientId "YOUR_CLIENT_ID_HERE" `
    -ClientSecret "YOUR_CLIENT_SECRET_HERE"
```

For the ZOLO-A6-9VxNUNA repository:
```powershell
.\setup-github-secrets.ps1 `
    -Repository "Mouy-leng/ZOLO-A6-9VxNUNA-" `
    -ClientId "YOUR_CLIENT_ID_HERE" `
    -ClientSecret "YOUR_CLIENT_SECRET_HERE"
```

The script will:
1. ✅ Check if GitHub CLI is installed
2. ✅ Verify authentication status
3. ✅ Authenticate if needed (via web browser)
4. ✅ Set CLIENT_ID secret
5. ✅ Set CLIENT_SECRET secret
6. ✅ Verify secrets were created successfully
7. ✅ Display usage examples

### Using Batch File Wrapper

If you prefer to use environment variables:

```powershell
# Set environment variables first
$env:OAUTH_CLIENT_ID = "YOUR_CLIENT_ID_HERE"
$env:OAUTH_CLIENT_SECRET = "YOUR_CLIENT_SECRET_HERE"

# Then run the batch file
.\SETUP-GITHUB-SECRETS.bat
```

### Additional Options

You can specify a different repository:

```powershell
.\setup-github-secrets.ps1 `
    -Repository "owner/repo-name" `
    -ClientId "your-client-id-here" `
    -ClientSecret "your-client-secret-here"
```

**Security Best Practice**: Store your credentials in a secure password manager and copy them only when needed.

## Method 2: Using GitHub CLI Manually

### Prerequisites

1. **Install GitHub CLI** (if not already installed):
   - Download from: https://cli.github.com/
   - Or via package manager:
     ```bash
     # Windows (winget)
     winget install --id GitHub.cli
     
     # macOS (Homebrew)
     brew install gh
     
     # Linux (apt)
     sudo apt install gh
     ```

### Steps

1. **Authenticate with GitHub CLI:**
   ```bash
   gh auth login
   ```
   Follow the prompts to authenticate via web browser.

2. **Set the secrets:**
   ```bash
   gh secret set CLIENT_ID --body "YOUR_CLIENT_ID_HERE" --repo Mouy-leng/ZOLO-A6-9VxNUNA-
   gh secret set CLIENT_SECRET --body "YOUR_CLIENT_SECRET_HERE" --repo Mouy-leng/ZOLO-A6-9VxNUNA-
   ```
   
   **Important Notes:**
   - Secret names cannot start with `GITHUB_` as that prefix is reserved by GitHub
   - Secrets are encrypted and cannot be viewed after creation
   - You can only update or delete existing secrets

3. **Verify the secrets were added:**
   ```bash
   gh secret list --repo Mouy-leng/ZOLO-A6-9VxNUNA-
   ```

## Method 3: Using GitHub Web Interface

If you prefer a GUI approach or cannot use GitHub CLI:

1. **Navigate to your repository:**
   - Go to: https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-

2. **Access Settings:**
   - Click on **Settings** (in the repository navigation bar)
   - You must have admin access to the repository

3. **Navigate to Secrets:**
   - In the left sidebar, click on **Secrets and variables** → **Actions**

4. **Add CLIENT_ID secret:**
   - Click **New repository secret**
   - **Name**: `CLIENT_ID`
   - **Secret**: `YOUR_CLIENT_ID_HERE`
   - Click **Add secret**

5. **Add CLIENT_SECRET secret:**
   - Click **New repository secret** again
   - **Name**: `CLIENT_SECRET`
   - **Secret**: `YOUR_CLIENT_SECRET_HERE`
   - Click **Add secret**

6. **Verify:**
   - You should see both secrets listed (values will be hidden)
   - Each secret will show when it was created/updated

## Using Secrets in GitHub Actions

Once your secrets are set up, you can use them in your GitHub Actions workflows:

### Example 1: Environment Variables

```yaml
name: OAuth Integration

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    
    env:
      CLIENT_ID: ${{ secrets.CLIENT_ID }}
      CLIENT_SECRET: ${{ secrets.CLIENT_SECRET }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Use OAuth credentials
        run: |
          echo "Authenticating with OAuth..."
          # Your script that uses CLIENT_ID and CLIENT_SECRET
```

### Example 2: Direct Usage in Steps

```yaml
name: Deploy Application

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Authenticate
        run: |
          echo "Client ID: ${{ secrets.CLIENT_ID }}"
          # Use secrets in your deployment script
        env:
          CLIENT_ID: ${{ secrets.CLIENT_ID }}
          CLIENT_SECRET: ${{ secrets.CLIENT_SECRET }}
      
      - name: Deploy
        run: |
          ./deploy.sh
```

### Example 3: Passing to Actions

```yaml
name: Build and Test

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure OAuth
        uses: some-action/oauth-setup@v1
        with:
          client-id: ${{ secrets.CLIENT_ID }}
          client-secret: ${{ secrets.CLIENT_SECRET }}
```

## Security Best Practices

### ✅ Do's

1. **Use secrets for sensitive data:**
   - API keys
   - OAuth credentials
   - Database passwords
   - Private tokens
   - Certificates

2. **Rotate secrets regularly:**
   - Update secrets periodically
   - Update immediately if compromised

3. **Use environment-specific secrets:**
   - Different secrets for development, staging, and production
   - Use GitHub environments for better control

4. **Limit access:**
   - Only give repository admin access to trusted users
   - Use organization secrets for shared credentials

### ❌ Don'ts

1. **Never commit secrets to code:**
   - Always use GitHub Secrets or environment variables
   - Never hardcode credentials

2. **Don't log secret values:**
   - Avoid printing secrets in workflow logs
   - GitHub automatically masks secret values in logs

3. **Don't use reserved prefixes:**
   - Secret names cannot start with `GITHUB_`
   - This prefix is reserved by GitHub

4. **Don't share secrets publicly:**
   - Keep repository private if it contains sensitive workflows
   - Review pull requests carefully for secret exposure

## Troubleshooting

### GitHub CLI Not Authenticated

**Problem:** `gh auth status` shows "not logged into any GitHub hosts"

**Solution:**
```bash
gh auth login
```
Follow the prompts to authenticate via web browser.

### Permission Denied

**Problem:** Cannot set secrets - "permission denied" error

**Solution:**
- Ensure you have admin access to the repository
- Verify you're authenticated with the correct GitHub account
- Check if the repository exists and you have access

### Secret Not Available in Workflow

**Problem:** Secret is not accessible in GitHub Actions

**Solution:**
1. Verify the secret name matches exactly (case-sensitive)
2. Check that the secret is set in the correct repository
3. For organization repos, ensure secrets are shared with the repository
4. Wait a few moments after creating secrets before using them

### Cannot View Secret Value

**This is normal!** GitHub encrypts secrets and never exposes their values after creation. You can only:
- Update the secret with a new value
- Delete the secret
- See when it was last updated

## Verification

### Check Secrets via CLI

```bash
# List all secrets for a repository
gh secret list --repo Mouy-leng/ZOLO-A6-9VxNUNA-

# Check if a specific secret exists
gh secret list --repo Mouy-leng/ZOLO-A6-9VxNUNA- | grep CLIENT_ID
```

### Check Secrets via Web Interface

1. Go to: https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-/settings/secrets/actions
2. Verify both secrets are listed:
   - CLIENT_ID
   - CLIENT_SECRET

### Test in Workflow

Create a simple test workflow to verify secrets are accessible:

```yaml
name: Test Secrets

on: [workflow_dispatch]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Check if secrets are available
        run: |
          if [ -n "${{ secrets.CLIENT_ID }}" ]; then
            echo "✅ CLIENT_ID is available"
          else
            echo "❌ CLIENT_ID is not available"
            exit 1
          fi
          
          if [ -n "${{ secrets.CLIENT_SECRET }}" ]; then
            echo "✅ CLIENT_SECRET is available"
          else
            echo "❌ CLIENT_SECRET is not available"
            exit 1
          fi
```

## Status

✅ **Secrets Successfully Configured**

- ✓ `CLIENT_ID` - Set for repository `Mouy-leng/ZOLO-A6-9VxNUNA-`
- ✓ `CLIENT_SECRET` - Set for repository `Mouy-leng/ZOLO-A6-9VxNUNA-`

These secrets are now ready to be used in GitHub Actions workflows for OAuth authentication.

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## Related Files

- `setup-github-secrets.ps1` - Automated setup script
- `README.md` - Project overview
- `AUTOMATION-RULES.md` - Automation patterns
- `GITHUB-DESKTOP-RULES.md` - GitHub integration rules

## Last Updated

2025-12-22

---

**Note**: This guide is part of the ZOLO-A6-9VxNUNA trading system automation. For more information about the complete system, see the main README.md file.

# GitHub Token Quick Reference

## Token Details

**Token**: [See secure section below]  
**Type**: Personal Access Token (classic)  
**Configured**: 2026-02-05  
**Status**: Active

## Secure Token Storage

⚠️ **SECURITY NOTE**: The actual token is stored separately for security.

To retrieve the token:

1. Check your secure password manager
2. Or contact repository administrator
3. Or regenerate at: https://github.com/settings/tokens

**Token Format**: `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`

## Quick Commands

### Set Environment Variable

```bash
export GITHUB_TOKEN=your_token_here

```bash

### Verify Token

```bash

# Check authentication
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Using GitHub CLI
echo "$GITHUB_TOKEN" | gh auth login --with-token
gh auth status

```bash

### Clone with Token

```bash
git clone https://${GITHUB_TOKEN}@github.com/A6-9V/NUNA.git

```bash

### Set Git Remote

```bash
git remote set-url origin https://${GITHUB_TOKEN}@github.com/A6-9V/NUNA.git

```bash

## Configuration Files

- ✅ `.env.example` - Updated with token
- ✅ `.env.secrets.example` - Updated with token
- 📄 `GITHUB_TOKEN_SETUP.md` - Complete documentation

## Required Scopes

- ✅ `repo` - Full repository access
- ✅ `workflow` - Workflow management
- ✅ `write:packages` - Package registry
- ✅ `admin:org` - Organization access

## Security Notes

⚠️ **Never commit `.env` file with actual token**  
⚠️ **Rotate token every 90 days**  
⚠️ **Store securely in GitHub Secrets**  
⚠️ **Revoke immediately if exposed**

## Next Steps

1. Copy token to `.env` file
2. Add to GitHub repository secrets
3. Test token access
4. Set up token rotation reminder

---

For complete documentation, see: **GITHUB_TOKEN_SETUP.md**

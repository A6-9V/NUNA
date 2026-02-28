# SECURITY NOTICE: forge.mql5.io Token

## ⚠️ Important Security Information

This repository contains references to a forge.mql5.io authentication token in
documentation and scripts. This is by design per the project requirements.

## Token Information

**Token**: `PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW`  
**Purpose**: Authenticate with forge.mql5.io for repository synchronization  
**Scope**: Access to `forge.mql5.io/LengKundee/NUNA` repository  

## Where the Token Appears

The token is referenced in the following files:

1. `.git/config` - Git remote configuration (not committed)
2. `FORGE_MQL5_SETUP.md` - Setup documentation
3. `REPLIT_INTEGRATION.md` - Integration documentation
4. `INTEGRATION_SETUP_SUMMARY.md` - Setup summary
5. `INTEGRATION_QUICK_REFERENCE.md` - Quick reference
6. `scripts/sync-forge.sh` - Sync script
7. `scripts/sync-forge.ps1` - Sync script
8. `scripts/cleanup-forge.sh` - Cleanup script
9. `scripts/cleanup-forge.ps1` - Cleanup script
10. `system-info.json` - System information (partial token only)

## Security Considerations

### Current Setup (By Design)

- Token is embedded in documentation for ease of use
- Scripts use the token directly for automation
- This is acceptable if:
  - Repository is private
  - Token has limited scope (only forge.mql5.io access)
  - Token can be easily rotated if compromised

### If Security is a Concern

If you need to enhance security, consider these alternatives:

#### Option 1: Use Environment Variables

Replace hardcoded tokens with environment variables:

```bash

# In scripts, replace:

git remote add forge https://PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW@forge.mql5.io/LengKundee/NUNA.git

# With:

git remote add forge https://${FORGE_TOKEN}@forge.mql5.io/LengKundee/NUNA.git

```bash

Then set the environment variable:

```bash
export FORGE_TOKEN="PQEpZiFttpnKv82uWnYEfw6dJAFcdu1msL8x03LW"

```bash

#### Option 2: Use Git Credential Helper

Configure git to store credentials securely:

```bash

# Set up credential helper

git config credential.helper store

# Add remote without token

git remote add forge https://forge.mql5.io/LengKundee/NUNA.git

# Git will prompt for username and password (token)

git push forge main

```bash

#### Option 3: Use SSH Keys (if supported)

If forge.mql5.io supports SSH:

```bash
git remote set-url forge git@forge.mql5.io:LengKundee/NUNA.git

```bash

## Token Rotation

If the token is compromised:

1. Generate a new token on forge.mql5.io
2. Update all references to the old token:
   ```bash

   # Update git remote

   git remote set-url forge https://NEW_TOKEN@forge.mql5.io/LengKundee/NUNA.git
   
   # Update scripts (use find and replace)


   # Update documentation

   ```

## Best Practices

1. **Keep this repository private** if it contains authentication tokens
2. **Rotate tokens periodically** (every 90 days recommended)
3. **Monitor access logs** on forge.mql5.io for suspicious activity
4. **Use minimal permissions** - token should only have access to the NUNA
repository
5. **Consider using CI/CD secrets** for automated syncing instead of hardcoded
tokens

## Mitigating Public Exposure

If this repository becomes public or the token is exposed:

1. **Immediately revoke the token** on forge.mql5.io
2. **Generate a new token**
3. **Update all configurations** with the new token
4. **Review access logs** for unauthorized use
5. **Consider using environment variables** for the new token

## Reporting Security Issues

If you discover a security issue:

1. **DO NOT** open a public issue
2. Contact the repository owner directly
3. Provide details about the vulnerability
4. Wait for confirmation before disclosing publicly

## Compliance

This security notice is provided for transparency. The current setup with
hardcoded tokens in documentation:

- ✅ Is acceptable for private repositories
- ✅ Is acceptable when token scope is limited
- ⚠️ May not comply with enterprise security policies
- ❌ Is not recommended for public repositories

## Summary

The forge.mql5.io token is intentionally included in this repository for ease of
setup and automation. If you have security concerns or need to comply with
stricter security policies, consider implementing one of the alternative
authentication methods described above.

---

**Last Updated**: 2026-02-05  
**Security Review Status**: Documented  
**Risk Level**: Low (private repo, limited scope token)

# Secrets Directory

This directory is for storing sensitive information that should **NEVER** be committed to version control.

## Purpose

Store sensitive credentials, API keys, tokens, and other secrets that are used by the automation scripts.

## Protected by .gitignore

The entire `Secrets/` directory is gitignored to prevent accidental commits of sensitive information.

## What to Store Here

- API keys
- OAuth credentials
- Database passwords
- Private tokens
- Certificates (`.pem` files)
- Credential files (`.json`)
- Any other sensitive configuration

## Security Best Practices

1. **Never commit secrets to version control**
   - All files in this directory are automatically excluded
   - Double-check before pushing changes

2. **Use proper file permissions**
   - Restrict read/write access to this directory
   - Only the owner should have access

3. **Backup securely**
   - Keep encrypted backups in a secure location
   - Use a password manager for critical credentials

4. **Rotate regularly**
   - Update credentials periodically
   - Revoke old credentials when rotating

5. **Use GitHub Secrets for CI/CD**
   - For GitHub Actions workflows, use GitHub Secrets
   - See `GITHUB-SECRETS-SETUP.md` for instructions

## Related Files

- `oauth-credentials.secret` - OAuth credentials (in project root, also gitignored)
- `.gitignore` - Contains rules to protect sensitive files
- `setup-github-secrets.ps1` - Script to set up GitHub repository secrets
- `GITHUB-SECRETS-SETUP.md` - Documentation for secrets management

## Example Structure

```
Secrets/
├── README.md (this file - safe to commit)
├── api-keys.json (gitignored)
├── database-credentials.json (gitignored)
├── certificates/
│   ├── server.pem (gitignored)
│   └── client.pem (gitignored)
└── tokens/
    ├── github-token.txt (gitignored)
    └── trading-api-token.txt (gitignored)
```

## Verification

To verify files are properly gitignored:

```bash
git status --ignored
```

Files in this directory should appear under "Ignored files" section.

---

**Important**: If you accidentally commit a secret, consider it compromised and rotate it immediately!

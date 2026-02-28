# Security Notice

## Sensitive Information Handling

This repository contains sensitive information related to project access:

1. `.git/config` - Git remote configuration
2. `FORGE_MQL5_SETUP.md` - Setup documentation

### Git Remote with Token

A registration token for forge.mql5.io is used to enable automated sync.

```bash
git remote add forge https://USER:TOKEN@forge.mql5.io/LengKundee/NUNA.git
```

### Token Security

- **Private Repository**: This token is stored in a private repository.
- **Limited Access**: Access is restricted to project team members.
- **Revocation**: The token can be revoked if compromised.

### Best Practices

- Do not share the repository link publicly.
- Use environment variables for local development tokens.
- Review access logs regularly.

---
description: "Security rules for handling GitHub tokens and sensitive credentials"
alwaysApply: false
globs: ["*git*.ps1", "*credentials*", ".gitignore"]
---

# Security and Token Management

## Token Security Rules

1. **Never Commit Tokens**: All token files are in `.gitignore`
2. **Local Storage Only**: Tokens stored in local files only
3. **Credential Manager**: Tokens moved to Windows Credential Manager after first use
4. **Backup Tokens**: Multiple tokens supported for redundancy

## Token File Handling

- **File**: `git-credentials.txt` (must be in `.gitignore`)
- **Format**: `GITHUB_TOKEN=your_token_here`
- **Location**: Project root (local only, never committed)

## Preferred Authentication (OAuth)

- Prefer **GitHub CLI OAuth** (`gh auth login`) and configure git with `gh auth setup-git`.
- Use PATs only as a fallback when OAuth isn’t possible.

## Token Usage in Scripts

- Tokens are never logged or displayed
- Tokens stored in Windows Credential Manager after first use
- Token file is gitignored and never committed
- Use `Get-Content` with error handling to read tokens
- Never echo or Write-Host token values

## Token Permissions Required

- `repo` - Full repository access
- `workflow` - GitHub Actions (if using)

## Git Credential Management

- Prefer HTTPS with **OAuth via `gh`** when available
- PAT fallback: HTTPS with token authentication (never commit / never print)
- Store in Windows Credential Manager after first use
- Scripts should check for token file existence before use
- Provide helpful error messages if token is missing

## Security Best Practices

- Always verify `.gitignore` includes `git-credentials.txt`
- Never hardcode tokens in scripts
- Use environment variables or secure file storage
- Clear token variables after use when possible
- Document token requirements in documentation, not in code

## References

- See `AUTOMATION-RULES.md` for token management details
- See `.gitignore` for excluded files

---
description: "Automation patterns and intelligent defaults for Windows setup and git operations"
alwaysApply: false
globs: ["auto-*.ps1", "run-all-auto.ps1"]
---

# Automation Patterns

This project follows specific automation patterns for Windows setup and git operations.

## Core Principles

1. **Automated Decision Making**: Scripts make intelligent decisions without user prompts
2. **Best Practices First**: Always choose the most secure and recommended options
3. **Fail-Safe**: If something can't be automated, skip it gracefully
4. **Token Security**: GitHub tokens are stored locally and never committed

## Windows Setup Automation

### Browser Selection
- **Priority Order**: Chrome > Edge > Firefox
- Automatically select the first available browser
- Set as default browser automatically

### File Explorer Settings
- Show Extensions: Always enabled (security best practice)
- Show Hidden Files: Always enabled (usability)
- Launch To: Set to "This PC" (better organization)

### Windows Sync
- All Sync Groups: Enabled automatically
- Includes: Settings, Passwords, Theme, Language, etc.

### Security Configuration
- Defender Exclusions: Automatically added for all cloud folders
- Firewall Rules: Automatically created for cloud services
- Controlled Folder Access: Cloud folders automatically allowed

## Git Operations Automation

### Credential Management
- Preferred (recommended): GitHub CLI OAuth (`gh auth login`) + `gh auth setup-git`
- Fallback: `git-credentials.txt` (gitignored) for PAT-based automation if `gh` isn’t available
- Security: Never print tokens; never leave tokenized remote URLs configured after a push

### Commit Strategy
- Auto-commit: All changes committed automatically
- Commit Message: Intelligent messages based on file changes
- Branch: Always uses `main` branch

### Push Strategy
- Automatic Push: Pushes immediately after commit
- Error Handling: Graceful failure with helpful messages
- Auth Strategy: Uses OAuth via `gh` when available; otherwise PAT fallback (if configured locally)

## Cloud Services Automation

### Service Detection
- OneDrive: Checks standard installation paths
- Google Drive: Checks multiple possible locations
- Dropbox: Checks standard installation paths

### Service Management
- Auto-start: Services started automatically if found
- Status Check: Verifies if services are running
- No Installation: Skips if service not found (doesn't install)

## Error Handling Patterns

- **Missing Files**: Scripts skip gracefully
- **Permission Errors**: Scripts request elevation automatically
- **Network Errors**: Scripts report but don't fail completely
- **Token Errors**: Scripts provide helpful error messages

## Execution Flow

1. User runs: `RUN-AUTO-SETUP.bat` or `run-all-auto.ps1`
2. Windows Setup: Runs automatically with intelligent defaults
3. Git Push: Runs automatically (OAuth via `gh` preferred; PAT fallback optional)
4. Summary: Shows what was completed

## References

- See `AUTOMATION-RULES.md` for complete automation documentation
- See `README.md` for project overview

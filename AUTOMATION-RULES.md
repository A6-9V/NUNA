# Automation Rules and Configuration

This document defines the automation rules and intelligent defaults used by the setup scripts.

## Core Principles

1. **Automated Decision Making**: Scripts make intelligent decisions without user prompts
2. **Best Practices First**: Always choose the most secure and recommended options
3. **Fail-Safe**: If something can't be automated, skip it gracefully
4. **Token Security**: GitHub tokens are stored locally and never committed

## Automation Rules

### Windows Setup (`auto-setup.ps1`)

#### Browser Selection
- **Priority Order**: Chrome > Edge > Firefox
- **Decision**: Automatically select the first available browser
- **Action**: Set as default browser automatically

#### File Explorer Settings
- **Show Extensions**: Always enabled (security best practice)
- **Show Hidden Files**: Always enabled (usability)
- **Launch To**: Set to "This PC" (better organization)

#### Windows Sync
- **All Sync Groups**: Enabled automatically
- **Includes**: Settings, Passwords, Theme, Language, etc.

#### Security Configuration
- **Defender Exclusions**: Automatically added for all cloud folders
- **Firewall Rules**: Automatically created for cloud services
- **Controlled Folder Access**: Cloud folders automatically allowed

### Git Operations (`auto-git-push.ps1`)

#### Credential Management
- **Token Storage**: Saved in `git-credentials.txt` (gitignored)
- **Windows Credential Manager**: Tokens stored securely after first use
- **Remote URL**: Uses HTTPS with token authentication

#### Commit Strategy
- **Auto-commit**: All changes committed automatically
- **Commit Message**: Intelligent messages based on file changes
- **Branch**: Always uses `main` branch

#### Push Strategy
- **Automatic Push**: Pushes immediately after commit
- **Error Handling**: Graceful failure with helpful messages
- **Token Usage**: Uses saved token automatically

### Cloud Services

#### Service Detection
- **OneDrive**: Checks standard installation paths
- **Google Drive**: Checks multiple possible locations
- **Dropbox**: Checks standard installation paths

#### Service Management
- **Auto-start**: Services started automatically if found
- **Status Check**: Verifies if services are running
- **No Installation**: Skips if service not found (doesn't install)

## Token Security Rules

1. **Never Commit Tokens**: All token files are in `.gitignore`
2. **Local Storage Only**: Tokens stored in local files only
3. **Credential Manager**: Tokens moved to Windows Credential Manager after first use
4. **Backup Tokens**: Multiple tokens supported for redundancy

## File Organization

### Scripts
- `auto-setup.ps1` - Automated Windows configuration
- `auto-git-push.ps1` - Automated git operations with token
- `run-all-auto.ps1` - Master script that runs everything
- `git-setup.ps1` - Initial git repository setup

### Configuration
- `git-credentials.txt` - GitHub tokens (gitignored)
- `.gitignore` - Excludes all sensitive files

### Documentation
- `AUTOMATION-RULES.md` - This file
- `README.md` - Project documentation
- `MANUAL-SETUP-GUIDE.md` - Manual steps guide

## Execution Flow

1. **User runs**: `RUN-AUTO-SETUP.bat` or `run-all-auto.ps1`
2. **Windows Setup**: Runs automatically with intelligent defaults
3. **Git Push**: Runs automatically using saved token
4. **Summary**: Shows what was completed

## Error Handling

- **Missing Files**: Scripts skip gracefully
- **Permission Errors**: Scripts request elevation automatically
- **Network Errors**: Scripts report but don't fail completely
- **Token Errors**: Scripts provide helpful error messages

## Best Practices Enforced

1. **Security First**: All security settings enabled by default
2. **Privacy**: No data collection, all local
3. **Efficiency**: Minimal prompts, maximum automation
4. **Reliability**: Error handling at every step
5. **Maintainability**: Clear code structure and comments

## Customization

To customize automation rules, edit the respective script files:
- Browser selection: `Get-BestBrowser()` function in `auto-setup.ps1`
- Git behavior: `auto-git-push.ps1`
- Service detection: Service path arrays in `auto-setup.ps1`

## Token Management

### Adding/Updating Tokens
1. Edit `git-credentials.txt` (local file only)
2. Update `GITHUB_TOKEN` value
3. Scripts will use new token automatically

### Token Permissions Required
- `repo` - Full repository access
- `workflow` - GitHub Actions (if using)

### Security Notes
- Tokens are never logged or displayed
- Tokens stored in Windows Credential Manager after first use
- Token file is gitignored and never committed


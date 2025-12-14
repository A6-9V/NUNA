# GitHub Desktop Integration Rules

## Overview

This document defines the rules and best practices for using GitHub Desktop with the automated Windows setup scripts.

## GitHub Desktop Information

- **Website**: https://desktop.github.com/
- **Release Notes**: https://desktop.github.com/release-notes/
- **Download**: https://desktop.github.com/

## Installation Rules

### Automatic Detection
- Scripts check for GitHub Desktop in standard installation paths:
  - `%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe`
  - `%PROGRAMFILES%\GitHub Desktop\GitHubDesktop.exe`
  - `%PROGRAMFILES(X86)%\GitHub Desktop\GitHubDesktop.exe`

### Installation Process
1. If not found, script provides download link
2. User installs manually (GitHub Desktop requires user interaction)
3. After installation, run `github-desktop-setup.ps1` to configure

## Configuration Rules

### Git Settings
- **Username**: Automatically set to `Mouy-leng`
- **Email**: Automatically set to `Mouy-leng@users.noreply.github.com` (GitHub no-reply)
- **Shell**: Configured to use PowerShell

### Repository Association
- Local repository path: `C:\Users\USER\OneDrive`
- Repository URL: `https://github.com/Mouy-leng/Window-setup.git`
- Must be added manually in GitHub Desktop: File > Add Local Repository

### Settings File Location
- Settings stored in: `%APPDATA%\GitHub Desktop\settings.json`
- Scripts can modify settings automatically
- Settings are JSON format

## Integration with Automation Scripts

### Workflow
1. **Automated Scripts** (`auto-git-push.ps1`) handle git operations via command line
2. **GitHub Desktop** provides GUI for:
   - Visual diff viewing
   - Branch management
   - Pull request creation
   - History browsing

### Best Practices
- Use command line scripts for automation
- Use GitHub Desktop for visual operations
- Both can work on the same repository
- GitHub Desktop will detect changes made by scripts

## Update Rules

### Automatic Updates
- GitHub Desktop checks for updates automatically
- Updates are downloaded and installed automatically
- Release notes available at: https://desktop.github.com/release-notes/

### Version Tracking
- Check release notes regularly for new features
- Update automation rules if new features affect workflow
- Document any breaking changes

## Security Rules

### Authentication
- GitHub Desktop uses OAuth for authentication
- Tokens stored in Windows Credential Manager
- Separate from command-line git credentials

### Token Management
- Command-line scripts use Personal Access Tokens (from `git-credentials.txt`)
- GitHub Desktop uses OAuth tokens (managed by GitHub Desktop)
- Both methods are secure and can coexist

## Repository Rules

### Local Repository
- Path: `C:\Users\USER\OneDrive`
- Remote: `https://github.com/Mouy-leng/Window-setup.git`
- Branch: `main`

### File Exclusions
- `git-credentials.txt` - Never tracked (contains tokens)
- Personal files - Excluded via `.gitignore`
- System files - Excluded via `.gitignore`

## Automation Compatibility

### Scripts That Work Together
- `auto-git-push.ps1` - Command line git operations
- `github-desktop-setup.ps1` - GitHub Desktop configuration
- `run-all-auto.ps1` - Orchestrates all automation

### Conflict Prevention
- Scripts commit with specific messages
- GitHub Desktop will show these commits
- No conflicts if both use same repository
- GitHub Desktop refreshes automatically

## Troubleshooting

### GitHub Desktop Not Detected
1. Check installation paths
2. Verify GitHub Desktop is installed
3. Run `github-desktop-setup.ps1` to configure

### Settings Not Applied
1. Close GitHub Desktop before running setup script
2. Settings file may be locked if GitHub Desktop is running
3. Restart GitHub Desktop after configuration

### Repository Not Showing
1. Add repository manually: File > Add Local Repository
2. Select: `C:\Users\USER\OneDrive`
3. GitHub Desktop will detect existing git repository

## Release Notes Monitoring

### Regular Checks
- Check release notes monthly: https://desktop.github.com/release-notes/
- Review new features and improvements
- Update documentation if needed
- Test new features with automation scripts

### Breaking Changes
- Monitor release notes for breaking changes
- Update automation rules accordingly
- Test scripts after GitHub Desktop updates
- Document any compatibility issues

## Documentation Updates

When GitHub Desktop releases new versions:
1. Review release notes
2. Test with existing automation scripts
3. Update this document if rules change
4. Update `github-desktop-setup.ps1` if needed
5. Commit changes to repository

## Integration Checklist

- [ ] GitHub Desktop installed
- [ ] GitHub Desktop configured with account
- [ ] Local repository added to GitHub Desktop
- [ ] Git settings configured (username, email)
- [ ] Automation scripts tested
- [ ] Release notes reviewed
- [ ] Documentation updated

## References

- GitHub Desktop: https://desktop.github.com/
- Release Notes: https://desktop.github.com/release-notes/
- GitHub Repository: https://github.com/Mouy-leng/Window-setup.git
- Automation Rules: See `AUTOMATION-RULES.md`

---

**Last Updated**: Based on GitHub Desktop release notes review
**Next Review**: Check release notes monthly for updates


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
  - `%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe` (Primary location on Windows 11)
  - `%PROGRAMFILES%\GitHub Desktop\GitHubDesktop.exe`
  - `%PROGRAMFILES(X86)%\GitHub Desktop\GitHubDesktop.exe` (Checked safely with error handling)
- **System**: NuNa (Windows 11 Home Single Language 25H2, 64-bit x64)
- **Note**: ProgramFiles(x86) path is checked with try-catch to handle 64-bit systems gracefully

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
- Command-line scripts should prefer GitHub CLI OAuth (`gh auth login` + `gh auth setup-git`)
- PAT fallback (`git-credentials.txt`) is supported for automation if `gh` is unavailable
- GitHub Desktop uses its own OAuth tokens (managed by GitHub Desktop)
- All methods can coexist, but OAuth (Desktop/gh) reduces PAT handling risk

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

### Release Notes URL
- **Official Release Notes**: https://desktop.github.com/release-notes/
- Check regularly for latest updates and features
- Use `check-github-desktop-updates.ps1` script to check version and open release notes

### Regular Checks
- Check release notes monthly: https://desktop.github.com/release-notes/
- Review new features and improvements
- Update documentation if needed
- Test new features with automation scripts
- Run update check script: `.\check-github-desktop-updates.ps1`

### Breaking Changes
- Monitor release notes for breaking changes
- Update automation rules accordingly
- Test scripts after GitHub Desktop updates
- Document any compatibility issues
- Update `github-desktop-setup.ps1` if configuration changes

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

## System Configuration

- **Device**: NuNa
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Architecture**: 64-bit x64-based processor
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)
- **Installation Date**: 12/9/2025

For complete system information, see `SYSTEM-INFO.md`.

---

**Last Updated**: 2025-12-09
**System**: NuNa (Windows 11 Home Single Language 25H2)
**Next Review**: Check release notes monthly for updates


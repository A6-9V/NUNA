# Project Instructions for Cursor Agent

This document provides instructions for working with this Windows automation and setup project.

## System Configuration

- **Device**: NuNa
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Architecture**: 64-bit x64-based processor
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)

## Code Style

### PowerShell Scripts
- Use clear, descriptive variable names
- Add comments for complex logic
- Use `Write-Host` with `-ForegroundColor` for user feedback
- Always use try-catch blocks for error handling
- Use consistent status indicators: `[OK]`, `[INFO]`, `[WARNING]`, `[ERROR]`

### Error Handling
- Always use try-catch blocks for operations that might fail
- Skip gracefully if files/services are not found
- Use `Test-Path` before accessing files or directories
- Provide helpful error messages to users

## Environment Variables

- Use `$env:VARIABLENAME` for standard environment variables
- For `ProgramFiles(x86)`, always use: `(Get-Item "Env:ProgramFiles(x86)").Value` with try-catch
- Always handle cases where environment variables might not exist

## Security

- Never commit tokens or credentials
- All token files must be in `.gitignore`
- Tokens stored in Windows Credential Manager after first use
- Never log or display token values

## Automation Principles

1. **Automated Decision Making**: Scripts make intelligent decisions without user prompts
2. **Best Practices First**: Always choose the most secure and recommended options
3. **Fail-Safe**: If something can't be automated, skip it gracefully
4. **Token Security**: GitHub tokens are stored locally and never committed

## File Organization

- Scripts: `*.ps1` files in project root
- Documentation: `*.md` files for rules and guides
- Configuration: `git-credentials.txt` (gitignored, PAT fallback only; prefer `gh auth login` OAuth)
- Rules: `.cursor/rules/` directory for project-specific rules

## References

- `SYSTEM-INFO.md` - Complete system specifications
- `AUTOMATION-RULES.md` - Automation patterns and rules
- `GITHUB-DESKTOP-RULES.md` - GitHub Desktop integration
- `README.md` - Project overview and usage

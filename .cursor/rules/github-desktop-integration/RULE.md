---
description: "Rules for GitHub Desktop integration and update checking"
alwaysApply: false
globs: ["*github-desktop*.ps1", "check-github-desktop-updates.ps1"]
---

# GitHub Desktop Integration

## Installation Detection

Scripts check for GitHub Desktop in these locations (in order):
1. `$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe` (Primary on Windows 11)
2. `$env:PROGRAMFILES\GitHub Desktop\GitHubDesktop.exe`
3. `%PROGRAMFILES(X86)%\GitHub Desktop\GitHubDesktop.exe` (with proper error handling)

## Path Detection Pattern

Always use this pattern for ProgramFiles(x86):
```powershell
try {
    $programFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value
    if ($programFilesX86) {
        $desktopPaths += "$programFilesX86\GitHub Desktop\GitHubDesktop.exe"
    }
} catch {
    # ProgramFiles(x86) may not exist on 64-bit only systems
}
```

## Version Checking

- Check version using: `(Get-Item $path).VersionInfo.FileVersion`
- Warn if version is older than 3.3.0
- Parse version parts safely: `$parts = $ver -split '\.'`
- Always check `$parts.Count -ge 2` before accessing array elements

## Settings File

- Location: `$env:APPDATA\GitHub Desktop\settings.json`
- Format: JSON
- Can be modified automatically by scripts
- Close GitHub Desktop before modifying settings

## Release Notes

- **URL**: https://desktop.github.com/release-notes/
- Check regularly for updates
- Use `check-github-desktop-updates.ps1` to check version
- Open release notes with: `Start-Process "https://desktop.github.com/release-notes/"`

## Repository Configuration

- Local path: `C:\Users\USER\OneDrive`
- Remote: `https://github.com/Mouy-leng/Window-setup.git`
- Branch: `main`
- Must be added manually in GitHub Desktop: File > Add Local Repository

## Integration with Automation

- Command-line scripts (`auto-git-push.ps1`) handle git operations
- GitHub Desktop provides GUI for visual operations
- Both can work on the same repository
- GitHub Desktop detects changes made by scripts automatically

## References

- See `GITHUB-DESKTOP-RULES.md` for complete integration documentation
- Release Notes: https://desktop.github.com/release-notes/

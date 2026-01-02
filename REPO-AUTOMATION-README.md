# Repository Automation Scripts

This directory contains automation scripts for reviewing, merging pull requests, and injecting repositories from Mouy-leng and A6-9V organization into the my-drive-projects repository.

## Scripts Overview

### 1. `auto-review-merge-inject-repos.ps1` (Windows PowerShell)
Comprehensive PowerShell script for Windows environments.

### 2. `auto-review-merge-inject-repos.sh` (Linux/macOS Bash)
Bash version for Linux/macOS environments.

## Features

### Phase 1: Pull Request Review and Merge
- Automatically fetches all open PRs from:
  - All Mouy-leng repositories (14 repositories)
  - All A6-9V organization repositories
- Reviews each PR for:
  - Merge conflicts
  - CI/CD status checks
  - Merge ability
- Auto-merges PRs that pass all checks
- Generates detailed report of merge actions

### Phase 2: Repository Injection
- Clones or updates all repositories from:
  - Mouy-leng account
  - A6-9V organization
- Injects repository contents into `injected-repos/` directory
- Organizes by category:
  - `injected-repos/Mouy-leng/`
  - `injected-repos/A6-9V/`
- Excludes `.git` directories to prevent conflicts
- Creates comprehensive index and catalog

## Prerequisites

### For All Platforms:
1. **GitHub CLI (gh)**: Install from https://cli.github.com/
2. **Git**: Must be installed and configured
3. **GitHub Authentication**: Run `gh auth login` before using scripts

### Additional for Linux/macOS:
- `jq` command-line JSON processor
- `rsync` for efficient file copying

### Additional for Windows:
- PowerShell 5.1 or later
- `robocopy` (included with Windows)

## Usage

### Dry Run (Preview Mode)
Test what the script will do without making changes:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh --dry-run
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1 -DryRun
```

### Full Automation
Review, merge PRs, and inject all repositories:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1
```

### Skip PR Merging (Injection Only)
Only clone and inject repositories, skip PR processing:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh --inject-only
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1 -InjectOnly
```

### Skip Merging (Review Only)
Process PRs without actually merging them:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh --skip-merge
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1 -SkipMerge
```

## Output Files

After running, the script generates:

1. **Log File**: `repo-automation-YYYYMMDD-HHMMSS.log`
   - Detailed execution log with timestamps
   - Color-coded status messages

2. **Report File**: `repo-automation-report-YYYYMMDD-HHMMSS.md`
   - Markdown report with:
     - PR processing summary table
     - Repository injection summary table
     - Status of each operation

3. **Index File**: `injected-repos/README.md`
   - Complete catalog of injected repositories
   - Directory structure overview

## Repository Structure After Injection

```
my-drive-projects/
├── injected-repos/
│   ├── README.md                    # Index of all injected repos
│   ├── Mouy-leng/
│   │   ├── CompleteBotV2/          # Trading bot repository
│   │   ├── GenX_FX_0/              # Forex trading platform
│   │   ├── GenX_FX/                # AI-powered forex platform
│   │   ├── GenX_FX-v2/             # Version 2 of GenX FX
│   │   ├── Spreadsheet_N_Excel/    # Business management tools
│   │   ├── domain-controller/      # Drive management system
│   │   └── ...                     # Other repositories
│   └── A6-9V/
│       ├── A6..9V-GenX_FX.main/    # GenX FX main repository
│       └── ...                     # Other org repositories
├── auto-review-merge-inject-repos.ps1
├── auto-review-merge-inject-repos.sh
└── REPO-AUTOMATION-README.md       # This file
```

## Current Repository Status

### Mouy-leng Repositories (14 total):
1. **CompleteBotV2** - Python trading bot
2. **GenX_FX_0** - Python forex platform (48 open issues)
3. **GenX_FX** - AI-powered trading platform (31 open issues)
4. **Gen** - Python project (archived)
5. **GenX_FX-v2** - Version 2
6. **Android-development** - Android development
7. **demo-repository** - Demo examples
8. **Spreadsheet_N_Excel** - Business tools
9. **A69VTestApp** - Test application
10. **ProductionApp** - Production app
11. **GenX** - Full backend (archived)
12. **AdvancedIntelligence** - Jupyter notebooks (archived)
13. **Capital.BotV3** - Trading bot (archived)
14. **domain-controller** - Drive management

### A6-9V Organization Repositories:
- Various projects including my-drive-projects itself
- Multiple open PRs requiring review

### Open Pull Requests Summary:
- **22 open PRs** from Mouy-leng across various repositories
- Topics include:
  - Trading system improvements
  - Security fixes
  - Feature additions
  - Test stabilization
  - Documentation updates

## Safety Features

### PR Merge Safety:
- ✅ Checks for merge conflicts before merging
- ✅ Verifies CI/CD status checks
- ✅ Requires passing tests before auto-merge
- ✅ Manual review flagged for problematic PRs
- ✅ Dry-run mode to preview actions

### Repository Injection Safety:
- ✅ Excludes `.git` directories to prevent conflicts
- ✅ Creates separate category directories
- ✅ Preserves original repositories (non-destructive)
- ✅ Generates detailed logs and reports
- ✅ Skips my-drive-projects itself to avoid recursion

## Error Handling

The scripts include comprehensive error handling:
- Continue on non-critical errors
- Log all errors with details
- Generate report even if some operations fail
- Color-coded output for easy problem identification

## Example Output

```
[2025-12-22 06:54:04] [INFO] ========================================
[2025-12-22 06:54:04] [INFO] Repository Automation Script Started
[2025-12-22 06:54:04] [INFO] ========================================
[2025-12-22 06:54:05] [SUCCESS] GitHub CLI is authenticated
[2025-12-22 06:54:06] [INFO] Processing PR: Mouy-leng/GenX_FX_0#64
[2025-12-22 06:54:07] [SUCCESS] Successfully merged PR
[2025-12-22 06:54:10] [INFO] Injecting CompleteBotV2 into my-drive-projects...
[2025-12-22 06:54:15] [SUCCESS] Successfully injected: CompleteBotV2
...
[2025-12-22 07:15:30] [SUCCESS] ========================================
[2025-12-22 07:15:30] [SUCCESS] Automation Complete!
[2025-12-22 07:15:30] [SUCCESS] ========================================
[2025-12-22 07:15:30] [INFO] PRs Processed: 22
[2025-12-22 07:15:30] [INFO] Repositories Injected: 14
```

## Troubleshooting

### "GitHub CLI is not authenticated"
**Solution:** Run `gh auth login` and follow the prompts

### "Permission denied" errors
**Solution:** Ensure you have:
- Write access to the repository
- Proper GitHub token permissions
- Run with appropriate permissions

### "jq: command not found" (Linux/macOS)
**Solution:** Install jq:
- **Ubuntu/Debian:** `sudo apt-get install jq`
- **macOS:** `brew install jq`
- **Red Hat/CentOS:** `sudo yum install jq`

### Script won't run (Linux/macOS)
**Solution:** Make it executable:
```bash
chmod +x auto-review-merge-inject-repos.sh
```

## Best Practices

1. **Always run dry-run first** to preview actions
2. **Review the generated report** before committing
3. **Check log files** for any warnings or errors
4. **Verify injected repos** in the injected-repos directory
5. **Commit incrementally** rather than all at once

## Advanced Usage

### Custom Repository Filtering
Edit the script to add filtering logic in the main() function

### Change Injection Directory
Modify the `inject_repository()` function to change target location

### Additional Checks
Add custom validation logic in `process_pr()` function

## Support

For issues or questions:
1. Check the generated log files
2. Review the report markdown file
3. Check GitHub CLI documentation
4. Verify your authentication status

## License

These scripts are part of the my-drive-projects repository.
Use in accordance with repository license.

## Author

Created by Copilot Coding Agent for A6-9V/my-drive-projects

## Last Updated

2025-12-22

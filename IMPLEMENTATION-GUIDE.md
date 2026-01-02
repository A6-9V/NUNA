# Implementation Guide: Repository Automation

This guide provides step-by-step instructions for executing the repository automation to review/merge all PRs and inject repositories into my-drive-projects.

## Quick Start

For users who want to run the automation immediately:

```bash
# Step 1: Authenticate with GitHub
gh auth login

# Step 2: Run in dry-run mode to preview
./auto-review-merge-inject-repos.sh --dry-run

# Step 3: Review the preview output

# Step 4: Execute the automation
./auto-review-merge-inject-repos.sh

# Step 5: Review generated reports
cat repo-automation-report-*.md
```

## Detailed Implementation Steps

### Prerequisites Setup

#### 1. Install GitHub CLI

**Linux (Ubuntu/Debian):**
```bash
# Add GitHub CLI repository
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```

**macOS:**
```bash
brew install gh
```

**Windows:**
```powershell
# Using winget
winget install --id GitHub.cli

# Or using Chocolatey
choco install gh
```

#### 2. Install Additional Dependencies

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install -y jq rsync git
```

**macOS:**
```bash
brew install jq rsync git
```

**Windows:**
```powershell
# Git should already be installed
# jq and rsync are not required for PowerShell version
# But can be installed via: choco install jq
```

#### 3. Authenticate GitHub CLI

```bash
gh auth login
```

Follow the prompts:
1. Choose "GitHub.com"
2. Choose "HTTPS" as protocol
3. Choose "Login with a web browser"
4. Copy the one-time code
5. Press Enter to open browser
6. Paste code and authorize

Verify authentication:
```bash
gh auth status
```

### Execution Modes

#### Mode 1: Dry Run (Recommended First)

Preview all actions without making any changes:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh --dry-run
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1 -DryRun
```

**Expected Output:**
```
[2025-12-22 07:00:00] [INFO] ========================================
[2025-12-22 07:00:00] [INFO] Repository Automation Script Started
[2025-12-22 07:00:00] [INFO] ========================================
[2025-12-22 07:00:00] [INFO] Dry Run: true
[2025-12-22 07:00:00] [SUCCESS] GitHub CLI is authenticated
[2025-12-22 07:00:05] [INFO] Found 22 open PR(s) across repositories
[2025-12-22 07:00:06] [INFO] [DRY RUN] Would merge PR Mouy-leng/GenX_FX_0#64
[2025-12-22 07:00:07] [INFO] [DRY RUN] Would inject CompleteBotV2
...
```

Review the output carefully. Check:
- ✅ Number of PRs that would be merged
- ✅ Number of repositories that would be injected
- ✅ Any warnings or errors
- ✅ Storage space requirements

#### Mode 2: Full Automation

Execute all operations (PR merge + injection):

**Bash:**
```bash
./auto-review-merge-inject-repos.sh
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1
```

**Duration:** Approximately 15-30 minutes depending on:
- Number of repositories
- Internet connection speed
- Repository sizes

#### Mode 3: Injection Only

Skip PR processing, only inject repositories:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh --inject-only
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1 -InjectOnly
```

Use this mode if:
- PRs have already been merged manually
- You only want to update injected repositories
- You want to skip PR review entirely

#### Mode 4: Review Only

Review PRs without merging or injecting:

**Bash:**
```bash
./auto-review-merge-inject-repos.sh --skip-merge
```

**PowerShell:**
```powershell
.\auto-review-merge-inject-repos.ps1 -SkipMerge
```

Use this mode to:
- Generate PR status report
- Identify problematic PRs
- Plan manual interventions

### Understanding the Output

#### Console Output

The script provides color-coded real-time feedback:

- **Green (SUCCESS):** Operation completed successfully
- **Cyan (INFO):** Informational messages about progress
- **Yellow (WARNING):** Non-critical issues that need attention
- **Red (ERROR):** Critical errors that prevented an operation

#### Log File

Format: `repo-automation-YYYYMMDD-HHMMSS.log`

Contains detailed timestamped log of all operations:
```
[2025-12-22 07:05:30] [INFO] Fetching repositories for user: Mouy-leng...
[2025-12-22 07:05:35] [SUCCESS] Found 14 repositories for Mouy-leng
[2025-12-22 07:05:40] [INFO] Processing PR: Mouy-leng/GenX_FX_0#64
[2025-12-22 07:05:45] [SUCCESS] Successfully merged PR
```

Use for:
- Debugging issues
- Audit trail
- Determining what was changed

#### Report File

Format: `repo-automation-report-YYYYMMDD-HHMMSS.md`

Markdown-formatted summary report with tables:

**PR Processing Section:**
| Repository | PR# | Title | Status | Action |
|------------|-----|-------|--------|--------|
| Mouy-leng/GenX_FX_0 | #64 | Add automatic server selection | Merged | Merged Successfully |

**Repository Injection Section:**
| Repository | Category | Status | Target Path |
|------------|----------|--------|-------------|
| CompleteBotV2 | Mouy-leng | Injected Successfully | ./injected-repos/Mouy-leng/CompleteBotV2 |

### Post-Execution Steps

#### 1. Review Generated Files

```bash
# View the report
cat repo-automation-report-*.md

# Check the log for any warnings or errors
grep -i "warning\|error" repo-automation-*.log

# View the repository index
cat injected-repos/README.md
```

#### 2. Verify Injected Repositories

```bash
# List all injected repositories
ls -la injected-repos/Mouy-leng/
ls -la injected-repos/A6-9V/

# Verify specific repository
cd injected-repos/Mouy-leng/GenX_FX_0
ls -la
```

#### 3. Commit Changes (if needed)

The injected repositories are excluded by `.gitignore`, but you may want to commit the automation scripts and documentation:

```bash
# Stage all changes except injected repos
git add auto-review-merge-inject-repos.*
git add REPO-AUTOMATION-README.md
git add IMPLEMENTATION-GUIDE.md
git add .gitignore

# Commit
git commit -m "Add repository automation and documentation"

# Push
git push
```

#### 4. Handle Manual Review Items

If the report shows PRs that couldn't be auto-merged:

```bash
# List PRs requiring manual review
grep "Manual Review Required" repo-automation-report-*.md

# For each PR, review on GitHub and merge manually
# Example:
gh pr view 64 --repo Mouy-leng/GenX_FX_0
gh pr merge 64 --repo Mouy-leng/GenX_FX_0 --merge
```

### Troubleshooting

#### Issue: "GitHub CLI is not authenticated"

**Solution:**
```bash
gh auth login
gh auth status
```

#### Issue: "jq: command not found"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

#### Issue: "Permission denied" when running script

**Solution:**
```bash
chmod +x auto-review-merge-inject-repos.sh
./auto-review-merge-inject-repos.sh --dry-run
```

#### Issue: Script fails with "API rate limit exceeded"

**Solution:**
```bash
# Check your rate limit status
gh api rate_limit

# Wait for rate limit to reset, or use different auth method
# The script will automatically retry failed operations
```

#### Issue: Merge conflicts in PR

**Expected Behavior:** Script will skip PRs with conflicts and mark them for manual review.

**Solution:**
```bash
# Resolve conflicts manually
gh pr view <PR_NUMBER> --repo <OWNER>/<REPO>
# Follow GitHub's conflict resolution guide
# Then re-run the script
```

#### Issue: Out of disk space

**Solution:**
```bash
# Check available space
df -h

# Clean up if needed
rm -rf /tmp/repo-automation-temp/*

# Reduce number of repos by editing script
```

### Advanced Configuration

#### Customize Which Repositories to Inject

Edit the script's main function to add filtering:

```bash
# In auto-review-merge-inject-repos.sh
# Add after line: while read -r repo; do
if [ "$repo_name" = "specific-repo-to-skip" ]; then
    continue
fi
```

#### Change Injection Directory

Modify the `inject_repository` function:

```bash
# Change from:
local target_dir="$(pwd)/injected-repos/$category/$repo_name"

# To:
local target_dir="/custom/path/$category/$repo_name"
```

#### Add Custom PR Validation

Modify the `process_pr` function to add custom checks:

```bash
# Example: Only merge PRs from specific authors
if [ "$pr_author" != "Mouy-leng" ]; then
    log_warning "Skipping PR from $pr_author"
    return
fi
```

### Scheduling Automation

#### Linux/macOS (Cron)

Create a cron job to run daily:

```bash
# Edit crontab
crontab -e

# Add line to run daily at 2 AM
0 2 * * * cd /path/to/my-drive-projects && ./auto-review-merge-inject-repos.sh >> /var/log/repo-automation.log 2>&1
```

#### Windows (Task Scheduler)

Create scheduled task via PowerShell:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\auto-review-merge-inject-repos.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "RepoAutomation" -Action $action -Trigger $trigger
```

### Best Practices

1. **Always run dry-run first** before production execution
2. **Review reports thoroughly** before committing changes
3. **Keep backups** of important data before running
4. **Monitor disk space** when injecting many repositories
5. **Check GitHub API rate limits** if running frequently
6. **Test with small subset** before full automation
7. **Keep scripts updated** with latest gh CLI features
8. **Document customizations** you make to scripts
9. **Schedule during off-peak hours** for production use
10. **Maintain clean working directory** between runs

### Cleanup

After execution, you can clean up temporary files:

```bash
# Remove temporary clones
rm -rf /tmp/repo-automation-temp/

# Keep last 5 reports, delete older ones
ls -t repo-automation-report-*.md | tail -n +6 | xargs rm -f

# Keep last 5 logs, delete older ones
ls -t repo-automation-*.log | tail -n +6 | xargs rm -f
```

### Getting Help

If you encounter issues:

1. **Check the log file** for detailed error messages
2. **Run in dry-run mode** to identify the problem
3. **Verify prerequisites** are properly installed
4. **Check GitHub status** at https://www.githubstatus.com/
5. **Review documentation** in REPO-AUTOMATION-README.md
6. **Check gh CLI documentation** at https://cli.github.com/manual/

### Success Metrics

After successful execution, you should see:

✅ All safe PRs merged (those without conflicts or failed checks)
✅ All repositories cloned and injected into organized structure
✅ Comprehensive report generated with statistics
✅ Index file created in injected-repos/
✅ No critical errors in log file
✅ Manual review list created for problematic PRs

### Next Steps

After automation completes:

1. Review the generated report
2. Manually merge any flagged PRs
3. Test functionality of injected repositories
4. Update documentation as needed
5. Share results with team members
6. Plan for regular automation runs
7. Consider CI/CD integration

## Conclusion

This automation significantly reduces manual effort in:
- Reviewing and merging pull requests
- Keeping repository copies up-to-date
- Maintaining organized project structure

Follow this guide carefully, start with dry-run mode, and gradually build confidence with the automation tools.

---

**Last Updated:** 2025-12-22  
**Version:** 1.0  
**Author:** Copilot Coding Agent for A6-9V/my-drive-projects

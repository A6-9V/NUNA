# Auto-Merge Setup Guide

This guide explains how to set up and use automatic PR merging for the my-drive-projects repository.

## Overview

Auto-merge allows pull requests to be automatically merged when all requirements are met:
- ✅ All status checks pass
- ✅ All required reviews are approved
- ✅ No merge conflicts exist
- ✅ The PR is not in draft mode

## Quick Start

### For Windows (PowerShell)

1. **Double-click the batch file:**
   ```
   SETUP-AUTO-MERGE.bat
   ```

2. **Or run PowerShell directly:**
   ```powershell
   .\setup-auto-merge.ps1
   ```

### For Linux/macOS (GitHub CLI)

```bash
# Enable auto-merge for the repository
gh api -X PATCH repos/A6-9V/my-drive-projects -f allow_auto_merge=true

# Enable auto-merge for a specific PR
gh pr merge <PR-number> --auto --merge
```

## What Gets Installed

### 1. GitHub Actions Workflows

Two workflows are created in `.github/workflows/`:

#### `auto-merge.yml`
- Monitors all PRs for merge eligibility
- Checks for conflicts, status checks, and reviews
- Automatically merges when all requirements are met
- Deletes the branch after successful merge

#### `enable-auto-merge.yml`
- Automatically enables auto-merge when a PR is opened
- Adds informative comments to PRs
- Uses GitHub's built-in auto-merge feature

### 2. Setup Script (`setup-auto-merge.ps1`)

Interactive PowerShell script that:
- Verifies GitHub CLI installation and authentication
- Checks repository configuration
- Enables auto-merge on the repository
- Lists open PRs and allows enabling auto-merge for each

### 3. Batch Launcher (`SETUP-AUTO-MERGE.bat`)

Simple double-click launcher for Windows users.

## Repository Configuration

Auto-merge requires specific repository settings to be enabled:

1. **Allow auto-merge**: Must be enabled (handled by setup script)
2. **Merge methods**: At least one merge method must be allowed:
   - Merge commits (recommended)
   - Squash merging
   - Rebase merging

## How It Works

### Workflow Trigger Events

The workflows are triggered by:
- `pull_request` events: opened, synchronize, reopened, ready_for_review
- `pull_request_review` events: submitted
- `check_suite` events: completed
- `status` events: status check updates

### Merge Requirements

A PR will be auto-merged when:

1. **Not in draft mode**
2. **Mergeable state is clean** (no conflicts)
3. **All status checks pass** (if configured)
4. **No changes requested** in reviews
5. **Branch is up-to-date** with base branch

### Safety Features

- ✅ Never merges PRs with conflicts
- ✅ Waits for all CI/CD checks to pass
- ✅ Respects review requirements
- ✅ Adds informative comments to PRs
- ✅ Handles errors gracefully

## Manual Operations

### Enable Auto-Merge for a PR

Using GitHub CLI:
```bash
gh pr merge <PR-number> --auto --merge
```

Using GitHub Web UI:
1. Open the pull request
2. Click "Enable auto-merge" button
3. Select merge method
4. Click "Enable auto-merge"

### Disable Auto-Merge for a PR

Using GitHub CLI:
```bash
gh pr merge <PR-number> --disable-auto
```

Using GitHub Web UI:
1. Open the pull request
2. Click "Disable auto-merge" button

### Check Auto-Merge Status

```bash
gh pr view <PR-number> --json autoMergeRequest
```

## Troubleshooting

### "GitHub CLI is not authenticated"

**Solution:**
```bash
gh auth login
```
Follow the prompts to authenticate.

### "Could not enable auto-merge"

**Possible causes:**
1. You don't have admin/write permissions on the repository
2. Auto-merge is disabled in repository settings
3. Branch protection rules conflict with auto-merge

**Solution:**
1. Check permissions: `gh repo view A6-9V/my-drive-projects`
2. Enable in settings: https://github.com/A6-9V/my-drive-projects/settings
3. Review branch protection rules

### "Auto-merge not working for a PR"

**Checklist:**
- [ ] PR is not in draft mode
- [ ] No merge conflicts exist
- [ ] All status checks are passing
- [ ] No changes requested in reviews
- [ ] Auto-merge is actually enabled for the PR

**Debug:**
```bash
gh pr view <PR-number> --json mergeable,mergeStateStatus,autoMergeRequest
```

### "Workflow is not running"

**Possible causes:**
1. Workflows are disabled for the repository
2. GitHub Actions is not enabled
3. Workflow file has syntax errors

**Solution:**
1. Check Actions tab: https://github.com/A6-9V/my-drive-projects/actions
2. Enable Actions in repository settings if disabled
3. Validate workflow syntax: https://rhysd.github.io/actionlint/

## Best Practices

### For PR Authors

1. **Keep PRs small and focused** - Easier to review and merge
2. **Write clear PR descriptions** - Helps reviewers understand changes
3. **Ensure tests pass** before opening PR
4. **Keep branch up-to-date** with base branch
5. **Respond to review comments** promptly

### For Repository Maintainers

1. **Configure branch protection rules**
   - Require status checks to pass
   - Require review approvals
   - Require branches to be up to date

2. **Set up CI/CD pipelines**
   - Run tests on every PR
   - Check code quality
   - Validate builds

3. **Monitor auto-merge activity**
   - Review merged PRs regularly
   - Check for any issues
   - Adjust settings as needed

## Configuration Files

### `.github/workflows/auto-merge.yml`

Full-featured auto-merge workflow with:
- Comprehensive status checks
- Review validation
- Automatic branch updates
- Comment notifications
- Branch deletion after merge

### `.github/workflows/enable-auto-merge.yml`

Lightweight workflow that:
- Enables auto-merge when PR is opened
- Uses GitHub's built-in auto-merge feature
- Adds informative comments

## Security Considerations

### Permissions

The workflows use `GITHUB_TOKEN` with these permissions:
- `contents: write` - To merge PRs and delete branches
- `pull-requests: write` - To enable auto-merge and add comments
- `checks: read` - To check status of CI/CD runs

### Token Security

- ✅ Uses built-in `GITHUB_TOKEN` (no secrets needed)
- ✅ Token is automatically scoped to the repository
- ✅ Token expires after the workflow run
- ✅ No external services or APIs are called

### Safety Measures

- Only merges PRs that pass all checks
- Respects review requirements
- Never bypasses branch protection rules
- Logs all actions for audit trail

## Integration with Existing Scripts

### `check-and-merge-prs.ps1`

The existing `check-and-merge-prs.ps1` script complements the auto-merge workflows:
- Manual PR checking and merging
- Works with GitHub CLI
- Fallback to GitHub API if CLI not available
- Can be run independently

### `auto-review-merge-inject-repos.ps1`

The comprehensive automation script handles:
- Multi-repository PR management
- Repository injection
- Detailed logging and reporting
- Works alongside auto-merge workflows

## Future Enhancements

Potential improvements for auto-merge:
- [ ] Configurable merge strategies per PR label
- [ ] Scheduled merge windows
- [ ] Automatic PR creation from branches
- [ ] Integration with project boards
- [ ] Slack/Teams notifications
- [ ] Custom merge validation rules

## Additional Resources

- [GitHub Auto-Merge Documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub REST API Documentation](https://docs.github.com/en/rest)

## Support

For issues or questions:
1. Check workflow runs: https://github.com/A6-9V/my-drive-projects/actions
2. Review workflow logs for errors
3. Verify repository settings
4. Check GitHub CLI authentication: `gh auth status`

## License

Part of the my-drive-projects repository.
Use in accordance with repository license.

## Author

Created by GitHub Copilot for A6-9V/my-drive-projects

## Last Updated

2025-12-22

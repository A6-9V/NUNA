# Auto-Merge Quick Start

Quickly enable automatic PR merging for this repository.

## 🚀 One-Click Setup (Windows)

Simply double-click:
```
SETUP-AUTO-MERGE.bat
```

This will:
- ✅ Check GitHub CLI authentication
- ✅ Enable auto-merge on the repository
- ✅ List and enable auto-merge for open PRs
- ✅ Verify workflow configuration

## 📝 What Happens After Setup

### 1. When You Open a PR

The `enable-auto-merge.yml` workflow automatically:
- Enables auto-merge for the PR
- Adds a comment explaining auto-merge status
- Configures the PR to merge when ready

### 2. When Checks Pass

The `auto-merge.yml` workflow automatically:
- Monitors PR status continuously
- Checks for conflicts and review status
- Merges the PR when all requirements are met
- Deletes the source branch after merge

## 🔧 Manual Operations

### Enable auto-merge for a specific PR:
```bash
gh pr merge <PR-number> --auto --merge
```

### Check if auto-merge is enabled:
```bash
gh pr view <PR-number> --json autoMergeRequest
```

### Disable auto-merge:
```bash
gh pr merge <PR-number> --disable-auto
```

## ✅ Requirements for Auto-Merge

PRs will only auto-merge when:
- ✅ Not in draft mode
- ✅ No merge conflicts
- ✅ All status checks pass (if configured)
- ✅ No "changes requested" reviews
- ✅ Branch is up-to-date with base

## 📚 Full Documentation

See [AUTO-MERGE-SETUP-GUIDE.md](AUTO-MERGE-SETUP-GUIDE.md) for:
- Detailed configuration options
- Troubleshooting guides
- Best practices
- Advanced usage

## 🔍 Monitoring

View workflow runs:
```
https://github.com/A6-9V/my-drive-projects/actions
```

## 💡 Tips

1. **Keep PRs small** - Easier to review and merge
2. **Write good descriptions** - Helps reviewers understand changes
3. **Ensure tests pass** - Auto-merge waits for all checks
4. **Keep branch updated** - Prevents merge conflicts

## ❓ Troubleshooting

### Auto-merge not working?

1. Check PR status: `gh pr view <number>`
2. Verify workflows are enabled in repository settings
3. Check Actions tab for workflow errors
4. Ensure you have proper permissions

### Need Help?

- Check [AUTO-MERGE-SETUP-GUIDE.md](AUTO-MERGE-SETUP-GUIDE.md)
- Review workflow logs in Actions tab
- Verify GitHub CLI auth: `gh auth status`

---

**Created for A6-9V/my-drive-projects**

# Repository Cleanup and PR Merge Execution Guide

## Overview

This guide provides step-by-step instructions for cleaning up the A6-9V/my-drive-projects repository by reviewing and merging pull requests, and removing stale branches.

## Current Status

- **Open PRs:** 5 active + 1 tracking
- **Stale Branches:** ~27 branches from completed work
- **Priority Actions:** 2 PRs ready to merge, 2 require review

## Quick Start

### 1. Review Current State

```powershell
# List all open PRs with recommendations
.\review-and-merge-prs.ps1 -Action list

# Review a specific PR
.\review-and-merge-prs.ps1 -Action review -PRNumber 4
```

### 2. Test Branch Cleanup (Dry Run)

```powershell
# See what would be deleted without actually deleting
.\cleanup-stale-branches.ps1 -DryRun:$true
```

### 3. Read the Analysis Report

```powershell
# Open the detailed analysis
notepad BRANCH-CLEANUP-REPORT.md
```

## Phase 1: High-Priority PR Merges

### Step 1.1: Merge PR #4 (Security Critical) ⭐⭐⭐

**Why:** Removes GitHub token from remote URLs, critical security fix

```bash
# Via GitHub CLI
gh pr merge 4 --repo A6-9V/my-drive-projects --merge --delete-branch

# Or via web: https://github.com/A6-9V/my-drive-projects/pull/4
```

**Verification:**
```powershell
git fetch origin main:main
git log main --oneline -5
```

### Step 1.2: Merge PR #3 (Monitoring Feature) ⭐⭐

**Why:** Adds heartbeat monitoring for trading system

```bash
# Via GitHub CLI
gh pr merge 3 --repo A6-9V/my-drive-projects --merge --delete-branch

# Or via web: https://github.com/A6-9V/my-drive-projects/pull/3
```

**Verification:**
```powershell
git fetch origin main:main
git log main --oneline -5
```

## Phase 2: Review Required PRs

### Step 2.1: Review PR #12 (Scheduled Cleanup)

**Status:** Has 59 review comments that need addressing

```bash
# View PR and comments
gh pr view 12 --repo A6-9V/my-drive-projects --comments

# Or via web: https://github.com/A6-9V/my-drive-projects/pull/12
```

**Action Required:**
1. Review all 59 comments
2. Request changes from PR author
3. Wait for updates before merging
4. **DO NOT MERGE** until comments are addressed

### Step 2.2: Review PR #27 (GitHub Secrets)

**Status:** Check for security issues, OAuth credentials in PR description

```bash
# View PR
gh pr view 27 --repo A6-9V/my-drive-projects

# Or via web: https://github.com/A6-9V/my-drive-projects/pull/27
```

**Security Checklist:**
- [ ] Ensure no credentials hardcoded in script files
- [ ] Verify .gitignore includes *.secret files
- [ ] Check that OAuth credentials are only in PR description (not code)
- [ ] Review automation script for security best practices

**Decision:**
- If secure: Merge
- If issues found: Request changes
- If not needed: Close

## Phase 3: Close Meta/Documentation PRs

### Step 3.1: Close PR #26 (PR Review Docs)

**Why:** Documentation PR that served its purpose, meta-documentation

```bash
# Close without merging
gh pr close 26 --repo A6-9V/my-drive-projects

# Or via web: https://github.com/A6-9V/my-drive-projects/pull/26
```

**After Closing:**
```bash
# Delete the branch
git push origin --delete copilot/review-and-merge-pull-requests
```

### Step 3.2: Close PR #28 (Current Tracking PR)

**Why:** This PR has 0 code changes, just tracking the cleanup task

```bash
# Close after cleanup is complete
gh pr close 28 --repo A6-9V/my-drive-projects

# Or via web: https://github.com/A6-9V/my-drive-projects/pull/28
```

## Phase 4: Bulk Branch Cleanup

### Step 4.1: Review Branches to Delete

```powershell
# Dry run to see what would be deleted
.\cleanup-stale-branches.ps1 -DryRun:$true
```

**Expected Output:** List of ~27 stale branches

### Step 4.2: Execute Branch Deletion

```powershell
# Actually delete the stale branches
.\cleanup-stale-branches.ps1 -DryRun:$false
```

**Expected Results:**
- 20-27 branches deleted
- Log file created with deletion details
- Protected branches remain intact

### Step 4.3: Verify Cleanup

```bash
# Check remaining branches
git fetch --all --prune
git branch -r

# Or via GitHub CLI
gh repo view A6-9V/my-drive-projects --json defaultBranchRef,refs
```

## Phase 5: Final Verification

### Step 5.1: Check Repository State

```powershell
# Update local main branch
git fetch origin main:main
git checkout main
git pull origin main

# Verify recent merges
git log --oneline -10

# Count remaining branches
git branch -r | wc -l
```

### Step 5.2: Verify Open PRs

```bash
# List remaining open PRs
gh pr list --repo A6-9V/my-drive-projects

# Expected: 0-2 PRs (only those requiring review)
```

### Step 5.3: Generate Cleanup Summary

```powershell
# Create summary report
$summary = @"
Repository Cleanup Summary
==========================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

PRs Merged:
- PR #4: Security hardening (auto-git-push token fix)
- PR #3: Trading system heartbeat monitoring

PRs Reviewed:
- PR #12: Pending review (59 comments)
- PR #27: Pending security review

PRs Closed:
- PR #26: Meta-documentation (closed)
- PR #28: Tracking PR (closed after cleanup)

Branches Deleted:
- ~27 stale feature branches

Repository Health:
- Main branch: Up to date
- Security: Improved (token removal merged)
- Monitoring: Enhanced (heartbeat added)
- Branch count: Reduced by ~80%

Next Steps:
1. Monitor PR #12 for comment resolution
2. Complete security review of PR #27
3. Continue development on clean main branch
"@

$summary | Out-File "CLEANUP-SUMMARY-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
Write-Host "Summary saved to CLEANUP-SUMMARY-*.txt" -ForegroundColor Green
```

## Rollback Procedures

### If Wrong Branch Deleted

**Note:** GitHub retains deleted branches for 30 days

```bash
# Restore from PR page
# 1. Go to PR associated with branch
# 2. Click "Restore branch" button

# Or recreate from commit SHA
git push origin <commit-sha>:refs/heads/<branch-name>
```

### If Wrong PR Merged

```bash
# Revert the merge commit
git revert -m 1 <merge-commit-sha>
git push origin main
```

## Success Criteria

✅ **Completed when:**
- [ ] PR #4 merged (security)
- [ ] PR #3 merged (monitoring)
- [ ] PR #12 reviewed and action taken
- [ ] PR #27 reviewed and action taken
- [ ] PR #26 closed
- [ ] PR #28 closed (this one)
- [ ] 20+ stale branches deleted
- [ ] Cleanup summary generated
- [ ] Repository is navigable with < 10 branches

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `review-and-merge-prs.ps1` | Review and merge PRs | `.\review-and-merge-prs.ps1 -Action list` |
| `cleanup-stale-branches.ps1` | Delete stale branches | `.\cleanup-stale-branches.ps1 -DryRun:$false` |
| `BRANCH-CLEANUP-REPORT.md` | Detailed analysis | Read for background info |

## Safety Notes

1. **Dry Run First:** Always test with `-DryRun:$true` before actual deletion
2. **30-Day Recovery:** GitHub keeps deleted branches for 30 days
3. **PR History:** Preserved even after branch deletion
4. **Protected Branches:** Script explicitly protects active PR branches
5. **Backup:** All branch SHAs are in git history and PR pages

## Troubleshooting

### Issue: "Branch not found"
**Solution:** Branch may already be deleted or not exist on remote
```bash
git fetch --all --prune
```

### Issue: "Permission denied"
**Solution:** Ensure you have write access to repository
```bash
gh auth status
```

### Issue: "Merge conflict"
**Solution:** Resolve conflicts before merging
```bash
gh pr view <number> --repo A6-9V/my-drive-projects
# Click "Resolve conflicts" on web interface
```

## Post-Cleanup Maintenance

### Regular Branch Hygiene
```powershell
# Weekly: Check for stale branches
git fetch --all --prune
git branch -r --merged main

# Monthly: Review open PRs
gh pr list --repo A6-9V/my-drive-projects --state all
```

### Branch Naming Convention
- Feature: `feature/description`
- Bugfix: `bugfix/description`
- Cursor Agent: `Cursor/A6-9V/description-hash`
- Copilot: `copilot/description`

---

**Last Updated:** 2025-12-22  
**Repository:** A6-9V/my-drive-projects  
**Task:** Branch cleanup and PR review

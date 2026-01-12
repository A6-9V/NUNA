# GitHub Copilot & Jules Agents: Organization Setup Guide

This guide explains how to enable **GitHub Copilot coding agents** and **Jules (Google)** at the organization level for multiple orgs and personal accounts.

---

## Overview

| Account Type | Copilot Agent Support | Jules Support |
|--------------|----------------------|---------------|
| **Organization (Enterprise)** | ✅ Full support | ✅ Full support |
| **Organization (Team)** | ⚠️ Limited | ⚠️ Limited |
| **Personal Account** | ❌ Business tier only | ❌ Not available |

---

## Prerequisites

Before starting, ensure you have:

- [ ] **Organization Owner/Admin** permissions on each org
- [ ] **GitHub Copilot Enterprise** license (for full agent capabilities)
- [ ] **GitHub CLI** (`gh`) installed and authenticated
- [ ] For Jules: **Google Cloud** project with billing enabled

---

## Part 1: Organization-Level Copilot Setup

### Step 1: Enable Copilot Enterprise

1. Navigate to your organization: `https://github.com/YOUR-ORG`
2. Go to **Settings** → **Copilot**
3. Select **Copilot Enterprise** plan
4. Configure seat assignments (all members or specific teams)

### Step 2: Install the Copilot SWE Agent

Install the agent app at the **organization level** (not per-repo):

```bash
# Install GitHub Copilot coding agent for your organization
gh extension install github/gh-copilot

# Verify installation
gh copilot --version
```

Or install via the GitHub Marketplace:
1. Visit: `https://github.com/apps/copilot-swe-agent`
2. Click **Install** → Select your organization
3. Grant access to **All repositories** (recommended) or select specific repos

### Step 3: Grant Repository Permissions

For agents to create branches and open PRs:

```bash
# Enable Copilot agent on a specific repository
gh api repos/YOUR-ORG/REPO-NAME/copilot \
  -X PATCH \
  -f agent_enabled=true
```

Or via UI:
1. Go to repo **Settings** → **Copilot**
2. Enable **Allow Copilot to make changes**
3. Set permission level to **Write**

---

## Part 2: Jules Agent Setup (Google)

### Step 1: Connect Google Cloud to Your Org

1. Visit: `https://jules.google/org-setup`
2. Sign in with your **Google Workspace admin** account
3. Link to your GitHub organization
4. Authorize required OAuth scopes

### Step 2: Configure Jules Permissions

```yaml
# .github/jules.yml (in each repo or at org level)
jules:
  enabled: true
  permissions:
    - write:code
    - create:pr
  allowed_branches:
    - feature/*
    - fix/*
    - jules/*
```

---

## Part 3: Multi-Organization Strategy

For users managing **multiple organizations**:

```
┌─────────────────────────────────────────────────────────────┐
│  Org 1 (Primary)                                            │
│  ├── Copilot Enterprise ✅                                  │
│  ├── Jules Agent ✅                                         │
│  └── All repos inherit agent access                         │
├─────────────────────────────────────────────────────────────┤
│  Org 2 (Secondary)                                          │
│  ├── Copilot Enterprise ✅                                  │
│  ├── Jules Agent ✅                                         │
│  └── Same setup as Org 1                                    │
├─────────────────────────────────────────────────────────────┤
│  Personal Account                                           │
│  ├── Copilot Business only (no Enterprise agents)          │
│  └── Manual PR workflow                                     │
└─────────────────────────────────────────────────────────────┘
```

### Quick Setup Commands for Multiple Orgs

```bash
# Set your orgs
ORG1="your-primary-org"
ORG2="your-secondary-org"

# Enable Copilot for both orgs
for ORG in $ORG1 $ORG2; do
  echo "Enabling Copilot for $ORG..."
  gh api orgs/$ORG/copilot/billing \
    -X PATCH \
    -f plan="enterprise"
done
```

---

## Part 4: Branch Protection (Critical for Security)

> ⚠️ **IMPORTANT**: Agents should **never** push directly to `main`/`master`.

### Required Branch Protection Rules

Configure these rules on your default branch:

| Rule | Setting | Purpose |
|------|---------|---------|
| Require pull request | ✅ Enabled | Agents must use PRs |
| Required reviewers | 1+ humans | Human approval gate |
| Dismiss stale approvals | ✅ Enabled | Re-review after changes |
| Restrict pushes | Admins only | Prevent direct commits |
| Require status checks | ✅ Enabled | CI must pass |

### Setup via GitHub CLI

```bash
# Apply branch protection to main branch
gh api repos/YOUR-ORG/REPO-NAME/branches/main/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  -f restrictions='{"users":[],"teams":[]}' \
  -f required_status_checks='{"strict":true,"contexts":["ci"]}'
```

### Agent Workflow Diagram

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Agent   │───▶│  Branch  │───▶│   PR     │───▶│  Review  │
│  Works   │    │ feature/ │    │ Created  │    │  Human   │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                      │
                                                      ▼
                                               ┌──────────┐
                                               │  Merge   │
                                               │  to main │
                                               └──────────┘
```

**Result**: Agents work on feature branches → Humans review and approve → Controlled merges to main.

---

## Part 5: Quick Reference Commands

### Copilot Agent Commands

```bash
# Check Copilot status for an org
gh api orgs/YOUR-ORG/copilot/billing

# List repos with Copilot enabled
gh api orgs/YOUR-ORG/copilot/repos --paginate

# Enable agent on specific repo
gh api repos/YOUR-ORG/REPO-NAME/copilot -X PATCH -f agent_enabled=true
```

### Monitoring Agent Activity

```bash
# View recent PRs created by Copilot agent
gh pr list --author="app/copilot-swe-agent" --state=all

# Check agent workflow runs
gh run list --workflow=copilot-agent.yml
```

---

## Troubleshooting

### Agent Not Creating PRs

1. **Check permissions**: Ensure agent has `write` access to the repo
2. **Verify installation**: Agent must be installed at org level
3. **Branch protection**: Ensure feature branches are not protected

### Agent PRs Failing CI

1. Review the agent's code changes carefully
2. Provide clearer instructions in your prompt
3. Consider adding a `.github/copilot-instructions.md` file

### Rate Limits

- Enterprise: 500 agent requests/hour/org
- Team: 100 agent requests/hour/org

---

## Security Best Practices

1. ✅ **Never disable branch protection** for agents
2. ✅ **Require human review** on all agent PRs
3. ✅ **Use allowlists** for sensitive repos
4. ✅ **Audit agent activity** regularly via GitHub audit log
5. ✅ **Rotate credentials** used by agents periodically

---

## Additional Resources

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Copilot Coding Agent Tips](https://gh.io/copilot-coding-agent-tips)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [Jules Agent Setup](https://jules.google/docs)

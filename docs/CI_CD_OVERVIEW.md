# CI/CD Pipeline Overview

## Workflow Triggers and Flow

```mermaid
graph TB
    Start([Developer Activity]) --> Push{Event Type}
    
    Push -->|Push to Branch| CI[CI Workflow]
    Push -->|Pull Request| PR[PR Workflows]
    Push -->|Tag v*.*.*| Release[Release Workflow]
    Push -->|Schedule/Manual| Scheduled[Scheduled Workflows]
    
    CI --> PythonTests[Python Tests & Lint]
    CI --> DockerBuild[Docker Build & Test]
    
    PR --> PythonTests
    PR --> DockerBuild
    PR --> Security[Security Scan]
    PR --> Quality[Code Quality]
    PR --> Labeler[Auto Label PR]
    PR --> Docs[Documentation Checks]
    
    Security --> CodeQL[CodeQL Analysis]
    Security --> DepScan[Dependency Scan]
    Security --> ContainerScan[Container Scan]
    Security --> SecretScan[Secret Scan]
    
    Quality --> Coverage[Test Coverage]
    Quality --> Complexity[Code Complexity]
    Quality --> Style[Code Style]
    
    Docs --> LinkCheck[Link Validation]
    Docs --> MDLint[Markdown Lint]
    Docs --> Spell[Spell Check]
    
    PythonTests --> Merge{All Checks Pass?}
    DockerBuild --> Merge
    Security --> Merge
    Quality --> Merge
    Docs --> Merge
    
    Merge -->|Yes| Deploy[Deploy Workflow]
    Merge -->|No| Fail[Fix Issues]
    
    Deploy --> BuildImage[Build Docker Image]
    BuildImage --> PushGHCR[Push to GHCR]
    PushGHCR --> Done([Deployed])
    
    Release --> CreateRelease[Create GitHub Release]
    Release --> MultiArch[Multi-Arch Build]
    MultiArch --> PushRelease[Push Tagged Images]
    PushRelease --> Done
    
    Scheduled --> WeeklySecurity[Weekly Security Scan]
    Scheduled --> WeeklyDocs[Weekly Link Check]
    Scheduled --> DailyStale[Daily Stale Check]
    Scheduled --> WeeklyDeps[Weekly Dependabot]
    
    Fail --> Fix[Update Code]
    Fix --> Start
    
    style CI fill:#e1f5ff
    style Security fill:#ffe1e1
    style Quality fill:#fff4e1
    style Deploy fill:#e1ffe1
    style Release fill:#f0e1ff
    style Scheduled fill:#fff0f5

```bash

## Workflow Status Badges

Add these to your README.md:

```markdown
[![CI](https://github.com/A6-9V/NUNA/actions/workflows/ci.yml/badge.svg)](https://github.com/A6-9V/NUNA/actions/workflows/ci.yml)
[![Security Scanning](https://github.com/A6-9V/NUNA/actions/workflows/security.yml/badge.svg)](https://github.com/A6-9V/NUNA/actions/workflows/security.yml)
[![Code Quality](https://github.com/A6-9V/NUNA/actions/workflows/code-quality.yml/badge.svg)](https://github.com/A6-9V/NUNA/actions/workflows/code-quality.yml)
[![Deploy](https://github.com/A6-9V/NUNA/actions/workflows/deploy.yml/badge.svg)](https://github.com/A6-9V/NUNA/actions/workflows/deploy.yml)

```bash

## Workflow Summary

| Workflow | Frequency | Duration (Avg) | Purpose |
|----------|-----------|----------------|---------|
| CI | On Push/PR | ~3-5 min | Test & Build |
| Security | Weekly + PR | ~8-12 min | Security Scan |
| Code Quality | On Push/PR | ~5-7 min | Quality Checks |
| Deploy | On Main Push | ~4-6 min | Deploy Images |
| Release | On Tag | ~8-10 min | Create Release |
| Documentation | Weekly + Changes | ~2-3 min | Validate Docs |
| Stale | Daily | ~1-2 min | Clean Up |
| Dependabot | Weekly | N/A | Update Deps |

## Permissions Required

### Workflows

- `contents: read` - Read repository content
- `contents: write` - Create releases, update files
- `packages: write` - Push to GitHub Container Registry
- `security-events: write` - Upload security scan results
- `pull-requests: write` - Comment on PRs, apply labels
- `issues: write` - Create issues, manage stale items
- `actions: read` - Read workflow data

### Repository Settings
Enable in Settings → Actions:

- ✅ Allow GitHub Actions
- ✅ Allow actions created by GitHub
- ✅ Allow specified actions (if using restrictive policy)
- ✅ Read and write permissions for GITHUB_TOKEN

### Required Secrets
None required! All workflows use `secrets.GITHUB_TOKEN` which is automatically
provided.

### Optional Secrets (for enhanced features)

- `VPS_SSH_KEY` - For automated VPS deployment
- `SLACK_WEBHOOK` - For deployment notifications
- `CODECOV_TOKEN` - For codecov.io integration

## Workflow Dependencies

```bash
┌─────────────────┐
│   Dependabot    │
│  (Weekly Auto)  │
└────────┬────────┘
         │
    ┌────▼────────────────────┐
    │  Security Scan Updates  │
    │   Dependencies Daily     │
    └────────┬────────────────┘
             │
    ┌────────▼────────┐
    │   CI Pipeline   │
    │  (Every Push)   │
    └────────┬────────┘
             │
    ┌────────▼──────────┐
    │  Code Quality &   │
    │  Documentation    │
    └────────┬──────────┘
             │
    ┌────────▼────────┐
    │  Deploy / Release│
    │  (Main/Tags)    │
    └─────────────────┘

```bash

## Cost Optimization

### Strategies Used

1. **Caching**
   - Docker layer caching with GitHub Actions cache
   - Python pip dependency caching
   - Reduces build time by 60-80%

2. **Conditional Execution**

   - Documentation checks only on doc changes
   - Security scans on schedule for non-PR runs
   - Deployment only on main branch

3. **Parallel Jobs**

   - Security scans run in parallel
   - Quality checks run concurrently
   - Reduces overall pipeline time

4. **Efficient Scheduling**

   - Weekly scans instead of daily
   - Stale check during low-usage hours
   - Dependabot batches updates

### Estimated Monthly Usage

- CI runs: ~300-500 runs/month
- Security scans: ~10-15 runs/month
- Quality checks: ~200-300 runs/month
- Total: ~2,000-3,000 minutes/month

**Note:** Private repos have 2,000-3,000 free minutes/month depending on plan.

## Maintenance Schedule

### Weekly

- [ ] Review security scan results
- [ ] Check Dependabot PRs
- [ ] Monitor workflow success rates

### Monthly

- [ ] Review and update workflow configurations
- [ ] Check for action version updates
- [ ] Audit workflow permissions

### Quarterly

- [ ] Review caching strategies
- [ ] Optimize slow workflows
- [ ] Update documentation

---

For detailed workflow documentation, see
[CI_CD_DOCUMENTATION.md](CI_CD_DOCUMENTATION.md)

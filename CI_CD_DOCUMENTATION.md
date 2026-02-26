# CI/CD Workflows Documentation

This document describes all the continuous integration and deployment workflows configured for the NUNA repository.

## Table of Contents

1. [CI Workflow](#ci-workflow)
2. [Deployment Workflow](#deployment-workflow)
3. [Security Scanning Workflow](#security-scanning-workflow)
4. [Code Quality Workflow](#code-quality-workflow)
5. [Release Workflow](#release-workflow)
6. [PR Labeler Workflow](#pr-labeler-workflow)
7. [Documentation Workflow](#documentation-workflow)
8. [Stale Issues/PRs Workflow](#stale-issuesprs-workflow)
9. [Dependabot Configuration](#dependabot-configuration)

---

## CI Workflow

**File:** `.github/workflows/ci.yml`

**Triggers:**
- Push to `main`, `copilot/**`, `cursor/**`, `bolt/**` branches
- Pull requests to `main`

**Jobs:**
1. **Python Tests** - Runs Python tests, linting, and CLI smoke tests
   - Python 3.12
   - Flake8 linting (syntax errors fail build)
   - Syntax checking with compileall
   - Unit tests with unittest
   - CLI smoke tests for gdrive_cleanup and trading_data_manager
   
2. **Docker Build & Test** - Builds and tests Docker image
   - Builds Docker image with Buildx
   - Tests image with basic commands
   - Uses GitHub Actions cache for faster builds

**What it validates:**
- ✅ Python code syntax and style
- ✅ Unit tests pass
- ✅ CLI commands work
- ✅ Docker image builds successfully

---

## Deployment Workflow

**File:** `.github/workflows/deploy.yml`

**Triggers:**
- Push to `main` branch
- Tags matching `v*` pattern
- Manual workflow dispatch with environment selection

**Jobs:**
1. **Build & Deploy Docker Image** - Builds and pushes to GitHub Container Registry
   - Multi-tag Docker images
   - Semantic versioning support
   - Deployment summary with pull commands
   
2. **Deploy to VPS** - Automated or manual VPS deployment
   - **Automated Mode** (when secrets configured):
     - Sets up SSH connection using SSH key
     - Runs deployment script (`scripts/deploy-vps.sh`)
     - Automatically deploys to configured VPS
     - Provides deployment summary
   - **Manual Mode** (when secrets not configured):
     - Provides setup instructions for automated deployment
     - Shows manual deployment commands
   - Only runs for main branch
   - Requires `VPS_DEPLOYMENT_ENABLED` variable set to `true`

**Required Secrets for Automated Deployment:**
- `VPS_HOST` - VPS hostname or IP address
- `VPS_USER` - SSH username for VPS access
- `VPS_SSH_KEY` - Private SSH key for authentication
- `VPS_DEPLOY_PATH` - Deployment path on VPS (optional, defaults to `/opt/nuna`)

**Required Variables:**
- `VPS_DEPLOYMENT_ENABLED` - Set to `true` to enable automated VPS deployment

**Concurrency:** Prevents multiple simultaneous deployments

**What it does:**
- 🚀 Builds production Docker images
- 📦 Pushes to ghcr.io
- 🔄 Automatically deploys to VPS (when configured)
- 📋 Generates deployment instructions

**VPS Deployment Steps:**
1. ✅ Connects to VPS via SSH
2. ✅ Creates deployment directory
3. ✅ Copies configuration files
4. ✅ Installs Docker and Docker Compose (if needed)
5. ✅ Pulls latest Docker image
6. ✅ Stops existing containers
7. ✅ Starts new containers
8. ✅ Verifies deployment

For detailed VPS deployment documentation, see [VPS_DEPLOYMENT.md](../VPS_DEPLOYMENT.md).

---

## Security Scanning Workflow

**File:** `.github/workflows/security.yml`

**Triggers:**
- Push to main and feature branches
- Pull requests to main
- Weekly schedule (Mondays at 9:00 AM UTC)
- Manual workflow dispatch

**Jobs:**
1. **CodeQL Analysis** - Advanced semantic code analysis
   - Scans Python and JavaScript code
   - Security and quality queries
   - Results uploaded to GitHub Security tab
   
2. **Python Dependency Scan** - Check for vulnerable dependencies
   - Uses pip-audit
   - Generates JSON audit reports
   - Uploads artifacts for review
   
3. **Docker Image Security Scan** - Container vulnerability scanning
   - Uses Trivy scanner
   - Scans for CRITICAL, HIGH, and MEDIUM vulnerabilities
   - Results uploaded to GitHub Security tab
   
4. **Secret Scan** - Detect accidentally committed secrets
   - Uses TruffleHog
   - Scans entire git history
   - Only reports verified secrets
   
5. **Security Summary** - Consolidates all security check results

**What it protects against:**
- 🔒 Code vulnerabilities
- 📦 Vulnerable dependencies
- 🐳 Container vulnerabilities
- 🔑 Leaked secrets

---

## Code Quality Workflow

**File:** `.github/workflows/code-quality.yml`

**Triggers:**
- Push to main and feature branches
- Pull requests to main

**Jobs:**
1. **Test Coverage Report** - Measures test coverage
   - Uses coverage.py and pytest-cov
   - Generates HTML coverage reports
   - Posts coverage comments on PRs
   - Minimum thresholds: 70% green, 50% orange
   
2. **Code Complexity Analysis** - Analyzes code maintainability
   - Cyclomatic complexity with radon
   - Maintainability index calculation
   - Checks complexity thresholds
   
3. **Code Style Check** - Enforces consistent code style
   - Black formatter checking
   - isort import sorting
   - PEP8 style validation
   
4. **Quality Summary** - Consolidates all quality check results

**What it measures:**
- 📊 Test coverage percentage
- 🧮 Code complexity metrics
- 🎨 Code style consistency
- 🔧 Maintainability scores

---

## Release Workflow

**File:** `.github/workflows/release.yml`

**Triggers:**
- Tags matching `v*.*.*` pattern (e.g., v1.0.0)
- Manual workflow dispatch with version input

**Jobs:**
1. **Create Release** - Creates GitHub release
   - Generates changelog from commits
   - Creates release notes
   - Marks pre-releases (versions with `-` like v1.0.0-beta)
   
2. **Build & Push Release Images** - Multi-architecture Docker builds
   - Builds for linux/amd64 and linux/arm64
   - Tags with semantic versioning
   - Tags latest for stable releases
   - Pushes to GitHub Container Registry

**Semantic Versioning Tags:**
- `v1.2.3` → tags: `1.2.3`, `1.2`, `1`, `latest`
- `v1.2.3-beta` → tags: `1.2.3-beta` (no latest)

**What it automates:**
- 🏷️ Release creation
- 📝 Changelog generation
- 🐳 Multi-arch Docker builds
- 📦 Version tagging

---

## PR Labeler Workflow

**File:** `.github/workflows/pr-labeler.yml`  
**Config:** `.github/labeler.yml`

**Triggers:**
- Pull request opened, synchronized, or reopened

**Automatic Labels:**
- `documentation` - Changes to *.md files, docs/, guidebook/
- `docker` - Changes to Dockerfile, docker-compose files
- `python` - Changes to *.py files, requirements.txt
- `testing` - Changes to test files
- `ci-cd` - Changes to .github/ files
- `configuration` - Changes to config files (JSON, YAML, env)
- `scripts` - Changes to PowerShell, Batch, Shell scripts
- `security` - Changes to security-related files

**What it does:**
- 🏷️ Auto-labels PRs based on file changes
- 📋 Makes PR organization easier
- 🔍 Improves PR discoverability

---

## Documentation Workflow

**File:** `.github/workflows/documentation.yml`

**Triggers:**
- Push to main with documentation changes
- Pull requests with documentation changes
- Weekly schedule (Sundays at 2:00 AM UTC)
- Manual workflow dispatch

**Jobs:**
1. **Link Checker** - Validates all links in markdown files
   - Uses lychee link checker
   - Excludes localhost and local IPs
   - Creates issues for broken links (scheduled runs)
   
2. **Markdown Lint** - Ensures markdown formatting consistency
   - Uses markdownlint-cli2
   - Checks all *.md files
   
3. **Spell Check** - Catches typos and misspellings
   - Checks spelling in documentation
   - Uses custom dictionary if configured
   
4. **Documentation Summary** - Consolidates check results

**What it validates:**
- 🔗 All links work correctly
- 📝 Markdown follows style rules
- ✍️ Spelling is correct
- 📚 Documentation quality

---

## Stale Issues/PRs Workflow

**File:** `.github/workflows/stale.yml`

**Triggers:**
- Daily schedule (1:00 AM UTC)
- Manual workflow dispatch

**Configuration:**

**Issues:**
- Marked stale after 60 days of inactivity
- Closed 7 days after marked stale
- Exempt labels: `pinned`, `security`, `enhancement`

**Pull Requests:**
- Marked stale after 30 days of inactivity
- Closed 7 days after marked stale
- Exempt labels: `pinned`, `security`, `in-progress`

**What it does:**
- 🧹 Keeps issue tracker clean
- ⏰ Automatically closes inactive items
- 💬 Adds helpful messages before closing
- 🔄 Removes stale label when updated

---

## Dependabot Configuration

**File:** `.github/dependabot.yml`

**Update Schedule:** Weekly on Mondays at 9:00 AM UTC

**Ecosystems Monitored:**
1. **Python (pip)** - Python package dependencies
   - Groups minor and patch updates
   - Max 5 open PRs
   
2. **GitHub Actions** - Workflow action versions
   - Max 3 open PRs
   
3. **Docker** - Base image updates
   - Max 3 open PRs

**PR Configuration:**
- Commit prefix: `chore(deps)`
- Auto-assigned reviewers
- Labeled with `dependencies` + ecosystem label
- Grouped updates for efficiency

**What it does:**
- 🔄 Automatically updates dependencies
- 🔒 Keeps security patches current
- 📦 Groups related updates
- 🤖 Reduces manual dependency management

---

## Workflow Integration

All workflows are designed to work together:

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Push/PR                         │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
   ┌────▼────┐ ┌───▼────┐ ┌──▼─────────┐
   │   CI    │ │Security│ │Code Quality│
   │ Tests   │ │ Scan   │ │  Checks    │
   └────┬────┘ └───┬────┘ └──┬─────────┘
        │          │          │
        └──────────┼──────────┘
                   │
              ┌────▼────┐
              │   PR    │
              │ Review  │
              └────┬────┘
                   │
              ┌────▼────┐
              │  Merge  │
              │ to Main │
              └────┬────┘
                   │
         ┌─────────┴─────────┐
         │                   │
    ┌────▼────┐         ┌────▼────┐
    │ Deploy  │         │ Release │
    │to GHCR  │         │(on tag) │
    └─────────┘         └─────────┘
```

---

## Best Practices

### For Contributors

1. **Before pushing:**
   - Run tests locally: `python -m unittest discover -s . -p "test_*.py"`
   - Check linting: `flake8 .`
   - Verify changes build: `docker build -t test .`

2. **During PR:**
   - Wait for all CI checks to pass
   - Address security findings immediately
   - Review coverage reports
   - Check auto-applied labels

3. **After merge:**
   - Monitor deployment workflow
   - Verify Docker image pushed successfully
   - Check VPS deployment status (if enabled)

### For Maintainers

1. **Security:**
   - Review security scan results weekly
   - Address critical vulnerabilities immediately
   - Keep dependencies up to date

2. **Releases:**
   - Use semantic versioning
   - Tag releases: `git tag v1.0.0 && git push --tags`
   - Review generated changelog before release

3. **Maintenance:**
   - Review Dependabot PRs promptly
   - Keep workflows up to date
   - Monitor workflow usage and costs

4. **VPS Deployment:**
   - Configure VPS secrets for automated deployment
   - Test deployment script locally before enabling
   - Monitor VPS resources and container health
   - Keep VPS system and Docker updated
   - Backup VPS data regularly

---

## Troubleshooting

### Workflow Failures

**CI Tests Failing:**
```bash
# Run locally
python -m unittest discover -s . -p "test_*.py" -v
flake8 . --exclude=.venv,venv,ENV,__pycache__,.git
```

**Security Scan Failing:**
- Check CodeQL alerts in Security tab
- Review Trivy scan results
- Update vulnerable dependencies

**Docker Build Failing:**
```bash
# Test locally
docker build -t nuna-tools:test .
docker run --rm nuna-tools:test python --version
```

**Release Workflow Issues:**
- Ensure tag follows `v*.*.*` pattern
- Verify GITHUB_TOKEN has packages:write permission
- Check Docker registry login

**VPS Deployment Failing:**
```bash
# Test SSH connection
ssh -v $VPS_USER@$VPS_HOST

# Test deployment script locally
export VPS_HOST="your-vps"
export VPS_USER="your-user"
bash -x scripts/deploy-vps.sh

# Check GitHub Actions secrets are configured
# Required: VPS_HOST, VPS_USER, VPS_SSH_KEY
# Variable: VPS_DEPLOYMENT_ENABLED=true
```

For detailed VPS troubleshooting, see [VPS_DEPLOYMENT.md](../VPS_DEPLOYMENT.md#troubleshooting).

### Getting Help

- Check workflow run logs in Actions tab
- Review security findings in Security tab
- Consult specific workflow documentation above

---

## Configuration Files

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | Continuous integration |
| `.github/workflows/deploy.yml` | Deployment automation |
| `.github/workflows/security.yml` | Security scanning |
| `.github/workflows/code-quality.yml` | Code quality checks |
| `.github/workflows/release.yml` | Release automation |
| `.github/workflows/pr-labeler.yml` | PR auto-labeling |
| `.github/workflows/documentation.yml` | Documentation validation |
| `.github/workflows/stale.yml` | Stale item management |
| `.github/dependabot.yml` | Dependency updates |
| `.github/labeler.yml` | PR label configuration |
| `scripts/deploy-vps.sh` | VPS deployment script |
| `docker-compose.vps.yml` | VPS-optimized Docker Compose config |
| `.env.vps.example` | VPS environment variables template |

## Related Documentation

- [VPS Deployment Guide](../VPS_DEPLOYMENT.md) - Complete VPS deployment documentation
- [VPS Hosting Configuration](../VPS_HOSTING.md) - VPS server details and management
- [README](../README.md) - Main project documentation

---

**Last Updated:** 2026-02-05  
**Maintained by:** NUNA Contributors

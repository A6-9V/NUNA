# GitLab CI/CD Pipeline Setup Guide

This document describes the GitLab CI/CD pipeline configuration for the NUNA MetaTrader 5 Trading System.

## Overview

The GitLab pipeline automates testing, building, security scanning, and deployment of the NUNA trading tools and Docker containers. It mirrors the functionality of the GitHub Actions workflows while leveraging GitLab-specific features.

## Pipeline Stages

The pipeline consists of 5 main stages that run sequentially:

```
validate → analyze → containerize → security_audit → publish
```

### 1. Validate Phase

**Purpose:** Ensure code quality and functionality before proceeding

**Jobs:**
- `verify_python_syntax` - Validates Python syntax across all modules
- `lint_codebase` - Runs Flake8 linter with strict error checking
- `execute_unit_tests` - Runs the full unit test suite
- `verify_cli_tools` - Tests all CLI command interfaces

**Duration:** ~3-5 minutes

### 2. Analyze Phase

**Purpose:** Assess code quality metrics and test coverage

**Jobs:**
- `measure_test_coverage` - Generates test coverage reports with HTML output
- `assess_code_complexity` - Analyzes cyclomatic complexity and maintainability

**Duration:** ~2-3 minutes

### 3. Containerize Phase

**Purpose:** Build and test Docker containers

**Jobs:**
- `build_trading_container` - Builds the Docker image with build metadata
- `test_trading_container` - Validates container functionality

**Duration:** ~4-6 minutes

### 4. Security Audit Phase

**Purpose:** Identify security vulnerabilities

**Jobs:**
- `scan_python_dependencies` - Audits Python packages with pip-audit
- `scan_container_vulnerabilities` - Scans Docker image with Trivy
- `detect_secrets` - Searches for exposed secrets with TruffleHog

**Duration:** ~5-8 minutes

**Note:** Security jobs are set to `allow_failure: true` to prevent blocking deployments for minor issues.

### 5. Publish Phase

**Purpose:** Deploy containers to GitLab Container Registry

**Jobs:**
- `deploy_to_registry` - Publishes latest image (main branch only)
- `release_versioned_image` - Creates versioned releases (tags only)

**Duration:** ~2-4 minutes

## Configuration Details

### Variables

The pipeline uses several environment variables:

| Variable | Purpose | Default |
|----------|---------|---------|
| `PYTHON_EXEC` | Python executable | `python3.12` |
| `PROJECT_IMAGE` | Container image name | `$CI_REGISTRY_IMAGE/nuna-trading-tools` |
| `DOCKER_DRIVER` | Docker storage driver | `overlay2` |
| `PIP_CACHE_DIR` | Pip cache location | `$CI_PROJECT_DIR/.cache/pip` |

### Caching Strategy

The pipeline implements intelligent caching to speed up builds:

**Python Dependencies:**
```yaml
cache:
  key: pip-deps-$CI_COMMIT_REF_SLUG
  paths:
    - .cache/pip
```

**Docker Layers:**
- Uses `--cache-from` to leverage previous builds
- Significantly reduces build times (60-80% faster)

### Artifacts

Pipeline jobs produce various artifacts:

| Job | Artifact | Retention | Purpose |
|-----|----------|-----------|---------|
| `lint_codebase` | `flake8_report.txt` | 1 week | Linting results |
| `measure_test_coverage` | `htmlcov/`, `coverage.json` | 1 month | Coverage reports |
| `assess_code_complexity` | Complexity JSONs | 1 month | Maintainability metrics |
| `build_trading_container` | `nuna-image.tar` | 1 day | Docker image |
| `scan_python_dependencies` | `pip-audit-report.json` | 1 month | Security audit |
| `scan_container_vulnerabilities` | `trivy-report.json` | 1 month | Container scan |
| `detect_secrets` | `secrets-scan.json` | 1 week | Secret detection |

## Getting Started

### Prerequisites

1. **GitLab Repository** - Your NUNA project must be hosted on GitLab
2. **GitLab Runner** - At least one runner with Docker executor enabled
3. **Container Registry** - GitLab Container Registry enabled for your project

### Enabling the Pipeline

The pipeline is automatically enabled once `.gitlab-ci.yml` exists in your repository root. It will trigger on:

- **Push to any branch** - Runs validation, analysis, containerization, and security stages
- **Push to main/master** - Also runs deployment to registry
- **Git tags** (v*.*.*) - Triggers versioned release

### Required GitLab Settings

Navigate to **Settings → CI/CD** and configure:

#### Variables

No custom variables are required! The pipeline uses built-in GitLab variables:
- `CI_REGISTRY` - GitLab Container Registry URL
- `CI_REGISTRY_USER` - Registry username (automatically provided)
- `CI_REGISTRY_PASSWORD` - Registry password (automatically provided)
- `CI_COMMIT_TAG` - Git tag name (when triggered by tag)

#### Optional Variables

For enhanced features, you can add:
- `NOTIFICATION_WEBHOOK` - Slack/Teams webhook for notifications
- `VPS_DEPLOY_ENABLED` - Set to `true` to enable VPS deployment

#### Runners

Ensure you have runners with these tags:
- Docker executor support
- At least 2GB RAM
- Sufficient disk space for Docker builds

## Pipeline Workflow

### For Feature Branches

```
git push origin feature/my-feature
  ↓
Runs: validate → analyze → containerize → security_audit
  ↓
All jobs must pass before merge
```

### For Main Branch

```
git push origin main
  ↓
Runs: All stages including publish
  ↓
Deploys latest image to registry
```

### For Tagged Releases

```
git tag v1.2.3
git push origin v1.2.3
  ↓
Runs: All stages
  ↓
Creates versioned images:
  - v1.2.3
  - 1.2.3
  - 1.2
  - 1
  - stable
```

## Using the Container Images

### Pull Latest Image

```bash
docker login registry.gitlab.com
docker pull $CI_REGISTRY_IMAGE/nuna-trading-tools:latest
```

### Pull Specific Version

```bash
docker pull $CI_REGISTRY_IMAGE/nuna-trading-tools:v1.2.3
docker pull $CI_REGISTRY_IMAGE/nuna-trading-tools:1.2
docker pull $CI_REGISTRY_IMAGE/nuna-trading-tools:stable
```

### Run Trading Tools

```bash
# Run gdrive cleanup
docker run --rm \
  -v $(pwd):/workspace \
  $CI_REGISTRY_IMAGE/nuna-trading-tools:latest \
  python gdrive_cleanup.py --help

# Run trading data manager
docker run --rm \
  -v $(pwd):/workspace \
  $CI_REGISTRY_IMAGE/nuna-trading-tools:latest \
  python trading_data_manager.py --help
```

## Monitoring Pipeline

### View Pipeline Status

1. Navigate to **CI/CD → Pipelines**
2. Click on a pipeline to see job details
3. Click on a job to view logs

### Pipeline Badges

Add these badges to your README.md:

```markdown
[![Pipeline Status](https://gitlab.com/<your-namespace>/NUNA/badges/main/pipeline.svg)](https://gitlab.com/<your-namespace>/NUNA/-/pipelines)
[![Coverage Report](https://gitlab.com/<your-namespace>/NUNA/badges/main/coverage.svg)](https://gitlab.com/<your-namespace>/NUNA/-/graphs/main/charts)
```

### Artifacts Access

1. Go to **CI/CD → Pipelines**
2. Click on the pipeline
3. Click the download button next to jobs with artifacts
4. Or use the "Browse" button to view artifacts online

## Troubleshooting

### Pipeline Fails on First Run

**Symptom:** Pipeline fails with Docker login errors

**Solution:** 
1. Ensure Container Registry is enabled: **Settings → General → Visibility → Container Registry**
2. Check runner has Docker executor configured
3. Verify `$CI_REGISTRY_USER` and `$CI_REGISTRY_PASSWORD` are available

### Python Tests Fail

**Symptom:** Unit tests or CLI tests fail

**Solution:**
1. Run tests locally: `python -m unittest discover -s . -p "test_*.py"`
2. Check Python version matches (3.12)
3. Verify all dependencies in requirements.txt are correct

### Docker Build Fails

**Symptom:** Container build errors

**Solution:**
1. Test locally: `docker build -t test .`
2. Check Dockerfile exists and is valid
3. Ensure runner has sufficient disk space
4. Clear Docker cache if needed

### Security Scans Report Issues

**Symptom:** Security jobs flag vulnerabilities

**Solution:**
1. Review the artifact reports (JSON files)
2. Update vulnerable dependencies in requirements.txt
3. Security jobs won't block deployment (allow_failure: true)
4. Address critical issues promptly

### Slow Pipeline Execution

**Symptom:** Pipeline takes too long

**Solution:**
1. Check cache is working (look for "cache hit" in logs)
2. Ensure runners are not overloaded
3. Consider adding more runners
4. Review job dependencies for unnecessary waiting

## Performance Optimization

### Caching Best Practices

The pipeline uses caching for:
- Python pip packages (per branch)
- Docker layer caching (when using GitLab Runner cache)

To maximize cache effectiveness:
- Keep requirements.txt stable
- Use specific package versions
- Don't frequently change Dockerfile base image

### Parallel Execution

Jobs within the same stage run in parallel when possible:
- All validate jobs run concurrently
- All security_audit jobs run concurrently
- Requires multiple runners for full parallelization

### Resource Requirements

Recommended runner specifications:
- **CPU:** 2+ cores
- **RAM:** 4GB minimum, 8GB recommended
- **Disk:** 20GB free space for Docker builds
- **Network:** Good internet for pulling images

## Integration with GitHub Actions

This GitLab pipeline complements the existing GitHub Actions workflows:

| Feature | GitHub Actions | GitLab CI/CD |
|---------|----------------|--------------|
| Python Tests | ✅ | ✅ |
| Docker Build | ✅ | ✅ |
| Security Scanning | ✅ CodeQL | ✅ Trivy |
| Code Quality | ✅ | ✅ |
| Container Registry | GHCR | GitLab Registry |
| VPS Deployment | ✅ | 🔄 Configurable |

Both pipelines can run simultaneously, providing redundancy and flexibility.

## Migration from GitHub Only

If moving from GitHub-only to dual platform:

1. ✅ Keep existing GitHub Actions workflows
2. ✅ Add GitLab CI/CD pipeline (this file)
3. ✅ Both will run independently
4. ✅ Choose primary registry (GHCR vs GitLab)
5. ✅ Update deployment scripts to reference correct registry

## Advanced Configuration

### Custom Job Triggers

Add rules to specific jobs:

```yaml
my_job:
  stage: validate
  script:
    - echo "Custom job"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "main"
```

### Matrix Builds

Test multiple Python versions:

```yaml
test_multiple_versions:
  stage: validate
  image: python:${PYTHON_VERSION}
  parallel:
    matrix:
      - PYTHON_VERSION: ["3.10", "3.11", "3.12"]
  script:
    - python -m unittest discover
```

### Scheduled Pipelines

Configure in **CI/CD → Schedules** for:
- Weekly security scans
- Nightly builds
- Periodic cleanup tasks

## Support and Resources

- **GitLab CI/CD Docs:** https://docs.gitlab.com/ee/ci/
- **Docker Executor:** https://docs.gitlab.com/runner/executors/docker.html
- **Container Registry:** https://docs.gitlab.com/ee/user/packages/container_registry/

## Related Documentation

- [CI/CD Overview](CI_CD_OVERVIEW.md) - GitHub Actions overview
- [CI/CD Documentation](CI_CD_DOCUMENTATION.md) - Detailed GitHub workflows
- [VPS Deployment](VPS_DEPLOYMENT.md) - VPS deployment guide
- [README](README.md) - Main project documentation

---

**Last Updated:** 2026-02-05  
**Pipeline Version:** 1.0  
**Maintained by:** NUNA Contributors

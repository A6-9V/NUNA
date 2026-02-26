# GitLab CI/CD Quick Reference

Quick reference for using GitLab CI/CD with the NUNA project on forge.mql5.io.

## Quick Start

### 1. Setup Runner (One-time)

```bash
# Linux/macOS
./scripts/setup-gitlab-runner.sh

# Windows PowerShell (as Administrator)
# Follow instructions in GITLAB_RUNNER_SETUP.md
```

### 2. Push Code

```bash
# Push to forge.mql5.io
git push forge main

# Or push to both GitHub and forge
git push origin main
git push forge main
```

### 3. View Pipeline

Visit: https://forge.mql5.io/LengKundee/NUNA/-/pipelines

## Runner Token

**⚠️ SECURITY WARNING**: Treat this as sensitive information.

```
d7tzwkGG974FKv6zb5m9IO4xHy99Br6cZPuCddwN
```

**Security**: This token is used to register runners. Keep it secure. Consider using environment variable `GITLAB_RUNNER_TOKEN` when using the setup script.

## Pipeline Stages

1. **setup** - Install dependencies
2. **test** - Run linting, syntax checks, and unit tests
3. **build** - Build Docker images
4. **deploy** - Deploy to production (manual)

## Common Commands

### View Runner Status

```bash
sudo gitlab-runner status
```

### Start/Stop Runner

```bash
sudo gitlab-runner start
sudo gitlab-runner stop
sudo gitlab-runner restart
```

### View Runner Logs

```bash
sudo gitlab-runner --debug run
```

### List Registered Runners

```bash
sudo gitlab-runner list
```

### Verify Runner Configuration

```bash
sudo gitlab-runner verify
```

## Pipeline Jobs

### Automatic Jobs

- `setup` - Environment setup
- `lint` - Python linting with flake8
- `syntax-check` - Compile all Python files
- `unit-tests` - Run unittest suite
- `cli-tests` - Test CLI commands
- `integration-tests` - Integration tests
- `docker-build` - Build Docker image

### Manual Jobs

- `deploy` - Deploy to production (requires manual trigger)

## Running Python Code

### Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
python -m unittest discover -s . -p "test_*.py" -v

# Run CLI tools
python gdrive_cleanup.py --help
python trading_data_manager.py --help
python main.py --help
```

### CI/CD Execution

Python code is automatically executed by GitLab CI/CD on:
- Every push to any branch
- Every merge request
- Manual pipeline triggers

## CI/CD Configuration

Configuration file: `.gitlab-ci.yml`

### Customize Jobs

Edit `.gitlab-ci.yml` to add or modify jobs:

```yaml
my-custom-job:
  stage: test
  script:
    - echo "Running custom job"
    - python my_script.py
  tags:
    - docker
```

### Environment Variables

Set in GitLab UI: **Settings > CI/CD > Variables**

Common variables:
- `EXNESS_LOGIN` - MT5 account login
- `EXNESS_PASSWORD` - MT5 password (masked)
- `EXNESS_SERVER` - MT5 server name
- `MT5_PATH` - Path to MT5 terminal

## Troubleshooting

### Runner Not Picking Up Jobs

```bash
# Check runner status
sudo gitlab-runner verify

# Check runner tags
sudo gitlab-runner list

# Restart runner
sudo gitlab-runner restart
```

### Pipeline Failing

1. Check job logs in GitLab UI
2. Run commands locally to reproduce
3. Fix issues and push again

### Docker Issues

```bash
# Add gitlab-runner to docker group
sudo usermod -aG docker gitlab-runner
sudo systemctl restart gitlab-runner
```

## File Locations

### Configuration Files

- `.gitlab-ci.yml` - Pipeline configuration
- `requirements.txt` - Python dependencies
- `scripts/setup-gitlab-runner.sh` - Runner setup script

### Documentation

- `GITLAB_RUNNER_SETUP.md` - Complete setup guide
- `FORGE_MQL5_SETUP.md` - forge.mql5.io sync guide
- `README.md` - Main project documentation

## Links

- **forge.mql5.io Project**: https://forge.mql5.io/LengKundee/NUNA
- **GitHub Repository**: https://github.com/A6-9V/NUNA
- **GitLab Runner Docs**: https://docs.gitlab.com/runner/
- **GitLab CI/CD Docs**: https://docs.gitlab.com/ee/ci/

## Support

For help:
1. Check `GITLAB_RUNNER_SETUP.md` for detailed instructions
2. Review GitLab CI/CD documentation
3. Open an issue on GitHub

---

**Last Updated**: 2026-02-13  
**Repository**: A6-9V/NUNA  
**forge.mql5.io**: LengKundee/NUNA

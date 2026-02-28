# GitLab Runner Setup Guide

This guide explains how to set up and configure GitLab CI/CD runners for the NUNA project on forge.mql5.io.

## Overview

The NUNA project uses GitLab CI/CD for automated testing, building, and deployment on the forge.mql5.io platform. This document covers the setup and configuration of GitLab runners.

## Runner Token

**⚠️ SECURITY WARNING**: This section contains a sensitive runner registration token. In a production environment, this token should be:
- Stored in a secure secrets manager
- Distributed through private channels
- Rotated regularly
- Never committed to public repositories

**Runner Registration Token**: `d7tzwkGG974FKv6zb5m9IO4xHy99Br6cZPuCddwN`

**Security Note**: This token is used to register new runners with the GitLab/forge.mql5.io repository. Keep it secure and do not share it publicly. The token is included here as it was explicitly provided in the project requirements, but should be treated as sensitive information.

## Prerequisites

- Access to forge.mql5.io repository (https://forge.mql5.io/LengKundee/NUNA)
- Docker installed (for Docker executor)
- GitLab Runner installed on your system
- Network access to forge.mql5.io

## Installing GitLab Runner

### Linux

```bash

# Download the binary
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

# Give it permissions to execute
sudo chmod +x /usr/local/bin/gitlab-runner

# Create a GitLab CI user
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

# Install and run as service
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start

```bash

### macOS

```bash

# Install using Homebrew
brew install gitlab-runner

# Start the service
brew services start gitlab-runner

```bash

### Windows

1. Download GitLab Runner from: https://docs.gitlab.com/runner/install/windows.html
2. Extract to `C:\GitLab-Runner`
3. Open PowerShell as Administrator and run:
   ```powershell
   cd C:\GitLab-Runner
   .\gitlab-runner.exe install
   .\gitlab-runner.exe start
   ```

## Registering a Runner

### Automatic Registration

```bash
sudo gitlab-runner register \

  --non-interactive \
  --url "https://forge.mql5.io/" \
  --registration-token "d7tzwkGG974FKv6zb5m9IO4xHy99Br6cZPuCddwN" \
  --executor "docker" \
  --docker-image "python:3.12-slim" \
  --description "NUNA Python Runner" \
  --tag-list "docker,python,nuna" \
  --run-untagged="false" \
  --locked="false" \
  --access-level="not_protected"

```bash

### Interactive Registration

```bash
sudo gitlab-runner register

```bash

Then provide the following information when prompted:

1. **GitLab instance URL**: `https://forge.mql5.io/`
2. **Registration token**: `d7tzwkGG974FKv6zb5m9IO4xHy99Br6cZPuCddwN`
3. **Description**: `NUNA Python Runner`
4. **Tags**: `docker,python,nuna`
5. **Executor**: `docker`
6. **Default Docker image**: `python:3.12-slim`

## Runner Configuration

The runner configuration is stored in `/etc/gitlab-runner/config.toml` (Linux) or `C:\GitLab-Runner\config.toml` (Windows).

### Example Configuration

```toml
concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "NUNA Python Runner"
  url = "https://forge.mql5.io/"
  token = "<RUNNER_TOKEN_AFTER_REGISTRATION>"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "python:3.12-slim"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0

```bash

## CI/CD Pipeline

The GitLab CI/CD pipeline is defined in `.gitlab-ci.yml` and includes the following stages:

### Stages

1. **setup** - Environment setup and dependency installation
2. **test** - Linting, syntax checking, and unit tests
3. **build** - Docker image building
4. **deploy** - Deployment preparation and execution

### Jobs

- **setup**: Verify environment and install dependencies
- **lint**: Run flake8 Python linting
- **syntax-check**: Compile all Python files to check syntax
- **unit-tests**: Run unit tests with unittest
- **cli-tests**: Test CLI commands functionality
- **integration-tests**: Run integration tests
- **docker-build**: Build and test Docker image
- **prepare-deploy**: Create deployment artifacts
- **deploy**: Manual deployment trigger

## Running Python Code

### Automatic Execution

Python code is automatically executed on every push or merge request through the GitLab CI/CD pipeline:

1. Push code to the repository
2. GitLab runner picks up the job
3. Runner executes Python tests and scripts
4. Results are displayed in the pipeline view

### Manual Execution

To manually trigger Python code execution:

1. Go to forge.mql5.io project: https://forge.mql5.io/LengKundee/NUNA
2. Navigate to **CI/CD > Pipelines**
3. Click **Run Pipeline**
4. Select the branch
5. Click **Run**

## Monitoring and Troubleshooting

### View Runner Status

```bash
sudo gitlab-runner status

```bash

### View Runner Logs

```bash
sudo gitlab-runner --debug run

```bash

### Check Pipeline Status

Visit: https://forge.mql5.io/LengKundee/NUNA/-/pipelines

### Common Issues

#### Runner Not Picking Up Jobs

1. Check runner status:
   ```bash
   sudo gitlab-runner verify
   ```

2. Ensure runner is active:
   ```bash
   sudo gitlab-runner list
   ```

3. Check runner tags match job tags

#### Docker Permission Issues

```bash

# Add gitlab-runner user to docker group
sudo usermod -aG docker gitlab-runner
sudo systemctl restart gitlab-runner

```bash

#### Network/SSL Issues

If you encounter SSL/TLS errors:

```bash

# Edit config.toml
sudo nano /etc/gitlab-runner/config.toml

# Add or modify:
[runners.docker]
  tls_verify = false

```bash

## Security Best Practices

1. **Protect the Runner Token**: Never commit the runner token to the repository
2. **Use Tags**: Use specific tags to control which runners execute which jobs
3. **Limit Concurrent Jobs**: Set appropriate concurrency limits
4. **Monitor Resource Usage**: Keep track of runner resource consumption
5. **Regular Updates**: Keep GitLab Runner updated to the latest version

## Updating GitLab Runner

### Linux

```bash
sudo gitlab-runner stop
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
sudo chmod +x /usr/local/bin/gitlab-runner
sudo gitlab-runner start

```bash

### macOS

```bash
brew upgrade gitlab-runner
brew services restart gitlab-runner

```bash

### Windows

1. Download latest version
2. Stop the service: `gitlab-runner.exe stop`
3. Replace the executable
4. Start the service: `gitlab-runner.exe start`

## Managing Multiple Runners

You can register multiple runners for different purposes:

```bash

# Runner for Python tests
gitlab-runner register --executor docker --docker-image python:3.12-slim --tag-list "python,tests"

# Runner for Docker builds
gitlab-runner register --executor docker --docker-image docker:24-dind --tag-list "docker,build"

# Runner for deployments
gitlab-runner register --executor shell --tag-list "deployment"

```bash

## Environment Variables

Set environment variables for runners in GitLab:

1. Go to **Settings > CI/CD > Variables**
2. Add variables:

   - `EXNESS_LOGIN`: MT5 account login
   - `EXNESS_PASSWORD`: MT5 account password (masked)
   - `EXNESS_SERVER`: MT5 server name
   - `MT5_PATH`: Path to MT5 terminal

## Resources

- **GitLab Runner Documentation**: https://docs.gitlab.com/runner/
- **forge.mql5.io**: https://forge.mql5.io/
- **GitLab CI/CD Documentation**: https://docs.gitlab.com/ee/ci/
- **Docker Executor**: https://docs.gitlab.com/runner/executors/docker.html

## Integration with GitHub

The NUNA project is synchronized between:

- **GitHub**: https://github.com/A6-9V/NUNA (Primary)
- **forge.mql5.io**: https://forge.mql5.io/LengKundee/NUNA (GitLab)

See [FORGE_MQL5_SETUP.md](FORGE_MQL5_SETUP.md) for syncing instructions.

## Support

For issues related to:

- **Runner setup**: Check GitLab Runner documentation
- **Pipeline configuration**: Review `.gitlab-ci.yml` syntax
- **forge.mql5.io access**: Contact MQL5 support
- **Project issues**: Open an issue on GitHub

---

**Last Updated**: 2026-02-13  
**Repository**: A6-9V/NUNA  
**forge.mql5.io Repository**: LengKundee/NUNA  
**Runner Token**: d7tzwkGG974FKv6zb5m9IO4xHy99Br6cZPuCddwN

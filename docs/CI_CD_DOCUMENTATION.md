# CI/CD Workflows Documentation

This document describes the GitHub Actions workflows implemented for the NUNA
project to ensure code quality, security, and automated deployment.

## CI Workflow

**File**: .github/workflows/ci.yml

- **Triggers**: Push to main, Pull Requests to main.
- **Jobs**:
  - Docker Build & Test: Verifies that the Docker image builds successfully and
    basic smoke tests pass.

## Deployment Workflow

**File**: .github/workflows/deploy.yml

- **Triggers**: Push to main branch, Tags matching v*.
- **Jobs**:
  - Build & Deploy: Builds the Docker image and pushes it to GHCR.
  - Deploy to VPS: Optionally deploys the new image to a configured VPS.

## Security Workflow

**File**: .github/workflows/security.yml

- **Triggers**: Scheduled daily, Push to main, Pull Requests to main.
- **Jobs**:
  - Python Security: Audits dependencies using pip-audit.
  - Docker Security: Scans Docker images for vulnerabilities using Trivy.
  - Secret Scan: Scans repository for exposed secrets using TruffleHog.

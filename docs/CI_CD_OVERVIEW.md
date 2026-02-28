# CI/CD Overview

## Pipeline Architecture
Our CI/CD process ensures code quality and automated deployments.

## CI Workflows
1. **Validation**: Linting and unit tests.
2. **Security**: Dependency scans and secret detection.
3. **Quality**: Code coverage reports.

## CD Workflows
1. **Docker**: Builds and pushes images to Artifact Registry.
2. **Kubernetes**: Deploys to GKE using Kustomize.

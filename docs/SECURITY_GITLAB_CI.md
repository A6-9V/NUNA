# Security in GitLab CI

## Strategy
We integrate security checks into every pipeline run.

## Components
- **Secret Scanning**: Detects exposed credentials.
- **Dependency Scanning**: Checks for vulnerable packages.
- **SAST**: Static analysis for common vulnerabilities.

## Configuration
Define variables for API keys in the GitLab CI/CD settings.

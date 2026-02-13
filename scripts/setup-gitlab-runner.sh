#!/bin/bash
# Quick setup script for GitLab CI/CD integration with forge.mql5.io
# This script helps configure GitLab runners for the NUNA project
#
# SECURITY NOTE: This script contains a default runner registration token.
# For enhanced security, set the GITLAB_RUNNER_TOKEN environment variable
# instead of using the hardcoded default:
#   export GITLAB_RUNNER_TOKEN="your-secure-token"
#   ./setup-gitlab-runner.sh

set -e

echo "========================================"
echo "GitLab Runner Setup for NUNA Project"
echo "========================================"
echo ""

# Check if GitLab Runner is installed
if ! command -v gitlab-runner &> /dev/null; then
    echo "❌ GitLab Runner is not installed."
    echo ""
    echo "Please install GitLab Runner first:"
    echo ""
    echo "  Linux:"
    echo "    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash"
    echo "    sudo apt-get install gitlab-runner"
    echo ""
    echo "  macOS:"
    echo "    brew install gitlab-runner"
    echo ""
    echo "  Windows:"
    echo "    Download from: https://docs.gitlab.com/runner/install/windows.html"
    echo ""
    exit 1
fi

echo "✓ GitLab Runner is installed"
gitlab-runner --version
echo ""

# Runner configuration
GITLAB_URL="https://forge.mql5.io/"
# Read token from environment variable or use the provided default
RUNNER_TOKEN="${GITLAB_RUNNER_TOKEN:-d7tzwkGG974FKv6zb5m9IO4xHy99Br6cZPuCddwN}"
RUNNER_NAME="NUNA Python Runner"
RUNNER_EXECUTOR="docker"
DOCKER_IMAGE="python:3.12-slim"
RUNNER_TAGS="docker,python,nuna"

echo "Configuration:"
echo "  URL: $GITLAB_URL"
echo "  Name: $RUNNER_NAME"
echo "  Executor: $RUNNER_EXECUTOR"
echo "  Docker Image: $DOCKER_IMAGE"
echo "  Tags: $RUNNER_TAGS"
echo "  Token: ${RUNNER_TOKEN:0:10}... (masked)"
echo ""
echo "⚠️  SECURITY NOTE: The runner token is sensitive. Keep it secure."
echo "    You can set GITLAB_RUNNER_TOKEN environment variable to override the default."
echo ""

# Check if Docker is available for Docker executor
if [ "$RUNNER_EXECUTOR" = "docker" ]; then
    if ! command -v docker &> /dev/null; then
        echo "⚠️  Warning: Docker is not installed but required for Docker executor."
        echo "   Please install Docker first: https://docs.docker.com/get-docker/"
        echo ""
        read -p "Do you want to continue with shell executor instead? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            RUNNER_EXECUTOR="shell"
            echo "Switching to shell executor..."
        else
            exit 1
        fi
    else
        echo "✓ Docker is installed"
        docker --version
    fi
fi
echo ""

# Ask for confirmation
echo "This script will register a new GitLab runner with the following configuration:"
echo "  Registration token: ${RUNNER_TOKEN:0:10}..."
echo ""
read -p "Do you want to proceed? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Register the runner
echo ""
echo "Registering GitLab runner..."
echo ""

if [ "$RUNNER_EXECUTOR" = "docker" ]; then
    sudo gitlab-runner register \
        --non-interactive \
        --url "$GITLAB_URL" \
        --registration-token "$RUNNER_TOKEN" \
        --executor "$RUNNER_EXECUTOR" \
        --docker-image "$DOCKER_IMAGE" \
        --description "$RUNNER_NAME" \
        --tag-list "$RUNNER_TAGS" \
        --run-untagged="false" \
        --locked="false" \
        --access-level="not_protected"
else
    sudo gitlab-runner register \
        --non-interactive \
        --url "$GITLAB_URL" \
        --registration-token "$RUNNER_TOKEN" \
        --executor "$RUNNER_EXECUTOR" \
        --description "$RUNNER_NAME" \
        --tag-list "$RUNNER_TAGS" \
        --run-untagged="false" \
        --locked="false" \
        --access-level="not_protected"
fi

echo ""
echo "✓ Runner registered successfully!"
echo ""

# Start the runner if not running
echo "Starting GitLab runner service..."
sudo gitlab-runner start || true

echo ""
echo "✓ GitLab runner is now running"
echo ""

# Display runner status
echo "Runner status:"
sudo gitlab-runner list
echo ""

echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Push code to the forge.mql5.io repository"
echo "2. GitLab CI/CD will automatically run pipelines"
echo "3. View pipeline status at: https://forge.mql5.io/LengKundee/NUNA/-/pipelines"
echo ""
echo "To view runner logs:"
echo "  sudo gitlab-runner --debug run"
echo ""
echo "To stop the runner:"
echo "  sudo gitlab-runner stop"
echo ""
echo "For more information, see GITLAB_RUNNER_SETUP.md"
echo ""

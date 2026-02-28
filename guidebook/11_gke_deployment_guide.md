# GKE Deployment Guide

This guide explains how to deploy the NUNA services to Google Kubernetes Engine (GKE) in the project `sharp-doodad-471511-s5`.

## Prerequisites

1.  **Google Cloud SDK**: Installed and authenticated (`gcloud auth login`).
2.  **Docker**: Installed and running.
3.  **kubectl**: Installed.

## Project Structure

- `kubernetes/base/`: Contains the base Kubernetes manifests.
- `kubernetes/overlays/production/`: Contains production-specific configurations and patches.
- `scripts/deploy-gke.sh`: Automation script for deployment.

## Deployment Steps

1.  **Configure Secrets**:
    Copy the example secret file and edit it with your real passwords:
    ```bash
    cp kubernetes/base/secret.yaml.example kubernetes/base/secret.yaml
    # Edit with your passwords using your favorite editor
    ```

2.  **Run Deployment Script**:
    ```bash
    ./scripts/deploy-gke.sh
    ```

This script will:
1.  Enable necessary Google Cloud APIs.
2.  Create or get credentials for the GKE cluster `nuna-cluster` (Zonal).
3.  Ensure an Artifact Registry repository exists.
4.  Build and push the Docker image to Google Artifact Registry (GAR).
5.  Apply the Kubernetes manifests using Kustomize.

## Manual Management

### Viewing Pods
```bash
kubectl get pods
```

### Viewing Logs
```bash
kubectl logs -f deployment/trading-bridge
```

### Accessing Grafana
The Grafana service is exposed via a LoadBalancer. Get the external IP:
```bash
kubectl get service grafana
```
**Important**: Ensure you have changed the default admin password in `secret.yaml` before deploying.

## Scaling
To scale the trading bridge, you can update the `kustomization.yaml` in `kubernetes/overlays/production/` or use kubectl:
```bash
kubectl scale deployment/trading-bridge --replicas=3
```

# GKE Deployment Guide

## Prerequisites
- Google Cloud Project
- GKE Cluster created
- Artifact Registry enabled

## Deployment
1. Build the image: `scripts/build-docker.sh`.
2. Push to Artifact Registry.
3. Apply manifests: `kubectl apply -k kubernetes/overlays/production`.

## Verification
Check pod status: `kubectl get pods`.

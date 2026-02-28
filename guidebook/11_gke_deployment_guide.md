# GKE Deployment Guide

This guide explains how to deploy to GKE in project `sharp-doodad-471511-s5`.

## Prerequisites

1. **Google Cloud SDK**: Installed and authenticated.
2. **Docker**: Installed and running.
3. **kubectl**: Installed.

## Deployment Steps

1. Enable APIs.
2. Create Cluster.
3. Push Image.
4. Deploy Manifests.

```bash
./scripts/deploy-gke.sh
```

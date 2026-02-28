#!/bin/bash
# GKE Deployment Script for NUNA
# Automates deployment to Google Kubernetes Engine using Artifact Registry

set -e

# Configuration
PROJECT_ID="sharp-doodad-471511-s5"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="nuna-cluster"
REPO_NAME="nuna-repo"
IMAGE_NAME="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/trading-bridge:latest"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting GKE Deployment for Project: $PROJECT_ID${NC}"

# Step 1: Enable APIs
echo -e "${YELLOW}Step 1: Enabling necessary APIs...${NC}"
gcloud services enable container.googleapis.com artifactregistry.googleapis.com --project $PROJECT_ID

# Step 2: Create Artifact Registry Repository
echo -e "${YELLOW}Step 2: Ensuring Artifact Registry repository exists...${NC}"
if gcloud artifacts repositories describe $REPO_NAME --location $REGION --project $PROJECT_ID > /dev/null 2>&1; then
    echo "Repository $REPO_NAME already exists."
else
    echo "Creating repository $REPO_NAME..."
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --project $PROJECT_ID \
        --description="Docker repository for NUNA services"
fi

# Step 3: Configure GKE Cluster
echo -e "${YELLOW}Step 3: Configuring GKE Cluster (Zonal)...${NC}"
if gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID > /dev/null 2>&1; then
    echo "Cluster $CLUSTER_NAME already exists."
else
    echo "Creating cluster $CLUSTER_NAME..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone $ZONE \
        --project $PROJECT_ID \
        --num-nodes 3 \
        --machine-type e2-medium
fi

# Get Credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# Step 4: Handle Secrets
echo -e "${YELLOW}Step 4: Ensuring secrets are configured...${NC}"
if [ ! -f kubernetes/base/secret.yaml ]; then
    if [ -f kubernetes/base/secret.yaml.example ]; then
        echo "Creating kubernetes/base/secret.yaml from template..."
        cp kubernetes/base/secret.yaml.example kubernetes/base/secret.yaml
        echo "WARNING: Using default passwords in secret.yaml. Please edit and re-deploy!"
    else
        echo "ERROR: secret.yaml.example not found!"
        # Exit if secret.yaml.example is missing
        [[ -f kubernetes/base/secret.yaml.example ]] || { echo "CRITICAL: secret.yaml.example missing"; return 1; }
    fi
fi

# Step 5: Build and Push Docker Image
echo -e "${YELLOW}Step 5: Building and Pushing Docker Image...${NC}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
docker build -t $IMAGE_NAME .
docker push $IMAGE_NAME

# Step 6: Deploy to Kubernetes
echo -e "${YELLOW}Step 6: Deploying to GKE using Kustomize...${NC}"
kubectl apply -k kubernetes/overlays/production

echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "Check status with: ${YELLOW}kubectl get pods${NC}"

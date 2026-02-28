#!/bin/bash

set -e

PROJECT_ID="sharp-doodad-471511-s5"
CLUSTER_NAME="nuna-cluster"
REGION="us-central1"
ZONE="us-central1-a"
NAMESPACE="nuna-trading"

echo "Starting GKE Deployment for project: $PROJECT_ID"

if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed."
    exit 1
fi

gcloud config set project $PROJECT_ID

echo "Getting credentials for cluster $CLUSTER_NAME in $ZONE..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE || {
    echo "Cluster not found. Attempting to create a zonal cluster..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone $ZONE \
        --num-nodes 1 \
        --machine-type e2-medium \
        --disk-size 20
}

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

if [ -f "kubernetes/base/secret.yaml" ]; then
    kubectl apply -f kubernetes/base/secret.yaml -n $NAMESPACE
fi

if [ -d "kubernetes/overlays/production" ]; then
    kubectl apply -k kubernetes/overlays/production -n $NAMESPACE
elif [ -d "kubernetes/base" ]; then
    kubectl apply -f kubernetes/base -n $NAMESPACE
else
    echo "Error: No Kubernetes manifests found."
    exit 1
fi

echo "GKE Deployment completed successfully!"

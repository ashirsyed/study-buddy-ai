#!/bin/bash

# Kubernetes Setup Script
# This script sets up Kubernetes namespace and secrets

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set defaults
NAMESPACE=${K8S_NAMESPACE:-study-buddy}

echo -e "${GREEN}🚀 Setting up Kubernetes for Study Buddy AI...${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed!${NC}"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster!${NC}"
    echo "Please configure kubectl or set KUBECONFIG environment variable."
    exit 1
fi

# Create namespace
echo -e "${GREEN}📦 Creating namespace: $NAMESPACE...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Check if GROQ_API_KEY is set
if [ -z "$GROQ_API_KEY" ] || [ "$GROQ_API_KEY" == "your_groq_api_key_here" ]; then
    echo -e "${YELLOW}⚠️  GROQ_API_KEY not set in .env${NC}"
    read -p "Enter your Groq API Key: " GROQ_API_KEY
fi

# Create or update secret
echo -e "${GREEN}🔐 Creating/updating secret...${NC}"
kubectl create secret generic groq-api-secret \
    --from-literal=GROQ_API_KEY="$GROQ_API_KEY" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Kubernetes setup complete!${NC}"
echo ""
echo "Namespace: $NAMESPACE"
echo "Secret: groq-api-secret"
echo ""
echo "Next steps:"
echo "1. Update manifests/deployment.yaml with your image URL"
echo "2. Apply manifests: kubectl apply -f manifests/"


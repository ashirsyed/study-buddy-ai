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

# Check if kubectl is available (k3s on VM)
if ! command -v kubectl &> /dev/null && ! command -v k3s &> /dev/null; then
    echo -e "${RED}❌ kubectl or k3s is not installed!${NC}"
    echo "Please install k3s: curl -sfL https://get.k3s.io | sh -"
    exit 1
fi

# Check if k3s is running
if command -v k3s &> /dev/null; then
    if ! sudo systemctl is-active --quiet k3s; then
        echo -e "${RED}❌ k3s is not running!${NC}"
        echo "Please start k3s: sudo systemctl start k3s"
        exit 1
    fi
    
    # Set KUBECONFIG for k3s
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    KUBECTL_CMD="sudo k3s kubectl"
else
    KUBECTL_CMD="kubectl"
fi

# Check if we can connect to cluster
if ! $KUBECTL_CMD cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster!${NC}"
    echo "Please check k3s status: sudo systemctl status k3s"
    exit 1
fi

# Create namespace
echo -e "${GREEN}📦 Creating namespace: $NAMESPACE...${NC}"
$KUBECTL_CMD create namespace $NAMESPACE --dry-run=client -o yaml | $KUBECTL_CMD apply -f -

# Check if GROQ_API_KEY is set
if [ -z "$GROQ_API_KEY" ] || [ "$GROQ_API_KEY" == "your_groq_api_key_here" ]; then
    echo -e "${YELLOW}⚠️  GROQ_API_KEY not set in .env${NC}"
    read -p "Enter your Groq API Key: " GROQ_API_KEY
fi

# Create or update secret
echo -e "${GREEN}🔐 Creating/updating secret...${NC}"
$KUBECTL_CMD create secret generic groq-api-secret \
    --from-literal=GROQ_API_KEY="$GROQ_API_KEY" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | $KUBECTL_CMD apply -f -

echo -e "${GREEN}✅ Kubernetes setup complete!${NC}"
echo ""
echo "Namespace: $NAMESPACE"
echo "Secret: groq-api-secret"
echo ""
echo "Next steps:"
echo "1. Build Docker image: docker build -t study-buddy-ai:latest ."
echo "2. Update manifests/deployment.yaml with your image (use 'study-buddy-ai:latest' for local)"
echo "3. Apply manifests: $KUBECTL_CMD apply -f manifests/"
echo ""
echo "Note: Using k3s on VM. For local images, use 'imagePullPolicy: Never' in deployment.yaml"


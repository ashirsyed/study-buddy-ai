#!/bin/bash

# Fix k3s kubeconfig permissions
# This script copies k3s.yaml to ~/.kube/config with proper permissions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Fixing k3s kubeconfig permissions...${NC}"

# Check if k3s is installed
if ! command -v k3s &> /dev/null; then
    echo -e "${RED}❌ k3s is not installed!${NC}"
    exit 1
fi

# Check if k3s is running
if ! sudo systemctl is-active --quiet k3s; then
    echo -e "${YELLOW}⚠️  k3s is not running. Starting k3s...${NC}"
    sudo systemctl start k3s
    sleep 5
fi

# Create .kube directory
mkdir -p ~/.kube

# Copy k3s config to user's kubeconfig
echo -e "${GREEN}📋 Copying k3s.yaml to ~/.kube/config...${NC}"
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# Fix ownership
echo -e "${GREEN}👤 Setting ownership...${NC}"
sudo chown $USER:$USER ~/.kube/config

# Fix permissions
echo -e "${GREEN}🔒 Setting permissions...${NC}"
chmod 600 ~/.kube/config

# Update server URL to use localhost (for better compatibility)
echo -e "${GREEN}🌐 Updating server URL...${NC}"
sed -i 's/127.0.0.1/localhost/g' ~/.kube/config 2>/dev/null || \
sed -i '' 's/127.0.0.1/localhost/g' ~/.kube/config 2>/dev/null || true

# Set KUBECONFIG
export KUBECONFIG=~/.kube/config

# Verify
echo -e "${GREEN}✅ Verifying connection...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Success! kubectl is now configured.${NC}"
    echo ""
    echo "You can now use:"
    echo "  kubectl get nodes"
    echo "  kubectl apply -f manifests/"
    echo ""
    kubectl cluster-info
else
    echo -e "${RED}❌ Still having issues. Try:${NC}"
    echo "  sudo k3s kubectl get nodes"
    exit 1
fi


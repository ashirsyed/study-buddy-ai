#!/bin/bash

# Install ArgoCD CLI Script
# This script installs the ArgoCD CLI tool

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Installing ArgoCD CLI...${NC}"

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "${GREEN}Detected OS: $OS, Architecture: $ARCH${NC}"

# Install ArgoCD CLI
if [[ "$OS" == "Linux" ]]; then
    echo -e "${GREEN}📥 Downloading ArgoCD CLI for Linux...${NC}"
    curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
    rm /tmp/argocd-linux-amd64
    echo -e "${GREEN}✅ ArgoCD CLI installed to /usr/local/bin/argocd${NC}"
elif [[ "$OS" == "Darwin" ]]; then
    # macOS
    if command -v brew &> /dev/null; then
        echo -e "${GREEN}📥 Installing via Homebrew...${NC}"
        brew install argocd
    else
        echo -e "${GREEN}📥 Downloading ArgoCD CLI for macOS...${NC}"
        curl -sSL -o /tmp/argocd-darwin-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
        sudo install -m 555 /tmp/argocd-darwin-amd64 /usr/local/bin/argocd
        rm /tmp/argocd-darwin-amd64
        echo -e "${GREEN}✅ ArgoCD CLI installed to /usr/local/bin/argocd${NC}"
    fi
else
    echo -e "${RED}❌ Unsupported OS: $OS${NC}"
    echo "Please install ArgoCD CLI manually from: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    exit 1
fi

# Verify installation
if command -v argocd &> /dev/null; then
    ARGOCD_VERSION=$(argocd version --client --short 2>/dev/null || echo "installed")
    echo -e "${GREEN}✅ ArgoCD CLI installed successfully!${NC}"
    echo -e "${GREEN}Version: $ARGOCD_VERSION${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Next Steps:${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1. Port forward ArgoCD server:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo ""
    echo "2. Login to ArgoCD:"
    echo "   argocd login localhost:8080"
    echo ""
    echo "3. Get admin password:"
    echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    echo ""
    echo "4. Sync application:"
    echo "   argocd app sync study-buddy-ai"
    echo ""
else
    echo -e "${RED}❌ Installation failed!${NC}"
    exit 1
fi


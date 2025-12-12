#!/bin/bash

# Create Kubernetes Service for Study Buddy AI
# This script creates the service if it doesn't exist

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Creating Kubernetes Service...${NC}"

# Check if kubectl is available
if command -v k3s &> /dev/null && sudo systemctl is-active --quiet k3s; then
    KUBECTL_CMD="sudo k3s kubectl"
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
elif [ -f ~/.kube/config ]; then
    KUBECTL_CMD="kubectl"
    export KUBECONFIG=~/.kube/config
else
    echo -e "${RED}❌ kubectl not configured!${NC}"
    echo "Please run: ./scripts/fix-k3s-config.sh"
    exit 1
fi

# Check if namespace exists
if ! $KUBECTL_CMD get namespace study-buddy &> /dev/null; then
    echo -e "${GREEN}📦 Creating namespace...${NC}"
    $KUBECTL_CMD create namespace study-buddy
fi

# Check if service already exists
if $KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy &> /dev/null; then
    echo -e "${YELLOW}⚠️  Service already exists${NC}"
    $KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy
    exit 0
fi

# Create service
echo -e "${GREEN}🚀 Creating service...${NC}"
$KUBECTL_CMD apply -f manifests/service.yaml

# Verify
echo -e "${GREEN}✅ Service created!${NC}"
$KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Service Information:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SERVICE_TYPE=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy -o jsonpath='{.spec.type}')

if [ "$SERVICE_TYPE" == "LoadBalancer" ]; then
    EXTERNAL_IP=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" == "<pending>" ]; then
        echo -e "Type: ${YELLOW}LoadBalancer${NC} (External IP pending...)"
        echo -e "Access via port-forward: ${GREEN}kubectl port-forward svc/study-buddy-ai-service -n study-buddy 8080:80${NC}"
    else
        echo -e "Type: ${GREEN}LoadBalancer${NC}"
        echo -e "External IP: ${GREEN}$EXTERNAL_IP${NC}"
        echo -e "Access at: ${GREEN}http://$EXTERNAL_IP${NC}"
    fi
elif [ "$SERVICE_TYPE" == "NodePort" ]; then
    NODEPORT=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy -o jsonpath='{.spec.ports[0].nodePort}')
    VM_IP=$(curl -s ifconfig.me || echo "<VM_EXTERNAL_IP>")
    echo -e "Type: ${GREEN}NodePort${NC}"
    echo -e "NodePort: ${GREEN}$NODEPORT${NC}"
    echo -e "Access at: ${GREEN}http://$VM_IP:$NODEPORT${NC}"
else
    echo -e "Type: ${YELLOW}$SERVICE_TYPE${NC}"
    echo -e "Access via port-forward: ${GREEN}kubectl port-forward svc/study-buddy-ai-service -n study-buddy 8080:80${NC}"
fi

echo ""
echo -e "${GREEN}To access the app:${NC}"
echo "  ./scripts/access-app.sh"


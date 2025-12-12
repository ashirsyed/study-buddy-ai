#!/bin/bash

# ArgoCD Access Script for k3s on VM
# This script helps you access ArgoCD UI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Checking ArgoCD status...${NC}"

# Check if k3s is being used
if command -v k3s &> /dev/null && sudo systemctl is-active --quiet k3s; then
    KUBECTL_CMD="sudo k3s kubectl"
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    echo -e "${GREEN}✅ Using k3s${NC}"
else
    KUBECTL_CMD="kubectl"
    echo -e "${GREEN}✅ Using standard kubectl${NC}"
fi

# Check if ArgoCD namespace exists
if ! $KUBECTL_CMD get namespace argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD namespace not found!${NC}"
    echo "Please install ArgoCD first:"
    echo "  kubectl create namespace argocd"
    echo "  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi

# Check ArgoCD server pod
echo -e "${YELLOW}📦 Checking ArgoCD server pod...${NC}"
ARGOCD_POD=$($KUBECTL_CMD get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$ARGOCD_POD" ]; then
    echo -e "${RED}❌ ArgoCD server pod not found!${NC}"
    echo "Checking all pods in argocd namespace:"
    $KUBECTL_CMD get pods -n argocd
    exit 1
fi

echo -e "${GREEN}✅ Found ArgoCD server pod: $ARGOCD_POD${NC}"

# Check if pod is ready
POD_STATUS=$($KUBECTL_CMD get pod $ARGOCD_POD -n argocd -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}⚠️  Pod status: $POD_STATUS${NC}"
    echo "Waiting for pod to be ready..."
    $KUBECTL_CMD wait --for=condition=ready pod/$ARGOCD_POD -n argocd --timeout=60s
fi

# Get admin password
echo -e "${GREEN}🔐 Getting admin password...${NC}"
ADMIN_PASSWORD=$($KUBECTL_CMD -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "")

if [ -z "$ADMIN_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Could not get password. You may need to wait for ArgoCD to initialize.${NC}"
    echo "Try again in a few minutes."
else
    echo -e "${GREEN}✅ Admin password retrieved${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}ArgoCD Login Credentials:${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Username: ${YELLOW}admin${NC}"
    echo -e "Password: ${YELLOW}$ADMIN_PASSWORD${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# Choose access method
echo ""
echo "Choose access method:"
echo "1) Port Forward (localhost access)"
echo "2) NodePort (external access via VM IP)"
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Starting port forward...${NC}"
        echo "Access ArgoCD at: https://localhost:8080"
        echo "Press Ctrl+C to stop"
        echo ""
        
        # Try port-forward with pod first (more reliable)
        $KUBECTL_CMD port-forward $ARGOCD_POD -n argocd 8080:8080 || \
        $KUBECTL_CMD port-forward svc/argocd-server -n argocd 8080:443
        ;;
    2)
        echo -e "${GREEN}🔧 Changing service to NodePort...${NC}"
        $KUBECTL_CMD patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
        
        echo -e "${GREEN}✅ Service updated${NC}"
        echo ""
        echo "Getting NodePort..."
        NODEPORT=$($KUBECTL_CMD get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
        
        if [ -z "$NODEPORT" ]; then
            NODEPORT=$($KUBECTL_CMD get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')
        fi
        
        # Get VM external IP
        VM_IP=$(curl -s ifconfig.me || echo "<VM_EXTERNAL_IP>")
        
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}ArgoCD Access Information:${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "NodePort: ${YELLOW}$NODEPORT${NC}"
        echo -e "VM IP: ${YELLOW}$VM_IP${NC}"
        echo -e "Access URL: ${YELLOW}http://$VM_IP:$NODEPORT${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Make sure firewall allows port $NODEPORT"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac


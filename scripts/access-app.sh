#!/bin/bash

# Access Study Buddy AI Application
# This script helps you access the application running in Kubernetes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Checking Study Buddy AI application status...${NC}"

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
    echo -e "${RED}❌ Namespace 'study-buddy' not found!${NC}"
    echo "Please deploy the application first:"
    echo "  ./scripts/setup-k8s.sh"
    echo "  kubectl apply -f manifests/"
    exit 1
fi

# Check if pods are running
PODS=$($KUBECTL_CMD get pods -n study-buddy -l app=study-buddy-ai -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [ -z "$PODS" ]; then
    echo -e "${RED}❌ No pods found!${NC}"
    echo "Please deploy the application first:"
    echo "  kubectl apply -f manifests/deployment.yaml"
    exit 1
fi

echo -e "${GREEN}✅ Application pods found${NC}"
$KUBECTL_CMD get pods -n study-buddy -l app=study-buddy-ai

# Check service
SERVICE=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy 2>/dev/null || echo "")

if [ -z "$SERVICE" ]; then
    echo -e "${YELLOW}⚠️  Service not found. Creating port-forward to pod...${NC}"
    POD_NAME=$(echo $PODS | awk '{print $1}')
    echo -e "${GREEN}🚀 Starting port forward...${NC}"
    echo "Access at: http://localhost:8501"
    echo "Press Ctrl+C to stop"
    $KUBECTL_CMD port-forward pod/$POD_NAME -n study-buddy 8501:8501
    exit 0
fi

# Get service type
SERVICE_TYPE=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy -o jsonpath='{.spec.type}')

echo ""
echo "Choose access method:"
echo "1) Port Forward (localhost access)"
echo "2) Get External IP/NodePort (if available)"
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Starting port forward...${NC}"
        echo "Access at: http://localhost:8080"
        echo "Press Ctrl+C to stop"
        $KUBECTL_CMD port-forward svc/study-buddy-ai-service -n study-buddy 8080:80
        ;;
    2)
        if [ "$SERVICE_TYPE" == "LoadBalancer" ]; then
            EXTERNAL_IP=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
            if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" == "<pending>" ]; then
                echo -e "${YELLOW}⚠️  External IP is pending. Use port-forward instead.${NC}"
                echo "Or change service to NodePort:"
                echo "  kubectl patch svc study-buddy-ai-service -n study-buddy -p '{\"spec\": {\"type\": \"NodePort\"}}'"
            else
                echo -e "${GREEN}✅ External IP: $EXTERNAL_IP${NC}"
                echo -e "${GREEN}Access at: http://$EXTERNAL_IP${NC}"
            fi
        elif [ "$SERVICE_TYPE" == "NodePort" ]; then
            NODEPORT=$($KUBECTL_CMD get svc study-buddy-ai-service -n study-buddy -o jsonpath='{.spec.ports[0].nodePort}')
            VM_IP=$(curl -s ifconfig.me || echo "<VM_EXTERNAL_IP>")
            echo -e "${GREEN}✅ NodePort: $NODEPORT${NC}"
            echo -e "${GREEN}Access at: http://$VM_IP:$NODEPORT${NC}"
        else
            echo -e "${YELLOW}⚠️  Service type is $SERVICE_TYPE. Use port-forward instead.${NC}"
            echo "Starting port-forward..."
            $KUBECTL_CMD port-forward svc/study-buddy-ai-service -n study-buddy 8080:80
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac


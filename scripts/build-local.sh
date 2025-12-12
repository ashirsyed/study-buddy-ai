#!/bin/bash

# Build Docker Image Locally for VM Deployment
# This script builds the Docker image on the VM for use with k3s

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
IMAGE_NAME=${DOCKER_IMAGE_NAME:-study-buddy-ai}
IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest}
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%s)}

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    exit 1
fi

# Check if k3s is running
if command -v k3s &> /dev/null; then
    if ! sudo systemctl is-active --quiet k3s; then
        echo -e "${YELLOW}⚠️  k3s is not running. Starting k3s...${NC}"
        sudo systemctl start k3s
    fi
    echo -e "${GREEN}✅ k3s is running${NC}"
fi

# Build image
IMAGE_FULL="${IMAGE_NAME}:${IMAGE_TAG}"
IMAGE_VERSIONED="${IMAGE_NAME}:v${BUILD_NUMBER}"

echo -e "${GREEN}🏗️  Building Docker image locally...${NC}"
echo "Image: $IMAGE_FULL"
echo "Versioned: $IMAGE_VERSIONED"

# Build Docker image
docker build -t $IMAGE_FULL -t $IMAGE_VERSIONED .

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo "Images built:"
echo "  - $IMAGE_FULL"
echo "  - $IMAGE_VERSIONED"
echo ""

# Import image into k3s (k3s uses containerd)
if command -v k3s &> /dev/null; then
    echo -e "${GREEN}📦 Importing image into k3s...${NC}"
    
    # Save image to tar
    docker save $IMAGE_FULL -o /tmp/${IMAGE_NAME}.tar
    
    # Import into k3s
    sudo k3s ctr images import /tmp/${IMAGE_NAME}.tar
    
    # Cleanup
    rm /tmp/${IMAGE_NAME}.tar
    
    echo -e "${GREEN}✅ Image imported into k3s${NC}"
    echo ""
    echo "Verify: sudo k3s kubectl get pods -n study-buddy"
fi

echo ""
echo "To use this image, update manifests/deployment.yaml with:"
echo "  image: $IMAGE_FULL"
echo "  imagePullPolicy: Never"
echo ""
echo "Then apply: kubectl apply -f manifests/deployment.yaml"


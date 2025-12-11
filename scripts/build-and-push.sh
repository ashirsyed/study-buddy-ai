#!/bin/bash

# Build and Push Docker Image Script
# This script builds and pushes the Docker image to Google Container Registry

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
PROJECT_ID=${GCP_PROJECT_ID:-your-project-id}
IMAGE_NAME=${DOCKER_IMAGE_NAME:-study-buddy-ai}
IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest}
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%s)}

# Check if PROJECT_ID is set
if [ "$PROJECT_ID" == "your-project-id" ]; then
    echo -e "${RED}❌ GCP_PROJECT_ID not set!${NC}"
    echo "Please set GCP_PROJECT_ID in .env file or export it."
    exit 1
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed!${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    exit 1
fi

# Authenticate with GCP
echo -e "${GREEN}🔐 Authenticating with GCP...${NC}"
gcloud auth configure-docker --quiet

# Build image URLs
IMAGE_URL="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}"
IMAGE_URL_VERSIONED="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:v${BUILD_NUMBER}"

echo -e "${GREEN}🏗️  Building Docker image...${NC}"
echo "Image: $IMAGE_URL"
echo "Versioned: $IMAGE_URL_VERSIONED"

# Build Docker image
docker build -t $IMAGE_URL -t $IMAGE_URL_VERSIONED .

# Push images to GCR
echo -e "${GREEN}📤 Pushing images to Google Container Registry...${NC}"
docker push $IMAGE_URL
docker push $IMAGE_URL_VERSIONED

echo ""
echo -e "${GREEN}✅ Build and push complete!${NC}"
echo "Image: $IMAGE_URL"
echo "Versioned: $IMAGE_URL_VERSIONED"
echo ""
echo "To use this image in Kubernetes, update manifests/deployment.yaml with:"
echo "  image: $IMAGE_URL_VERSIONED"


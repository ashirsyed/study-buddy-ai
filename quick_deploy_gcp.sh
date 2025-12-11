#!/bin/bash

# Study Buddy AI - Quick GCP Deployment Script
# This script quickly deploys the application to Google Cloud Run

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Quick GCP Deployment for Study Buddy AI${NC}"
echo ""

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set defaults
PROJECT_ID=${GCP_PROJECT_ID:-""}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME=${DOCKER_IMAGE_NAME:-"study-buddy-ai"}
IMAGE_TAG=${DOCKER_TAG:-"latest"}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed.${NC}"
    echo -e "${YELLOW}Please install it from: https://cloud.google.com/sdk/docs/install${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed.${NC}"
    echo -e "${YELLOW}Please install Docker from: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

# Get project ID if not set
if [ -z "$PROJECT_ID" ]; then
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$CURRENT_PROJECT" ]; then
        echo -e "${YELLOW}Using current GCP project: $CURRENT_PROJECT${NC}"
        PROJECT_ID=$CURRENT_PROJECT
    else
        echo -e "${YELLOW}Enter your GCP Project ID:${NC}"
        read PROJECT_ID
    fi
fi

# Authenticate with GCP
echo -e "${GREEN}🔐 Authenticating with GCP...${NC}"
gcloud auth login --no-launch-browser 2>/dev/null || echo -e "${YELLOW}Already authenticated${NC}"

# Set project
echo -e "${GREEN}📁 Setting GCP project to: $PROJECT_ID${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${GREEN}🔌 Enabling required GCP APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Configure Docker for GCR
echo -e "${GREEN}🐳 Configuring Docker for Google Container Registry...${NC}"
gcloud auth configure-docker --quiet

# Build Docker image
echo -e "${GREEN}🏗️  Building Docker image...${NC}"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}:${IMAGE_TAG}"
docker build -t $IMAGE_NAME .

# Push image to GCR
echo -e "${GREEN}📤 Pushing Docker image to GCR...${NC}"
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo -e "${GREEN}🚀 Deploying to Cloud Run...${NC}"

# Check if GROQ_API_KEY is set
if [ -z "$GROQ_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  GROQ_API_KEY not found in environment.${NC}"
    echo -e "${YELLOW}Please enter your Groq API Key:${NC}"
    read -s GROQ_API_KEY
fi

# Deploy with environment variables
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars "GROQ_API_KEY=$GROQ_API_KEY" \
    --port 8501 \
    --memory 512Mi \
    --cpu 1 \
    --timeout 300 \
    --max-instances 10

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')

echo ""
echo -e "${GREEN}✅ Deployment successful!${NC}"
echo -e "${GREEN}🌐 Service URL: $SERVICE_URL${NC}"
echo ""
echo -e "${BLUE}To view logs, run:${NC}"
echo -e "${YELLOW}gcloud run services logs read $SERVICE_NAME --region $REGION${NC}"


#!/bin/bash

# Study Buddy AI - Quick GCP Deployment Script
# This script automates the deployment to Google Cloud Platform

set -e  # Exit on any error

echo "🚀 Starting GCP Quick Deployment for Study Buddy AI..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Please create .env file from env.example and configure it."
    exit 1
fi

# Check required environment variables
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  GCP_PROJECT_ID not set in .env${NC}"
    read -p "Enter your GCP Project ID: " GCP_PROJECT_ID
    echo "GCP_PROJECT_ID=$GCP_PROJECT_ID" >> .env
fi

if [ -z "$GROQ_API_KEY" ] || [ "$GROQ_API_KEY" == "your_groq_api_key_here" ]; then
    echo -e "${RED}❌ GROQ_API_KEY is not set in .env file!${NC}"
    exit 1
fi

# Set defaults
REGION=${GCP_REGION:-us-central1}
ZONE=${GCP_ZONE:-us-central1-a}
IMAGE_NAME=${DOCKER_IMAGE_NAME:-study-buddy-ai}
IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest}
SERVICE_NAME=${IMAGE_NAME}-service

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed!${NC}"
    echo "Please install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Authenticate with GCP
echo -e "${GREEN}🔐 Authenticating with GCP...${NC}"
gcloud auth login --no-launch-browser
gcloud config set project $GCP_PROJECT_ID

# Enable required APIs
echo -e "${GREEN}🔧 Enabling required GCP APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Configure Docker for GCP
echo -e "${GREEN}🐳 Configuring Docker for GCP...${NC}"
gcloud auth configure-docker

# Build Docker image
echo -e "${GREEN}🏗️  Building Docker image...${NC}"
IMAGE_URL="gcr.io/${GCP_PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t $IMAGE_URL .

# Push image to GCR
echo -e "${GREEN}📤 Pushing image to Google Container Registry...${NC}"
docker push $IMAGE_URL

# Deploy to Cloud Run (serverless, easiest option)
echo -e "${GREEN}🚀 Deploying to Cloud Run...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_URL \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8501 \
    --memory 2Gi \
    --cpu 2 \
    --timeout 300 \
    --set-env-vars GROQ_API_KEY=$GROQ_API_KEY \
    --max-instances 10

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo ""
echo -e "${GREEN}✅ Deployment successful!${NC}"
echo -e "${GREEN}🌐 Your application is available at: ${SERVICE_URL}${NC}"
echo ""
echo "To update the deployment, run this script again."
echo "To view logs: gcloud run logs read $SERVICE_NAME --platform managed --region $REGION"


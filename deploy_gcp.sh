#!/bin/bash

# Study Buddy AI - Quick GCP Deployment Script
# This script quickly deploys the application to Google Cloud Platform

set -e  # Exit on error

echo "🚀 Deploying Study Buddy AI to GCP..."

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "⚠️  .env file not found. Using environment variables from shell."
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed"
    echo "   Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "   Install it from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Set default values if not provided
GCP_PROJECT_ID=${GCP_PROJECT_ID:-""}
GCP_REGION=${GCP_REGION:-"us-central1"}
IMAGE_NAME=${DOCKER_IMAGE_NAME:-"study-buddy-ai"}
IMAGE_TAG=${DOCKER_TAG:-"latest"}

# Get project ID if not set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "📋 Getting current GCP project..."
    GCP_PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -z "$GCP_PROJECT_ID" ]; then
        echo "❌ GCP_PROJECT_ID is not set"
        echo "   Set it in .env file or run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
fi

echo "📦 Project ID: $GCP_PROJECT_ID"
echo "🌍 Region: $GCP_REGION"

# Authenticate with GCP
echo "🔐 Authenticating with GCP..."
gcloud auth configure-docker --quiet

# Build Docker image
echo "🏗️  Building Docker image..."
docker build -t gcr.io/${GCP_PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG} .

# Push image to GCR
echo "📤 Pushing image to Google Container Registry..."
docker push gcr.io/${GCP_PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}

# Deploy to Cloud Run (easiest option)
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy ${IMAGE_NAME} \
    --image gcr.io/${GCP_PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG} \
    --platform managed \
    --region ${GCP_REGION} \
    --allow-unauthenticated \
    --port 8501 \
    --set-env-vars GROQ_API_KEY=${GROQ_API_KEY} \
    --memory 512Mi \
    --cpu 1 \
    --timeout 300 \
    --max-instances 10

echo ""
echo "✅ Deployment complete!"
echo "🌐 Your application is now running on Cloud Run"
echo "📋 Get the URL with: gcloud run services describe ${IMAGE_NAME} --region ${GCP_REGION} --format 'value(status.url)'"


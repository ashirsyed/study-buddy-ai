#!/bin/bash

# Fix Jenkins Docker Permission Issue
# This script fixes Docker permission denied errors in Jenkins

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Fixing Jenkins Docker permissions...${NC}"

# Check if Jenkins is running as service or in Docker
if systemctl is-active --quiet jenkins 2>/dev/null; then
    echo -e "${GREEN}✅ Jenkins is running as a service${NC}"
    JENKINS_TYPE="service"
elif docker ps | grep -q jenkins; then
    echo -e "${GREEN}✅ Jenkins is running in Docker${NC}"
    JENKINS_TYPE="docker"
    JENKINS_CONTAINER=$(docker ps | grep jenkins | awk '{print $1}' | head -1)
else
    echo -e "${RED}❌ Jenkins is not running!${NC}"
    echo "Please start Jenkins first."
    exit 1
fi

if [ "$JENKINS_TYPE" == "service" ]; then
    echo -e "${GREEN}📦 Adding jenkins user to docker group...${NC}"
    
    # Add jenkins user to docker group
    sudo usermod -aG docker jenkins
    
    # Restart Jenkins
    echo -e "${GREEN}🔄 Restarting Jenkins...${NC}"
    sudo systemctl restart jenkins
    
    echo -e "${GREEN}✅ Jenkins user added to docker group${NC}"
    echo -e "${GREEN}✅ Jenkins restarted${NC}"
    
elif [ "$JENKINS_TYPE" == "docker" ]; then
    echo -e "${GREEN}🐳 Fixing Docker permissions for Jenkins container...${NC}"
    
    # Check if container is running with docker socket mounted
    if docker inspect $JENKINS_CONTAINER | grep -q "/var/run/docker.sock"; then
        echo -e "${YELLOW}⚠️  Docker socket is mounted. Checking permissions...${NC}"
        
        # Check if running as root
        if docker exec $JENKINS_CONTAINER id -u | grep -q "^0$"; then
            echo -e "${GREEN}✅ Jenkins container is running as root - should work${NC}"
        else
            echo -e "${YELLOW}⚠️  Jenkins container is not running as root${NC}"
            echo -e "${GREEN}🔄 Restarting Jenkins container with proper permissions...${NC}"
            
            # Get current container config
            JENKINS_IMAGE=$(docker inspect $JENKINS_CONTAINER --format='{{.Config.Image}}')
            JENKINS_PORTS=$(docker port $JENKINS_CONTAINER | awk '{print $1}' | head -1)
            
            # Stop and remove container
            docker stop $JENKINS_CONTAINER
            docker rm $JENKINS_CONTAINER
            
            # Get docker group ID
            DOCKER_GID=$(getent group docker | cut -d: -f3)
            
            # Start Jenkins with proper permissions
            docker run -d \
              --name jenkins \
              -p 8080:8080 \
              -p 50000:50000 \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v $(which docker):/usr/bin/docker \
              -u root \
              -e DOCKER_GID=$DOCKER_GID \
              $JENKINS_IMAGE
            
            echo -e "${GREEN}✅ Jenkins container restarted with root user${NC}"
        fi
    else
        echo -e "${RED}❌ Docker socket is not mounted!${NC}"
        echo -e "${GREEN}🔄 Restarting Jenkins container with Docker socket...${NC}"
        
        # Get current container config
        JENKINS_IMAGE=$(docker inspect $JENKINS_CONTAINER --format='{{.Config.Image}}')
        
        # Stop and remove container
        docker stop $JENKINS_CONTAINER
        docker rm $JENKINS_CONTAINER
        
        # Get docker group ID
        DOCKER_GID=$(getent group docker | cut -d: -f3)
        
        # Start Jenkins with Docker socket
        docker run -d \
          --name jenkins \
          -p 8080:8080 \
          -p 50000:50000 \
          -v /var/run/docker.sock:/var/run/docker.sock \
          -v $(which docker):/usr/bin/docker \
          -u root \
          -e DOCKER_GID=$DOCKER_GID \
          $JENKINS_IMAGE
        
        echo -e "${GREEN}✅ Jenkins container restarted with Docker socket mounted${NC}"
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Docker permissions fixed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Wait a few seconds for Jenkins to start, then:"
echo "1. Access Jenkins: http://<VM_IP>:8080"
echo "2. Try running your pipeline again"
echo ""
echo "If issues persist, check Jenkins logs:"
if [ "$JENKINS_TYPE" == "service" ]; then
    echo "  sudo journalctl -u jenkins -f"
else
    echo "  docker logs jenkins -f"
fi


#!/bin/bash

# Jenkins Installation Script for VM
# This script installs Jenkins and required plugins

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Installing Jenkins...${NC}"

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo -e "${YELLOW}⚠️  Java not found. Installing Java 17...${NC}"
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk
fi

# Check if Jenkins is already installed
if command -v jenkins &> /dev/null || systemctl list-units | grep -q jenkins; then
    echo -e "${YELLOW}⚠️  Jenkins appears to be already installed${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Install Jenkins
echo -e "${GREEN}📦 Adding Jenkins repository...${NC}"
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo -e "${GREEN}📥 Updating package list...${NC}"
sudo apt-get update

echo -e "${GREEN}⬇️  Installing Jenkins...${NC}"
sudo apt-get install -y jenkins

# Add jenkins user to docker group (fix Docker permissions)
echo -e "${GREEN}👤 Adding jenkins user to docker group...${NC}"
sudo usermod -aG docker jenkins

# Start and enable Jenkins
echo -e "${GREEN}▶️  Starting Jenkins...${NC}"
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Wait for Jenkins to start
echo -e "${GREEN}⏳ Waiting for Jenkins to start...${NC}"
sleep 10

# Get initial admin password
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Jenkins Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Initial Admin Password:${NC}"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "1. Access Jenkins at: http://$(curl -s ifconfig.me):8080"
echo "2. Enter the password above"
echo "3. Install suggested plugins"
echo "4. Create admin user"
echo "5. Install additional plugins:"
echo "   - Docker Pipeline"
echo "   - Kubernetes CLI"
echo "   - Git"
echo "   - Credentials Binding"
echo "6. Fix Docker permissions (if needed):"
echo "   ./scripts/fix-jenkins-docker.sh"
echo ""
echo -e "${GREEN}Check Jenkins status:${NC}"
echo "  sudo systemctl status jenkins"
echo ""
echo -e "${GREEN}View Jenkins logs:${NC}"
echo "  sudo journalctl -u jenkins -f"


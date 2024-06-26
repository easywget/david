#!/bin/bash

# Update package information and install prerequisites
apt update
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Ensure the required directories and files are created
mkdir -p /etc/apt/keyrings

# Download and install the Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Get architecture and codename
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)

# Add Docker repository
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package information
apt update

# Install Docker packages
apt install -y docker-ce docker-ce-cli containerd.io docker-compose

# Pull the latest Portainer image
docker pull portainer/portainer-ce:latest

# Run Portainer container with time synchronization
docker run -d \
  -p 8000:8000 -p 9443:9443 \
  --name portainer \
  --restart=always \
  -e TZ=$(timedatectl show --property=Timezone --value) \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  portainer/portainer-ce:latest

# Pull the Minecraft server image
docker pull itzg/minecraft-server

# Run the Minecraft server container with time synchronization and logging configurations
docker run -d \
  --name minecraft-java \
  --restart=always \
  -e EULA=TRUE \
  -e MEMORY=8G \
  -p 25565:25565 \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  itzg/minecraft-server

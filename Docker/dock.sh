#!/bin/bash

# Get the current timezone
current_timezone=$(timedatectl show --property=Timezone --value)

# Echo the current timezone
echo "Current timezone: $current_timezone"

# Check if the current timezone is already set to Singapore
if [ "$current_timezone" != "Asia/Singapore" ]; then
    # Set the timezone to Singapore
    echo "Setting timezone to Asia/Singapore..."
    timedatectl set-timezone Asia/Singapore
else
    echo "The timezone is already set to Asia/Singapore."
fi

apt update && apt upgrade -y
# Install prerequisites
apt update
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Ensure the required directories and files are created
mkdir -p /etc/apt/keyrings

# Download and install the Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package information
apt update

# Install Docker packages
apt install -y docker-ce docker-ce-cli containerd.io docker-compose

# Pull the latest Portainer image
docker pull portainer/portainer-ce:latest

# Run Portainer container
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

# Run FileBrowser container
docker run -d \
  --name filebrowser \
  --restart unless-stopped \
  -e TZ=Asia/Singapore \
  -p 8080:80 \
  -v /:/srv \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  filebrowser/filebrowser

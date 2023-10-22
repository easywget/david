#!/bin/bash

# Set the time zone
timedatectl set-timezone Asia/Singapore

# Update package information and upgrade installed packages
apt update
apt upgrade -y
apt-get install curl -y

# Define the URLs of the scripts to download
file_urls=(
  "https://raw.githubusercontent.com/easywget/david/main/Docker/portainer.sh"
  "https://raw.githubusercontent.com/easywget/david/main/Docker/filebrowser.sh"
  #"https://raw.githubusercontent.com/easywget/david/main/Minecraft/minecraft_java.sh"
  #"https://raw.githubusercontent.com/easywget/david/main/Minecraft/minecraft_bedrock.sh"
)

# Loop through the URLs and download the scripts using curl
for url in "${file_urls[@]}"; do
    curl -sSL "$url" | bash
done

# Optionally, perform additional setup or tasks here if needed
# For example, install packages or configure settings.

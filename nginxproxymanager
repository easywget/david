#!/bin/bash

# Define the Docker Compose YAML file
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Define the directories
DATA_DIR="./data"
LETSENCRYPT_DIR="./letsencrypt"

# Check if the Docker Compose file already exists
if [ -e "$DOCKER_COMPOSE_FILE" ]; then
  echo "Docker Compose file '$DOCKER_COMPOSE_FILE' already exists."
  exit 1
fi

# Create the Docker Compose YAML file
cat > "$DOCKER_COMPOSE_FILE" <<EOL
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'     # Public HTTP Port
      - '443:443'   # Public HTTPS Port
      - '81:81'     # Admin Web Port

    environment:
      # Uncomment this if you want to change the location of
      # the SQLite DB file within the container
      # DB_SQLITE_FILE: "/data/database.sqlite"

      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'

    volumes:
      - $DATA_DIR:/data            # Data directory for Nginx Proxy Manager configurations and data
      - $LETSENCRYPT_DIR:/etc/letsencrypt   # Let's Encrypt SSL certificates
EOL

# Create the directories
mkdir -p "$DATA_DIR"
mkdir -p "$LETSENCRYPT_DIR"

# Provide instructions to the user
echo "Docker Compose YAML file '$DOCKER_COMPOSE_FILE' created."
echo "Directories '$DATA_DIR' and '$LETSENCRYPT_DIR' created."

# Optionally, you can provide additional instructions or steps here.

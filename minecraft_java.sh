#!/bin/bash

# Pull the Docker image
docker pull itzg/minecraft-server

# Start the Minecraft server in a Docker container
docker run -d \
  -e EULA=TRUE \
  -e JVM_DD_OPTS="-Duser.timezone=Asia/Singapore" \
  --name minecraft \
  -p 25565:25565 \
  -e MEMORY=4G \
  --restart=always \
  itzg/minecraft-server


# Optionally, you can add more instructions or commands here.

# End of the script

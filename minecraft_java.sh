#!/bin/bash

docker pull itzg/minecraft-server
docker run -d -e EULA=TRUE -p 25565:25565 --name minecraft-java --restart=always -e MEMORY=6G itzg/minecraft-server

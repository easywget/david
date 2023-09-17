#!/bin/bash
docker pull itzg/minecraft-server
docker run -d -e EULA=TRUE --name minecraft -p 25565:25565 --restart=always itzg/minecraft-server

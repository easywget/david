#!/bin/bash

docker pull itzg/minecraft-server
docker run -d -e EULA=TRUE -p 25565:25565 --name minecraft-java --restart=always -e MEMORY=4G itzg/minecraft-server
docker run -d -e EULA=TRUE -p 25565:25565 --name minecraft-java --restart=always -e MEMORY=4G --tty --interactive itzg/minecraft-server


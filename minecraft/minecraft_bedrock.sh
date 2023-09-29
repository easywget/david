#!/bin/bash
docker pull itzg/minecraft-bedrock-server
docker run -d -it -e EULA=TRUE --name minecraft-bedrock -p 19132:19132/udp --restart=always itzg/minecraft-bedrock-server

docker run -d -e EULA=TRUE -p 25565:25565 --name minecraft-container -e MEMORY=4G --tty --interactive -v minecraft-world-data:/data itzg/minecraft-server

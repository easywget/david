#!/bin/bash
timedatectl set-timezone Asia/Singapore
mkdir -p /var/www/downloads
apt update && apt upgrade -y

# Create the portainer.sh script 
echo '#!/bin/bash' > /var/www/downloads/portainer.sh
echo 'apt install ca-certificates curl gnupg lsb-release -y' >> /var/www/downloads/portainer.sh
echo 'mkdir -p /etc/apt/keyrings' >> /var/www/downloads/portainer.sh
echo 'curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg' >> /var/www/downloads/portainer.sh
echo 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null' >> /var/www/downloads/portainer.sh
echo 'apt update' >> /var/www/downloads/portainer.sh
echo 'apt install docker-ce docker-ce-cli containerd.io docker-compose -y' >> /var/www/downloads/portainer.sh
echo 'docker pull portainer/portainer-ce:latest' >> /var/www/downloads/portainer.sh
echo 'docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -e TZ=Asia/Singapore -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest' >> /var/www/downloads/portainer.sh
chmod +x /var/www/downloads/portainer.sh  # Make the portainer.sh script executable

# Create the filebrowser.sh script
echo '#!/bin/bash' > /var/www/downloads/filebrowser.sh
echo 'docker run -d --name filebrowser --restart unless-stopped -e TZ=Asia/Singapore -p 8080:80 -v /:/srv filebrowser/filebrowser' >> /var/www/downloads/filebrowser.sh
chmod +x /var/www/downloads/filebrowser.sh  # Make the filebrowser.sh script executable

# Create the apache.sh script
echo '#!/bin/bash' > /var/www/downloads/apache.sh
echo 'apt install apache2 -y' >> /var/www/downloads/apache.sh
echo 'systemctl start apache2' >> /var/www/downloads/apache.sh
echo 'systemctl enable apache2' >> /var/www/downloads/apache.sh
chmod +x /var/www/downloads/apache.sh  # Make the apache.sh script executable

# Create the minecraft_java.sh script

echo '#!/bin/bash' > /var/www/downloads/minecraft_java.sh
echo 'docker pull itzg/minecraft-server' > /var/www/downloads/minecraft_java.sh
echo 'docker run -d -e EULA=TRUE --name minecraft -p 25565:25565 --restart=always itzg/minecraft-server' > /var/www/downloads/minecraft_java.sh
chmod +x /var/www/downloads/minecraft_java.sh  # Make the minecraft_java.sh script executable

# Create the minecraft_bedrock.sh script

echo '#!/bin/bash' > /var/www/downloads/minecraft_bedrock.sh
echo 'docker pull itzg/minecraft-bedrock-server' > /var/www/downloads/minecraft_bedrock.sh
echo 'docker run -d -it -e EULA=TRUE --name minecraft-bedrock -p 19132:19132/udp --restart=always itzg/minecraft-bedrock-server' > /var/www/downloads/minecraft_bedrock.sh
chmod +x /var/www/downloads/minecraft_bedrock.sh  # Make the minecraft_bedrock.sh script executable

# Create the wget.sh script

echo '#!/bin/bash' > /var/www/downloads/wget.sh
echo 'file_urls=(' >> /var/www/downloads/wget.sh
echo '    "http://192.168.1.200/downloads/filebrowser.sh"' >> /var/www/downloads/wget.sh
echo '    "http://192.168.1.200/downloads/portainer.sh"' >> /var/www/downloads/wget.sh
echo '    "http://192.168.1.200/downloads/minecraft_bedrock.sh"' >> /var/www/downloads/wget.sh
echo '    "http://192.168.1.200/downloads/minecraft_java.sh"' >> /var/www/downloads/wget.sh
echo ')' >> /var/www/downloads/wget.sh
echo 'for url in "${file_urls[@]}"; do' >> /var/www/downloads/wget.sh
echo '    wget "$url"' >> /var/www/downloads/wget.sh
echo 'done' >> /var/www/downloads/wget.sh

echo 'chmod +x portainer.sh' >> wget.sh
echo 'chmod +x filebrowser.sh' >> wget.sh
echo 'chmod +x minecraft_java.sh' >> wget.sh
echo 'chmod +x minecraft_bedrock.sh' >> wget.sh

chmod +x /var/www/downloads/wget.sh

# Execute apache2.sh
/bin/bash /var/www/downloads/apache.sh

#!/bin/bash
apt update && apt upgrade -y
apt install ca-certificates curl gnupg lsb-release -y
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt install docker-ce docker-ce-cli containerd.io docker-compose -y
docker pull portainer/portainer-ce:latest
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -e TZ=$(timedatectl show --property=Timezone --value) -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
docker run -d --name filebrowser --restart unless-stopped -e TZ=Asia/Singapore -p 8080:80 -v /:/srv filebrowser/filebrowser

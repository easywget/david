# Create the wget.sh script

#!/bin/bash

timedatectl set-timezone Asia/Singapore
apt update && apt upgrade -y

file_urls=(
"http://192.168.1.200/portainer.sh"
"http://192.168.1.200/filebrowser.sh"
"http://192.168.1.200/minecraft_java.sh"
"http://192.168.1.200/minecraft_bedrock.sh"
)
for url in "${file_urls[@]}"; do
    wget "$url"
done

chmod +x portainer.sh
chmod +x filebrowser.sh
chmod +x minecraft_java.sh
chmod +x minecraft_bedrock.sh

# Create the wget.sh script

#!/bin/bash

timedatectl set-timezone Asia/Singapore
apt update && apt upgrade -y

file_urls=(
"https://github.com/easywget/david/blob/main/portainer.sh"
"https://github.com/easywget/david/blob/main/filebrowser.sh"
"https://github.com/easywget/david/blob/main/minecraft_java.sh"
"https://github.com/easywget/david/blob/main/minecraft_bedrock.sh"
)
for url in "${file_urls[@]}"; do
    wget "$url"
done

chmod +x portainer.sh
chmod +x filebrowser.sh
chmod +x minecraft_java.sh
chmod +x minecraft_bedrock.sh

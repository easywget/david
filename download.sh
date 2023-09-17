# Create the wget.sh script
#!/bin/bash

timedatectl set-timezone Asia/Singapore
apt update && apt upgrade -y

file_urls=(
"https://raw.githubusercontent.com/easywget/david/main/portainer.sh"
"https://raw.githubusercontent.com/easywget/david/main/filebrowser.sh"
"https://raw.githubusercontent.com/easywget/david/main/minecraft_java.sh"
"https://raw.githubusercontent.com/easywget/david/main/minecraft_bedrock.sh"
)
for url in "${file_urls[@]}"; do
    wget "$url"
done

chmod +x portainer.sh
chmod +x filebrowser.sh
chmod +x minecraft_java.sh
chmod +x minecraft_bedrock.sh

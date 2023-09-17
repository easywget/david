# Create the wget.sh script

#!/bin/bash
file_urls=(
"http://192.168.1.200/downloads/filebrowser.sh"
"http://192.168.1.200/downloads/portainer.sh"
"http://192.168.1.200/downloads/minecraft_bedrock.sh"
"http://192.168.1.200/downloads/minecraft_java.sh"
)
for url in "${file_urls[@]}"; do
    wget "$url"
done

chmod +x portainer.sh
chmod +x filebrowser.sh
chmod +x minecraft_java.sh
chmod +x minecraft_bedrock.sh

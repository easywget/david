# Pull the latest Portainer image
docker pull portainer/portainer-ce:latest

# Stop and remove the existing Portainer container (if it exists)
docker stop portainer
docker rm portainer

# Start a new Portainer container with the updated image and configurations
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -e TZ=$(timedatectl show --property=Timezone --value) -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

#!/bin/bash
#install docker, then portainer, file.
# Update and upgrade the system
apt-get install curl -y
apt update && apt upgrade -y

# Install AdGuard Home
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

# Install Unbound
apt install unbound -y

# Download Unbound configuration and save it as config.conf
curl https://raw.githubusercontent.com/easywget/david/main/AdGuardHome/config.conf -o /etc/unbound/unbound.conf.d/config.conf

# Restart the Unbound service to apply the new configuration
systemctl restart unbound

# Reboot the system
reboot

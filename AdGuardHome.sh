#!/bin/bash

# Update and upgrade the system
apt-get install curl -y
apt update && sudo apt upgrade -y

# Install AdGuard Home
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

# Reboot the system
reboot

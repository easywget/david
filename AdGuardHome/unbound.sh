#!/bin/bash

# Install Unbound
apt install unbound -y

reboot
#download the config.conf at /etc/unbound/unbound.conf.d
curl https://raw.githubusercontent.com/easywget/david/main/AdGuardHome/config.conf -o /etc/unbound/unbound.conf.d/config.conf

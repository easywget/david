#!/bin/bash

# Define variables
UPDATE_SCRIPT_URL="https://get.glennr.nl/unifi/update/unifi-update.sh"
UPDATE_SCRIPT="unifi-update.sh"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if it does not exist
install_package() {
    if ! command_exists "$1"; then
        echo "$1 is not installed. Installing..."
        apt-get update
        apt-get install -y "$1"
        if [[ $? -ne 0 ]]; then
            echo "Failed to install $1."
            exit 1
        fi
    else
        echo "$1 is already installed."
    fi
}

# Check and install sudo and curl
install_package "sudo"
install_package "curl"

# Function to check for updates
check_for_updates() {
    echo "Checking for updates..."
    curl -s -O $UPDATE_SCRIPT_URL
    if [[ $? -ne 0 ]]; then
        echo "Failed to download the update script."
        exit 1
    fi
}

# Function to run the update script
run_update_script() {
    echo "Running the update script..."
    sudo bash $UPDATE_SCRIPT
    if [[ $? -ne 0 ]]; then
        echo "Failed to run the update script."
        exit 1
    fi
}

# Main script execution
echo "Starting UniFi Controller update process..."

# Check for updates
check_for_updates

# Run the update script
run_update_script

echo "UniFi Controller update process completed."

# Clean up
rm -f $UPDATE_SCRIPT
echo "Cleanup completed."

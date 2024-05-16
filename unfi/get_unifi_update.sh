#!/bin/bash

# Define variables
UPDATE_SCRIPT_URL="https://get.glennr.nl/unifi/update/unifi-update.sh"
UPDATE_SCRIPT="unifi-update.sh"

# Function to check for updates
check_for_updates() {
    echo "Checking for updates..."
    wget -q --show-progress -O $UPDATE_SCRIPT $UPDATE_SCRIPT_URL
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

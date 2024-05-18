#!/bin/bash

SERVICE_FILE_PATH="/etc/systemd/system/gemini.service"
NGINX_CONFIG_PATH="/etc/nginx/sites-available/gemini"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled/gemini"
APP_FILE_PATH="/opt/gemini/gemini_app.py"
VENV_PATH="/opt/gemini/venv"
WORKING_DIRECTORY="/opt/gemini"

# Function to stop the gemini service
stop_service() {
    echo "Stopping gemini service..."
    systemctl stop gemini.service
    systemctl disable gemini.service
}

# Function to remove the gemini service file
remove_service_file() {
    if [ -f "$SERVICE_FILE_PATH" ]; then
        echo "Removing gemini service file..."
        rm "$SERVICE_FILE_PATH"
        systemctl daemon-reload
    else
        echo "Gemini service file does not exist. Skipping removal."
    fi
}

# Function to remove the NGINX configuration
remove_nginx_config() {
    if [ -f "$NGINX_ENABLED_PATH" ]; then
        echo "Removing NGINX configuration..."
        rm "$NGINX_ENABLED_PATH"
    fi
    if [ -f "$NGINX_CONFIG_PATH" ]; then
        rm "$NGINX_CONFIG_PATH"
        systemctl reload nginx
    else
        echo "NGINX configuration file does not exist. Skipping removal."
    fi
}

# Function to remove application files and virtual environment
remove_app_files() {
    echo "Removing application files and virtual environment..."
    rm -rf "$APP_FILE_PATH" "$VENV_PATH"
}

# Main function to orchestrate all tasks
main() {
    stop_service
    remove_service_file
    remove_nginx_config
    remove_app_files
    echo "Gemini service and related files have been removed successfully."
}

# Execute the main function
main

#!/bin/bash

APP_FILE_PATH="/opt/gemini/gemini_app.py"
SERVICE_FILE_PATH="/etc/systemd/system/gemini.service"
ENV_FILE_PATH="/opt/gemini/.env"
NGINX_CONFIG_PATH="/etc/nginx/sites-available/gemini"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled/gemini"

APP_CONTENT=$(cat <<'EOF'
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023

...
EOF
)

SERVICE_CONTENT=$(cat <<'EOF'
[Unit]
Description=Gemini Streamlit Service
After=network.target

[Service]
User=geminiuser
Group=geminiuser
WorkingDirectory=/opt/gemini
ExecStart=/opt/gemini/venv/bin/streamlit run /opt/gemini/gemini_app.py --server.port=8501
Restart=always

[Install]
WantedBy=multi-user.target
EOF
)

NGINX_CONFIG_CONTENT=$(cat <<'EOF'
server {
    listen 80;
    server_name your_domain_or_ip;

    location / {
        proxy_pass http://127.0.0.1:8501;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
)

# Function to create the application file if it doesn't exist
create_app_file() {
    if [ ! -f "$APP_FILE_PATH" ]; then
        echo "Creating application file..."
        echo "$APP_CONTENT" > "$APP_FILE_PATH"
        chown geminiuser:geminiuser "$APP_FILE_PATH"
    else
        echo "Application file already exists. Skipping creation."
    fi
}

# Function to create the service file if it doesn't exist
create_service_file() {
    if [ ! -f "$SERVICE_FILE_PATH" ]; then
        echo "Creating service file..."
        echo "$SERVICE_CONTENT" > "$SERVICE_FILE_PATH"
    else
        echo "Service file already exists. Skipping creation."
    fi
}

# Function to create the NGINX configuration file
create_nginx_config() {
    if [ ! -f "$NGINX_CONFIG_PATH" ]; then
        echo "Creating NGINX configuration file..."
        echo "$NGINX_CONFIG_CONTENT" > "$NGINX_CONFIG_PATH"
        sed -i "s/your_domain_or_ip/$(hostname -I | awk '{print $1}')/g" "$NGINX_CONFIG_PATH"
        ln -s "$NGINX_CONFIG_PATH" "$NGINX_ENABLED_PATH"
    else
        echo "NGINX configuration file already exists. Skipping creation."
    fi
}

# Function to check if the .env file exists, prompt the user for the key if it doesn't, and create the .env file
check_env_file() {
    if [ ! -f "$ENV_FILE_PATH" ]; then
        echo ".env file not found in /opt/gemini. Please enter your GOOGLE_API_KEY:"
        read -r GOOGLE_API_KEY
        echo "GOOGLE_API_KEY=$GOOGLE_API_KEY" > "$ENV_FILE_PATH"
        chown geminiuser:geminiuser "$ENV_FILE_PATH"
        echo ".env file created."
    else
        echo ".env file found."
    fi
}

# Function to reload systemd, enable, and start the service
start_service() {
    echo "Reloading systemd, enabling, and starting the gemini service..."
    systemctl daemon-reload
    systemctl enable gemini.service
    systemctl start gemini.service
}

# Function to restart NGINX
restart_nginx() {
    echo "Restarting NGINX..."
    systemctl restart nginx
}

# Main function to orchestrate all tasks
main() {
    create_app_file
    create_service_file
    create_nginx_config
    check_env_file
    start_service
    restart_nginx
    echo "Gemini service has been started successfully."
}

# Execute the main function
main

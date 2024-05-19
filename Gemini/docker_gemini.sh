#!/bin/bash

# Variables
PROJECT_DIR="/opt/gemini"
GOOGLE_API_KEY="your_google_api_key_here" # Replace with your actual API key

# Ensure necessary packages are installed
install_packages() {
    echo "Updating package lists and installing necessary packages..."
    apt-get update -y
    apt-get install -y docker.io docker-compose
}

# Create project directory
create_project_directory() {
    echo "Creating project directory..."
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
}

# Create docker-compose.yml
create_docker_compose_file() {
    echo "Creating docker-compose.yml..."
    cat <<EOF > $PROJECT_DIR/docker-compose.yml
version: '3.8'

services:
  streamlit:
    image: streamlit/streamlit
    container_name: gemini_streamlit
    volumes:
      - .:/app
    ports:
      - "8501:8501"
    command: streamlit run /app/gemini_app.py --server.port=8501 --server.address=0.0.0.0
    environment:
      - GOOGLE_API_KEY=\${GOOGLE_API_KEY}

  nginx:
    image: nginx
    container_name: gemini_nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
EOF
}

# Create nginx.conf
create_nginx_config_file() {
    echo "Creating nginx.conf..."
    cat <<EOF > $PROJECT_DIR/nginx.conf
events {}

http {
    server {
        listen 80;
        server_name 192.168.1.150;

        location / {
            proxy_pass http://streamlit:8501;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
}

# Create Streamlit application file
create_streamlit_app_file() {
    echo "Creating gemini_app.py..."
    cat <<EOF > $PROJECT_DIR/gemini_app.py
import streamlit as st

st.title('Gemini App')

st.write('This is a simple Streamlit application.')
EOF
}

# Create .env file
create_env_file() {
    echo "Creating .env file..."
    cat <<EOF > $PROJECT_DIR/.env
GOOGLE_API_KEY=$GOOGLE_API_KEY
EOF
}

# Start Docker Compose
start_docker_compose() {
    echo "Starting Docker Compose..."
    cd $PROJECT_DIR
    docker-compose up -d
}

# Main function to orchestrate all tasks
main() {
    install_packages
    create_project_directory
    create_docker_compose_file
    create_nginx_config_file
    create_streamlit_app_file
    create_env_file
    start_docker_compose
    echo "Gemini service has been set up successfully using Docker and Docker Compose."
}

# Execute the main function
main

#!/bin/bash

# Update and upgrade the system
apt update && apt upgrade -y

# Install Docker prerequisites
apt install ca-certificates curl gnupg lsb-release -y

# Create directory for Docker keyring
mkdir -p /etc/apt/keyrings

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list and install Docker
apt update
apt install docker-ce docker-ce-cli containerd.io docker-compose -y

# Start Docker service
systemctl start docker
systemctl enable docker

# Define variables
DOCKER_IMAGE_NAME="gemini-app"
APP_DIR="/opt/gemini"

# Create application directory
mkdir -p $APP_DIR
cd $APP_DIR

# Create Dockerfile
echo "Creating Dockerfile..."
cat <<EOF > Dockerfile
# Use the official Python image from the Docker Hub
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy the rest of the application files
COPY . .

# Set environment variables
ENV GOOGLE_API_KEY=your_google_api_key_here

# Expose the port that Streamlit uses
EXPOSE 8501

# Run the application
ENTRYPOINT ["streamlit", "run"]
CMD ["app.py"]
EOF

# Create requirements.txt
echo "Creating requirements.txt..."
cat <<EOF > requirements.txt
streamlit
python-dotenv
google-generativeai
pillow
EOF

# Create docker-compose.yml (optional)
echo "Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  gemini-app:
    build: .
    ports:
      - "8501:8501"
    environment:
      - GOOGLE_API_KEY=your_google_api_key_here
EOF

# Download app.py
echo "Downloading app.py script..."
wget https://raw.githubusercontent.com/easywget/david/main/Gemini/app.py -O app.py

# Prompt user to enter their Google API key
read -p "Enter your Google API key: " google_api_key
sed -i "s/your_google_api_key_here/$google_api_key/" Dockerfile
sed -i "s/your_google_api_key_here/$google_api_key/" docker-compose.yml

# Build the Docker image
echo "Building the Docker image..."
docker build -t $DOCKER_IMAGE_NAME .

# Run the Docker container
echo "Running the Docker container..."
docker run -p 8501:8501 -e GOOGLE_API_KEY=$google_api_key $DOCKER_IMAGE_NAME

# Optionally, if using Docker Compose
# echo "Running the Docker Compose setup..."
# docker-compose up --build

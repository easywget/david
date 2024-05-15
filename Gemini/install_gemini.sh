#!/bin/bash

# Install sudo if not already installed
apt-get install sudo -y

# Set the timezone to Singapore
sudo timedatectl set-timezone Asia/Singapore

# Update package lists
sudo apt-get update

# Install Python 3 and pip
sudo apt install python3-pip -y
sudo apt install python3.11-venv -y

# Create a user for running the service
sudo useradd -m -s /bin/bash geminiuser

# Create a virtual environment
python3 -m venv /opt/gemini/venv

# Activate the virtual environment
source /opt/gemini/venv/bin/activate

# Install necessary Python packages
pip install streamlit python-dotenv google-generativeai

# Download the application files
wget https://raw.githubusercontent.com/easywget/david/main/Gemini/app.py -O /opt/gemini/app.py

# Ensure the geminiuser owns the /opt/gemini directory
sudo chown -R geminiuser:geminiuser /opt/gemini

# Create the systemd service file
cat <<EOF | sudo tee /etc/systemd/system/gemini.service
[Unit]
Description=Streamlit Application
After=network.target

[Service]
Type=simple
User=geminiuser
Environment="PATH=/opt/gemini/venv/bin:/usr/bin"
ExecStart=/opt/gemini/venv/bin/streamlit run /opt/gemini/app.py
WorkingDirectory=/opt/gemini/
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the service
sudo systemctl daemon-reload
sudo systemctl enable gemini.service
sudo systemctl start gemini.service

# Check the status of the service
sudo systemctl status gemini.service

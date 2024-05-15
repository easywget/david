#!/bin/bash

# Set the timezone to Singapore
sudo timedatectl set-timezone Asia/Singapore

# Update package lists
apt-get update

# Install Python 3 and pip
apt install python3-pip -y
apt install python3.11-venv -y

# Create a virtual environment
python3 -m venv /opt/gemini/venv

# Activate the virtual environment
source /opt/gemini/venv/bin/activate

# Install necessary Python packages
pip install streamlit
pip install python-dotenv
pip install google-g


# Update package lists
apt-get update

# Install Python 3 and pip
apt install python3-pip -y
apt install python3.11-venv -y

# Create a virtual environment
python3 -m venv /opt/gemini/venv

# Activate the virtual environment
source /opt/gemini/venv/bin/activate

# Install necessary Python packages
pip install streamlit
pip install python-dotenv
pip install google-generativeai

# Download the application files
wget https://raw.githubusercontent.com/easywget/david/main/Gemini/app.py -O /opt/gemini/app.py

# Download the systemd service file
wget https://raw.githubusercontent.com/easywget/david/main/Gemini/gemini.service -O /etc/systemd/system/gemini.service

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable gemini.service
systemctl start gemini.service

# Activate the virtual environment and run the Streamlit app (if needed for manual start)
source /opt/gemini/venv/bin/activate
streamlit run /opt/gemini/app.py

#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt-get update && apt-get upgrade -y

# Install prerequisites
echo "Installing prerequisites..."
apt-get install -y wget build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl

# Download and install Python 3.4.10
echo "Installing Python 3.4.10..."
cd /usr/src
wget https://www.python.org/ftp/python/3.4.10/Python-3.4.10.tgz
tar xzf Python-3.4.10.tgz
cd Python-3.4.10
./configure --enable-optimizations
make altinstall

# Create and activate a virtual environment using Python 3.4
echo "Setting up virtual environment..."
/usr/local/bin/python3.4 -m ensurepip
/usr/local/bin/python3.4 -m venv venv
source venv/bin/activate

# Upgrade pip and install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install streamlit google-generativeai python-dotenv pillow

# Create .env file for environment variables
echo "Creating .env file..."
cat <<EOF > .env
GOOGLE_API_KEY=your_google_api_key_here
EOF

# Prompt user to enter their Google API key
read -p "Enter your Google API key: " google_api_key
sed -i "s/your_google_api_key_here/$google_api_key/" .env

# Download the app.py script
echo "Downloading app.py script..."
wget https://raw.githubusercontent.com/easywget/david/main/Gemini/app.py -O app.py

# Run the Streamlit application
echo "Starting the Streamlit application..."
streamlit run app.py

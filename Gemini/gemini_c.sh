#!/bin/bash

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Variables
path="/opt/gemini/"
location="/opt/gemini/app.py"
user_to_run="geminiuser"  # replace with a dedicated non-root username
service_name="gemini"
config_file="/opt/gemini/.env"  # Config file for storing environment variables

# Create a non-root user for running the service
if ! id "$user_to_run" &>/dev/null; then
    useradd -m -d "$path" -s /bin/bash "$user_to_run"
fi

# Install Python3 and pip if not installed
apt-get update
apt-get install -y python3 python3-pip

# Create virtual environment
python3 -m venv "$path"venv
source "$path"venv/bin/activate

# Create requirements.txt file for Python dependencies
cat > "$path"requirements.txt << EOF
streamlit
python-dotenv
google-generativeai
EOF

# Install Python dependencies from requirements.txt
pip install -r "$path"requirements.txt

# Check and create configuration file
if [ ! -f "$config_file" ]; then
    touch "$config_file"
    echo "GOOGLE_API_KEY=your_google_api_key_here" > "$config_file"
    chown "$user_to_run":"$user_to_run" "$config_file"
    chmod 600 "$config_file"
fi

# Create or update the Python script
cat > "$location" << 'EOF'
# [Python script content goes here]
EOF
chown "$user_to_run":"$user_to_run" "$location"

# Set up systemd service
service_path="/etc/systemd/system/${service_name}.service"
cat > "$service_path" << EOF
[Unit]
Description=Streamlit Application
After=network.target

[Service]
Type=simple
User=$user_to_run
ExecStart=$path/venv/bin/streamlit run $location
Restart=always
WorkingDirectory=$path

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable "$service_name"
systemctl start "$service_name" || echo "Failed to start $service_name service"

echo "Setup completed."

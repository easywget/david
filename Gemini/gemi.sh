#!/bin/bash

# Variables
location="/opt/gemini/app.py"
user_to_run="non_root_user"  # replace with your actual username for the service
service_name="gemini"
encoded_content="..."  # Base64 encoded content of app.py

# Check for Python3 installation
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed. Installing now..."
    apt-get update && apt-get install python3 -y
else
    echo "Python3 is already installed."
fi

# Check for pip installation
if ! command -v pip3 &> /dev/null; then
    echo "pip is not installed. Installing now..."
    apt-get install python3-pip -y
else
    echo "pip is already installed."
fi

# List of apps to check and install if necessary
declare -a apps=("streamlit" "python-dotenv" "google-generativeai")

for app in "${apps[@]}"; do
    if ! pip3 list | grep -q $app; then
        echo "$app is not installed. Installing now..."
        pip3 install "$app"
    else
        echo "$app is already installed."
    fi
done

# Check if app.py is at the specified location
if [ ! -f "$location" ]; then
    echo "app.py not found at $location. Generating now..."
    echo "$encoded_content" | base64 --decode > "$location"
    chown "$user_to_run":"$user_to_run" "$location"
else
    echo "app.py is already at $location."
fi

# Set up systemd service to run app.py as non-root user at startup
service_path="/etc/systemd/system/${service_name}.service"
bash -c "cat > $service_path <<EOF
[Unit]
Description=Streamlit Application
After=network.target

[Service]
Type=simple
User=$user_to_run
ExecStart=/usr/bin/streamlit run $location
Restart=always
WorkingDirectory=$(dirname $location)

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd to recognize the new service, enable it, and start it
systemctl daemon-reload
systemctl enable $service_name
systemctl start $service_name

#!/bin/bash

# Define variables
service_unit_file="/etc/systemd/system/gemini-streamlit.service"
current_username="$(whoami)"
streamlit_command="/usr/local/bin/streamlit"
app_script="/opt/gemini/app.py"

[ "$EUID" -ne 0 ]; then exit 1

# Create the systemd service unit file
cat <<EOF | tee "$service_unit_file" > /dev/null
[Unit]
Description=Streamlit Gemini Application
After=network.target

[Service]
Type=simple
ExecStart=$streamlit_command run $app_script
Restart=on-failure
User=$current_username
WorkingDirectory=$(dirname $app_script)

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd manager configuration
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable gemini-streamlit.service
sudo systemctl start gemini-streamlit.service

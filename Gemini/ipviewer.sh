#!/bin/bash

# Function to check if a package is installed
is_installed() {
    dpkg -s "$1" &> /dev/null
}

# Function to stop the gemini services if they are running
stop_services() {
    systemctl stop gemini_flask.service 2>/dev/null || true
    systemctl stop gemini_streamlit.service 2>/dev/null || true
    systemctl disable gemini_flask.service 2>/dev/null || true
    systemctl disable gemini_streamlit.service 2>/dev/null || true
    pkill -f "gunicorn -w 4 -b 0.0.0.0:5000" || true
    pkill -f "streamlit run /opt/gemini/streamlit_app.py" || true
}

# Function to remove existing service, app, and server files
remove_old_files() {
    rm -f /etc/systemd/system/gemini_flask.service
    rm -f /etc/systemd/system/gemini_streamlit.service
    rm -f /opt/gemini/flask_server.py
    rm -f /opt/gemini/streamlit_app.py
    echo "Removed old gemini_flask.service, gemini_streamlit.service, flask_server.py, and streamlit_app.py files."
}

# Function to set the timezone to Singapore
set_timezone() {
    current_timezone=$(timedatectl show -p Timezone --value)
    if [ "$current_timezone" != "Asia/Singapore" ]; then
        timedatectl set-timezone Asia/Singapore
        echo "Timezone set to Asia/Singapore."
    else
        echo "Timezone is already set to Asia/Singapore."
    fi
}

# Function to update package lists
update_packages() {
    apt-get update
}

# Function to install necessary packages
install_packages() {
    if ! is_installed python3-pip; then
        apt-get install -y python3-pip
    fi
    if ! is_installed python3.11-venv; then
        apt-get install -y python3.11-venv
    fi
    if ! is_installed git; then
        apt-get install -y git
    fi
    if ! is_installed ufw; then
        apt-get install -y ufw
    fi
}

# Function to create a user for running the service if it doesn't already exist
create_user() {
    if ! id -u geminiuser > /dev/null 2>&1; then
        useradd -m -s /bin/bash geminiuser
    fi
}

# Function to create necessary directories
create_directories() {
    if [ ! -d /opt/gemini ]; then
        mkdir -p /opt/gemini
        chown -R geminiuser:geminiuser /opt/gemini
        echo "Created /opt/gemini directory."
    else
        echo "/opt/gemini directory already exists."
    fi
}

# Function to create a virtual environment
create_virtualenv() {
    if [ ! -d /opt/gemini/venv ]; then
        su - geminiuser -c "python3 -m venv /opt/gemini/venv"
    fi
}

# Function to install necessary Python packages
install_python_packages() {
    su - geminiuser -c "
    source /opt/gemini/venv/bin/activate && \
    pip install --upgrade pip && \
    for pkg in streamlit python-dotenv google-generativeai requests flask gunicorn; do
        pip show \$pkg >/dev/null 2>&1 || pip install \$pkg
    done
    "
}

# Function to create the flask_server.py file
create_flask_server_file() {
    su - geminiuser -c "
    echo \"from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/get_ip', methods=['GET'])
def get_ip():
    client_ip = request.args.get('client_ip', request.remote_addr)
    return jsonify({'ip': client_ip})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)\" > /opt/gemini/flask_server.py
    "
}

# Function to create the gemini_flask.service file
create_flask_service_file() {
    echo "[Unit]
Description=Gemini Flask Service
After=network.target

[Service]
User=geminiuser
WorkingDirectory=/opt/gemini
ExecStart=/opt/gemini/venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 flask_server:app
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gemini_flask.service
}

# Function to create the streamlit_app.py file
create_streamlit_app_file() {
    su - geminiuser -c "
    echo \"import streamlit as st
import requests

# Function to get IP address from local Flask server
def get_ip(client_ip):
    try:
        response = requests.get(f'http://localhost:5000/get_ip?client_ip={client_ip}')
        ip = response.json()['ip']
        return ip
    except requests.RequestException:
        return 'Unable to get IP'

# Get the client's IP address from Streamlit's request headers
client_ip = st.query_params.get('client_ip', ['127.0.0.1'])[0]

# Streamlit app
st.title('Visitor\\'s IP Address')

# Fetch and display the IP address
ip_address = get_ip(client_ip)
st.write(f'Your IP address is: {ip_address}')\" > /opt/gemini/streamlit_app.py
    "
}

# Function to create the gemini_streamlit.service file
create_streamlit_service_file() {
    echo "[Unit]
Description=Gemini Streamlit Service
After=network.target

[Service]
User=geminiuser
WorkingDirectory=/opt/gemini
ExecStart=/opt/gemini/venv/bin/streamlit run /opt/gemini/streamlit_app.py --server.port 8501
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gemini_streamlit.service
}

# Function to reload systemd, enable, and start the services
start_services() {
    systemctl daemon-reload
    systemctl enable gemini_flask.service
    systemctl start gemini_flask.service
    systemctl enable gemini_streamlit.service
    systemctl start gemini_streamlit.service
}

# Function to check the status of the services
check_services_status() {
    systemctl status gemini_flask.service
    systemctl status gemini_streamlit.service
}

# Function to configure the firewall
configure_firewall() {
    if ! ufw status | grep -q "5000"; then
        ufw allow 5000
    fi
    if ! ufw status | grep -q "8501"; then
        ufw allow 8501
    fi
    ufw --force enable
    echo "Firewall configured to allow ports 5000 and 8501."
}

# Main function to orchestrate all tasks
main() {
    stop_services
    remove_old_files
    set_timezone
    update_packages
    install_packages
    create_user
    create_directories
    create_virtualenv
    install_python_packages
    create_flask_server_file
    create_flask_service_file
    create_streamlit_app_file
    create_streamlit_service_file
    #configure_firewall
    start_services
    check_services_status
    echo "Gemini services have been started/restarted successfully."
}

# Execute the main function
main


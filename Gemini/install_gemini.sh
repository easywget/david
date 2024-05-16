#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/easywget/david/main/Gemini"
SERVICE_FILE="gemini.service"
APP_FILE="gemini_app.py"

# Function to check if a package is installed
is_installed() {
    dpkg -s "$1" &> /dev/null
}

# Function to stop the gemini service if it is running
stop_service() {
    systemctl stop gemini.service
}

# Function to set the timezone to Singapore
set_timezone() {
    timedatectl set-timezone Asia/Singapore
}

# Function to update package lists
update_packages() {
    apt-get update
}

# Function to install necessary packages
install_packages() {
    apt-get install -y python3-pip python3.11-venv git
}

# Function to create a user for running the service if it doesn't already exist
create_user() {
    if ! id -u geminiuser > /dev/null 2>&1; then
        useradd -m -s /bin/bash geminiuser
    fi
}

# Function to create necessary directories
create_directories() {
    mkdir -p /opt/gemini
    chown -R geminiuser:geminiuser /opt/gemini
}

# Function to download the files from GitHub
download_files() {
    su - geminiuser -c "
    cd /opt/gemini && \
    wget ${REPO_URL}/${SERVICE_FILE} -O /etc/systemd/system/${SERVICE_FILE} && \
    wget ${REPO_URL}/${APP_FILE} -O /opt/gemini/${APP_FILE} && \
    chown -R geminiuser:geminiuser /opt/gemini
    "
}

# Function to create a virtual environment
create_virtualenv() {
    su - geminiuser -c "python3 -m venv /opt/gemini/venv"
}

# Function to install necessary Python packages
install_python_packages() {
    su - geminiuser -c "
    source /opt/gemini/venv/bin/activate && \
    pip install streamlit python-dotenv google-generativeai requests streamlit_js_eval
    "
}

# Function to reload systemd, enable, and start the service
start_service() {
    systemctl daemon-reload
    systemctl enable gemini.service
    systemctl start gemini.service
}

# Function to check the status of the service
check_service_status() {
    systemctl status gemini.service
}

# Main function to orchestrate all tasks
main() {
    stop_service
    set_timezone
    update_packages
    install_packages
    create_user
    create_directories
    download_files
    create_virtualenv
    install_python_packages
    start_service
    check_service_status
    echo "Gemini service has been started/restarted successfully."
}

# Execute the main function
main

#!/bin/bash

# Function to check if a package is installed
is_installed() {
    dpkg -s "$1" &> /dev/null
}

# Function to set the timezone to Singapore
set_timezone() {
    echo "Setting timezone to Asia/Singapore..."
    timedatectl set-timezone Asia/Singapore
}

# Function to update package lists
update_packages() {
    echo "Updating package lists..."
    apt-get update -y
}

# Function to install necessary packages
install_packages() {
    echo "Installing necessary packages..."
    for package in python3-pip python3.11-venv nginx net-tools curl ufw; do
        if ! is_installed "$package"; then
            apt-get install -y "$package"
        fi
    done
}

# Function to configure UFW
configure_ufw() {
    echo "Configuring UFW..."
    ufw allow 80/tcp
    ufw allow 8501/tcp
    ufw enable
}

# Function to create a user for running the service if it doesn't already exist
create_user() {
    echo "Creating user geminiuser if it doesn't exist..."
    if ! id -u geminiuser > /dev/null 2>&1; then
        useradd -m -s /bin/bash geminiuser
    fi
}

# Function to create necessary directories
create_directories() {
    if [ ! -d /opt/gemini ]; then
        echo "Creating necessary directories..."
        install -d -m 755 -o geminiuser -g geminiuser /opt/gemini
    else
        echo "Directory /opt/gemini already exists. Setting ownership and permissions..."
        chown -R geminiuser:geminiuser /opt/gemini
        chmod -R 755 /opt/gemini
    fi
}

# Function to create a virtual environment
create_virtualenv() {
    echo "Creating Python virtual environment..."
    if [ ! -d /opt/gemini/venv ]; then
        su - geminiuser -c "python3 -m venv /opt/gemini/venv"
    fi
}

# Function to install necessary Python packages
install_python_packages() {
    echo "Installing necessary Python packages..."
    su - geminiuser -c "
    source /opt/gemini/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install streamlit python-dotenv google-generativeai
    "
}

# Main function to orchestrate all tasks
main() {
    set_timezone
    update_packages
    install_packages
    configure_ufw
    create_user
    create_directories
    create_virtualenv
    install_python_packages
    echo "Setup completed successfully."
}

# Execute the main function
main

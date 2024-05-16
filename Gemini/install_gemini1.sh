#!/bin/bash

# Check if the gemini service exists
if systemctl list-unit-files --type=service | grep -q 'gemini.service'; then
    # Stop the gemini service if it is running
    systemctl stop gemini.service
    echo "Gemini service stopped."
else
    echo "Gemini service not found or not loaded."
fi



# Function to check if a package is installed
is_installed() {
    dpkg -s "$1" &> /dev/null
}

# Get the current timezone
current_timezone=$(timedatectl show --property=Timezone --value)

# Echo the current timezone
echo "Current timezone: $current_timezone"

# Check if the current timezone is already set to Singapore
if [ "$current_timezone" != "Asia/Singapore" ]; then
    # Set the timezone to Singapore
    echo "Setting timezone to Asia/Singapore..."
    timedatectl set-timezone Asia/Singapore
else
    echo "The timezone is already set to Asia/Singapore."
fi

# Update package lists
apt-get update

# Install Python 3 and pip if not already installed
if ! is_installed python3-pip; then
    apt install python3-pip -y
fi

if ! is_installed python3.11-venv; then
    apt install python3.11-venv -y
fi

# Create a user for running the service if it doesn't already exist
if ! id -u geminiuser > /dev/null 2>&1; then
    useradd -m -s /bin/bash geminiuser
fi

# Create the necessary directories
mkdir -p /opt/gemini
chown -R geminiuser:geminiuser /opt/gemini

# Check if the .env file already exists and contains the API key
if [ -f /opt/gemini/.env ] && grep -q "GOOGLE_API_KEY=" /opt/gemini/.env; then
    echo "GOOGLE_API_KEY is already set in the .env file."
else
    read -p "Enter your GOOGLE_API_KEY: " google_api_key
    echo "GOOGLE_API_KEY=${google_api_key}" > /opt/gemini/.env
    chown geminiuser:geminiuser /opt/gemini/.env
fi

# Create a virtual environment if it doesn't already exist
if [ ! -d /opt/gemini/venv ]; then
    su - geminiuser -c "python3 -m venv /opt/gemini/venv"
fi

# Activate the virtual environment and install necessary Python packages
su - geminiuser -c "
source /opt/gemini/venv/bin/activate
pip install streamlit python-dotenv google-generativeai
"

# Verify the installation
su - geminiuser -c "/opt/gemini/venv/bin/pip list"

# Check if the Streamlit application file exists
if [ -f /opt/gemini/gemini_app.py ]; then
    read -p "The file gemini_app.py already exists. Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "Skipping creation of gemini_app.py"
        create_app="false"
    else
        create_app="true"
    fi
else
    create_app="true"
fi

# Create the Streamlit application file if it doesn't exist or user chose to overwrite
if [ "$create_app" == "true" ]; then
    cat <<EOF > /opt/gemini/gemini_app.py
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023

Author: kuany
"""

from dotenv import load_dotenv
load_dotenv()  # Load all the environmental variables

import streamlit as st
import os
import google.generativeai as genai
from PIL import Image

# Ensure the GOOGLE_API_KEY is set
api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    st.error("GOOGLE_API_KEY environment variable not set")
    st.stop()

genai.configure(api_key=api_key)

# Initialize the models
text_model = genai.GenerativeModel('gemini-pro')
image_model = genai.GenerativeModel('gemini-pro-vision')

# Function to load Gemini Pro model and get responses
def get_gemini_response(model_option, question=None, image_input=None):
    if model_option == 'Yes':
        model = image_model
        if question:
            response = model.generate_content([question, image_input])
        else:
            response = model.generate_content(image_input)
    else:
        model = text_model
        response = model.generate_content(question)
    return response.text

# Initialize Streamlit app
st.set_page_config(page_title='Gemini Project', layout='wide')
st.header('Gemini Pro / Gemini Pro Vision')

col1, col2 = st.columns(2)

with col1:
    model_option = st.selectbox('Do you need to provide an image for your question?', ('No', 'Yes'))

    if 'model_option' not in st.session_state:
        st.session_state.model_option = model_option

    if 'submit_button' not in st.session_state:
        st.session_state.submit_button = ''
        st.session_state.input = ''
        st.session_state.clicked = False
        st.session_state.question_log = []
        st.session_state.response_log = []
        st.session_state.image_log = []

    if st.session_state.model_option != model_option:
        st.session_state.submit_button = ''
        st.session_state.input = ''
        st.session_state.clicked = False
        st.session_state.model_option = model_option

    input_text = st.text_area('Input: ', key='input')

    image = None
    if model_option == 'Yes':
        uploaded_file = st.file_uploader('Choose an image', type=['jpg', 'jpeg', 'png'])
        if uploaded_file:
            image = Image.open(uploaded_file)

    if st.button("Generate response"):
        st.session_state.question_input = input_text
        if image:
            response = get_gemini_response(model_option, st.session_state.question_input, image)
        else:
            response = get_gemini_response(model_option, st.session_state.question_input)

        st.subheader('Current question asked:')
        st.write(st.session_state.question_input)

        if image:
            st.image(image, caption='Uploaded Image', use_column_width=True)

        st.subheader('Current response is:')
        st.write(response)

        st.session_state.question_log.append(st.session_state.question_input)
        st.session_state.image_log.append(image)
        st.session_state.response_log.append(response)

with col2:
    st.subheader('Past Questions and Responses:')
    if st.button('Clear past responses'):
        st.session_state.question_log, st.session_state.image_log, st.session_state.response_log = [], [], []

    for index, (each_question, each_image, each_response) in enumerate(zip(st.session_state.question_log, st.session_state.image_log, st.session_state.response_log)):
        st.subheader(f'Question {index + 1}:')
        st.write(each_question)

        if each_image:
            st.subheader(f'Image {index + 1}:')
            st.image(each_image)

        st.subheader(f'Response {index + 1}:')
        st.write(each_response)
EOF

    chown geminiuser:geminiuser /opt/gemini/gemini_app.py
fi

# Create the systemd service file
cat <<EOF > /etc/systemd/system/gemini.service
[Unit]
Description=Streamlit Application
After=network.target

[Service]
Type=simple
User=geminiuser
Environment="PATH=/opt/gemini/venv/bin:/usr/bin"
ExecStart=/opt/gemini/venv/bin/streamlit run /opt/gemini/gemini_app.py
WorkingDirectory=/opt/gemini/
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the service
systemctl daemon-reload
systemctl enable gemini.service
systemctl start gemini.service

# Check the status of the service
systemctl status gemini.service

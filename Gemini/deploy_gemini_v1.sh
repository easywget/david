#!/bin/bash

APP_FILE_PATH="/opt/gemini/gemini_app.py"
SERVICE_FILE_PATH="/etc/systemd/system/gemini.service"
ENV_FILE_PATH="/opt/gemini/.env"
NGINX_CONFIG_PATH="/etc/nginx/sites-available/gemini"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled/gemini"
STREAMLIT_CONFIG_DIR="/opt/gemini/.streamlit"
STREAMLIT_CONFIG_FILE="/opt/gemini/.streamlit/config.toml"

APP_CONTENT=$(cat <<'EOF'
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023

"""

from dotenv import load_dotenv
load_dotenv()  ### Loading all the environmental variables

import streamlit as st
import os
import google.generativeai as genai
import subprocess

from PIL import Image

genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

text_model = genai.GenerativeModel('gemini-pro')
image_model = genai.GenerativeModel('gemini-pro-vision')

### Create a function to load Gemini Pro model and get responses
def get_gemini_response(model_option, question = None, image_input = None):
    if model_option == 'Yes':
        model = image_model
        if question != '':
            response = model.generate_content([question, image_input])
        else:
            response = model.generate_content(image_input)
    else:
        model = text_model
        response = model.generate_content(question)
    return response.text

### Function to get IP address from access.log
def get_ip_address():
    try:
        result = subprocess.run(['tail', '-n', '1', '/var/log/nginx/access.log'], stdout=subprocess.PIPE)
        log_entry = result.stdout.decode('utf-8')
        ip_address = log_entry.split(' ')[0]
        return ip_address
    except Exception as e:
        return "Unable to fetch IP address"

### Initialize our streamlit app
st.set_page_config(page_title = 'Gemini Project', layout='wide')

st.header('Gemini Pro / Gemini Pro Vision')

# Display user's IP address
ip_address = get_ip_address()
st.subheader(f'Your IP address is: {ip_address}')

col1, col2 = st.columns(2)

with col1:

    model_option = st.selectbox('Do you need to provide image for your question?', 
                                ('No', 'Yes'))
    
    if 'model_option' not in st.session_state:
        st.session_state.model_option = ''
        st.session_state.model_option = model_option
    
    if 'submit_button' not in st.session_state:
        st.session_state.submit_button = ''
        st.session_state.input = ''
        st.session_state.clicked = False
        st.session_state.question_log = []
        st.session_state.response_log = []
        st.session_state.image_log = []
        
    def click_button():
        st.session_state.clicked = True
        st.session_state.question_input = st.session_state.input
        st.session_state.input = ''
    
    if st.session_state.model_option != model_option:
        st.session_state.submit_button = ''
        st.session_state.input = ''
        st.session_state.clicked = False
        st.session_state.model_option = model_option
    
    image = ''
    
    input = st.text_area('Input: ', key='input')
    
    if model_option == 'Yes':
        uploaded_file = st.file_uploader('Choose an image', type=['jpg', 'jpeg', 'png'])
        image = ''
        if uploaded_file is not None:
            image = Image.open(uploaded_file)
    
    ### When submit is clicked
    if st.button("Generate response"):
        st.session_state.question_input = input
        if image != '':
            response = get_gemini_response(model_option, st.session_state.question_input, image)
        else:
            response = get_gemini_response(model_option, st.session_state.question_input)
        
        st.subheader('Current question asked:')
        st.write(st.session_state.question_input)
        
        if image != '':
            temp_image = st.empty()
            st.image(image, caption='Uploaded Image', use_column_width=True)
        
        st.subheader('Current response is')
        st.write(response)
        
        st.session_state.question_log.append(st.session_state.question_input)
        st.session_state.image_log.append(image)
        st.session_state.response_log.append(response)
    else:
        if image != '':
            temp_image = st.image(image, caption='Uploaded Image', use_column_width=True)

with col2:
    st.subheader('Past Questions and Responses:')
    if st.button('Clear past responses'):
        st.session_state.question_log, st.session_state.image_log, st.session_state.response_log = [], [], []
    for index, (each_question, each_image, each_response) in enumerate(zip(st.session_state.question_log, st.session_state.image_log, st.session_state.response_log)):
        st.subheader('Question {}:'.format(index + 1))
        st.write(each_question)
        
        if each_image != '':
            st.subheader('Image {}:'.format(index + 1))
            st.image(each_image)
        
        st.subheader('Response {}:'.format(index + 1))
        st.write(each_response)
    
    st.session_state.question_input = ''
EOF
)

SERVICE_CONTENT=$(cat <<'EOF'
[Unit]
Description=Gemini Streamlit Service
After=network.target

[Service]
User=geminiuser
Group=geminiuser
WorkingDirectory=/opt/gemini
ExecStart=/opt/gemini/venv/bin/streamlit run /opt/gemini/gemini_app.py --server.port=8501 --server.address=0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
EOF
)

NGINX_CONFIG_CONTENT=$(cat <<'EOF'
server {
    listen 80;
    server_name 45.119.154.169;

    location / {
        proxy_pass http://192.168.1.150:8501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Additional security headers (optional)
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
}
EOF
)

STREAMLIT_CONFIG_CONTENT=$(cat <<'EOF'
[server]
headless = true
port = 8501
enableCORS = false
enableXsrfProtection = false
EOF
)

# Function to create the application file
create_app_file() {
    echo "Creating application file..."
    echo "$APP_CONTENT" > "$APP_FILE_PATH"
    chown geminiuser:geminiuser "$APP_FILE_PATH"
}

# Function to create the service file
create_service_file() {
    echo "Creating service file..."
    echo "$SERVICE_CONTENT" > "$SERVICE_FILE_PATH"
}

# Function to create the NGINX configuration file
create_nginx_config() {
    echo "Creating NGINX configuration file..."
    echo "$NGINX_CONFIG_CONTENT" > "$NGINX_CONFIG_PATH"
    ln -sf "$NGINX_CONFIG_PATH" "$NGINX_ENABLED_PATH"
}

# Function to check if the .env file exists, prompt the user for the key if it doesn't, and create the .env file
check_env_file() {
    if [ ! -f "$ENV_FILE_PATH" ]; then
        echo ".env file not found in /opt/gemini. Please enter your GOOGLE_API_KEY:"
        read -r GOOGLE_API_KEY
        echo "GOOGLE_API_KEY=$GOOGLE_API_KEY" > "$ENV_FILE_PATH"
        chown geminiuser:geminiuser "$ENV_FILE_PATH"
        echo ".env file created."
    else
        echo ".env file found."
    fi
}

# Function to create the Streamlit configuration file
create_streamlit_config() {
    echo "Creating Streamlit configuration directory..."
    mkdir -p "$STREAMLIT_CONFIG_DIR"
    chown geminiuser:geminiuser "$STREAMLIT_CONFIG_DIR"

    echo "Creating Streamlit configuration file..."
    echo "$STREAMLIT_CONFIG_CONTENT" > "$STREAMLIT_CONFIG_FILE"
    chown geminiuser:geminiuser "$STREAMLIT_CONFIG_FILE"
}

# Function to reload systemd, enable, and start the service
start_service() {
    echo "Reloading systemd, enabling, and starting the gemini service..."
    systemctl daemon-reload
    systemctl enable gemini.service
    systemctl start gemini.service
}

# Function to restart NGINX
restart_nginx() {
    echo "Restarting NGINX..."
    systemctl restart nginx
}

# Main function to orchestrate all tasks
main() {
    create_app_file
    create_service_file
    create_nginx_config
    check_env_file
    create_streamlit_config
    start_service
    restart_nginx
    echo "Gemini service and related files have been set up successfully."
}

# Execute the main function
main

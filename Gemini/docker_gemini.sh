#!/bin/bash

# Variables
PROJECT_DIR="/opt/gemini"

# Ensure necessary packages are installed
install_packages() {
    echo "Updating package lists and installing necessary packages..."
    apt-get update -y
    apt-get install -y docker.io docker-compose
}

# Create project directory
create_project_directory() {
    echo "Creating project directory..."
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
}

# Create docker-compose.yml
create_docker_compose_file() {
    echo "Creating docker-compose.yml..."
    cat <<EOF > $PROJECT_DIR/docker-compose.yml
version: '3.8'

services:
  streamlit:
    image: streamlit/streamlit
    container_name: gemini_streamlit
    volumes:
      - .:/app
    ports:
      - "8501:8501"
    command: streamlit run /app/gemini_app.py --server.port=8501 --server.address=0.0.0.0
    environment:
      - GOOGLE_API_KEY=\${GOOGLE_API_KEY}

  nginx:
    image: nginx
    container_name: gemini_nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
EOF
}

# Create nginx.conf
create_nginx_config_file() {
    echo "Creating nginx.conf..."
    cat <<EOF > $PROJECT_DIR/nginx.conf
events {}

http {
    server {
        listen 80;
        server_name 192.168.1.150;

        location / {
            proxy_pass http://streamlit:8501;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
}

# Create Streamlit application file
create_streamlit_app_file() {
    echo "Creating gemini_app.py..."
    cat <<EOF > $PROJECT_DIR/gemini_app.py
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023

@author: kuany
"""

from dotenv import load_dotenv
load_dotenv() ### Loading all the environmental variables

import streamlit as st
import os
import google.generativeai as genai

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

### Initialize our streamlit app
st.set_page_config(page_title = 'Gemini Project', layout='wide')

st.header('Gemini Pro / Gemini Pro Vision')

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
    
    # input = st.text_input('Input: ', key='input', on_change=click_button)
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
}

# Create .env file
create_env_file() {
    echo "Creating .env file..."
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        echo ".env file not found in $PROJECT_DIR. Please enter your GOOGLE_API_KEY:"
        read -r GOOGLE_API_KEY
        echo "GOOGLE_API_KEY=$GOOGLE_API_KEY" > "$PROJECT_DIR/.env"
        echo ".env file created."
    else
        echo ".env file found."
    fi
}

# Start Docker Compose
start_docker_compose() {
    echo "Starting Docker Compose..."
    cd $PROJECT_DIR
    docker-compose up -d
}

# Main function to orchestrate all tasks
main() {
    install_packages
    create_project_directory
    create_docker_compose_file
    create_nginx_config_file
    create_streamlit_app_file
    create_env_file
    start_docker_compose
    echo "Gemini service has been set up successfully using Docker and Docker Compose."
}

# Execute the main function
main

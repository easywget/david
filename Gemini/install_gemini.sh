#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y python3 python3-venv python3-pip curl

# Create and activate a virtual environment
echo "Setting up virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install streamlit python-dotenv google-generative-ai pillow

# Create .env file for environment variables
echo "Creating .env file..."
cat <<EOF > .env
GOOGLE_API_KEY=your_google_api_key_here
EOF

## Prompt user to enter their Google API key
#read -p "Enter your Google API key: " google_api_key
#sed -i "s/your_google_api_key_here/$google_api_key/" .env

# Download the app.py script (or copy from a local source)
echo "Downloading app.py script..."
cat <<'EOF' > app.py
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023

@author: kuany
"""

from dotenv import load_dotenv
load_dotenv()  # Loading all the environmental variables

import streamlit as st
import os
import google.generativeai as genai
from PIL import Image

genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

text_model = genai.GenerativeModel('gemini-pro')
image_model = genai.GenerativeModel('gemini-pro-vision')

# Create a function to load Gemini Pro model and get responses
def get_gemini_response(model_option, question=None, image_input=None):
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

# Initialize our Streamlit app
st.set_page_config(page_title='Gemini Project', layout='wide')

st.header('Gemini Pro / Gemini Pro Vision')

col1, col2 = st.columns(2)

with col1:
    model_option = st.selectbox('Do you need to provide an image for your question?', ('No', 'Yes'))

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

    # When submit is clicked
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

# Create systemd service file
echo "Creating systemd service file..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/gemini.service
[Unit]
Description=Streamlit Gemini Application
After=network.target

[Service]
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/venv/bin/streamlit run $(pwd)/app.py
Restart=always
RestartSec=10
Environment="GOOGLE_API_KEY=$google_api_key"

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd to apply the new service file
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling gemini service to start on boot..."
sudo systemctl enable gemini.service

# Start the gemini service
echo "Starting gemini service..."
sudo systemctl start gemini.service

# Check the status of the service
echo "Checking gemini service status..."
sudo systemctl status gemini.service

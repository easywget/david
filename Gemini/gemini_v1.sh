#!/bin/bash

# Variables
path="/opt/gemini/"
location="/opt/gemini/app.py"
user_to_run="root"  # replace with your actual username for the service
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
    mkdir -p $path
    echo "app.py not found at $location. Generating now..."
    
    cat << 'EOF' > /opt/gemini/app.py
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
ExecStart=/usr/local/bin/streamlit run $location
Restart=always
WorkingDirectory=$path

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd to recognize the new service, enable it, and start it
systemctl daemon-reload
systemctl enable $service_name
systemctl start $service_name

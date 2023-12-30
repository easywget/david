#!/bin/bash
#for debain.

# Default GitHub URL
github="add github/other link here"

# Changes here to install more packages.
PIP_PACKAGES=(
    "streamlit"
    "python-dotenv"
    "google-generativeai"
)

#check program
check_python(){
	if python3 --version &> /dev/null; then
		echo "Python is already installed. Version:"
		python3 --version
	else
		echo "Python is not installed. Installing Python."
		apt update
		apt install python3 -y
	fi
}

check_pip() {
	if pip3 --version &> /dev/null; then
		echo "pip is already installed. Version:"
		pip3 --version
	else
		echo "pip is not installed. Installing pip."
		apt install python3-pip -y
	fi
}

install_components(){
	for package in "${PIP_PACKAGES[@]}"; do
		echo "Installing $package..."
		pip install "$package"
	done
}

check_app_file(){
	echo "Do you want to download app.py from a specific URL? (y/n)"
	read -r download_choice
	
	if [ "download_choice" = "y" ]; then
		echo "Current default URL is: $github"
		echo "Would you like to use this URL? (y/n)"	
		read -r use_default_url
		if [ "$use_default_url" != "y" ]; then
			echo "Enter the new URL to download app.py (e.g., GitHub raw URL):"
			read -r github
		fi			
		download_app "$github"
	else
		generate_app
	fi
}

download_app(){
	local url=$1
	echo "Downloading app.py from $url..."
	# Try downloading with curl first
	if ! curl -o app.py "$url"; then
		echo "curl failed to download, trying wget..."
		# If curl fails, try downloading with wget
		if ! wget -O app.py "$url"; then
			echo "Download failed with both curl and wget."
			exit 1
		fi
	fi
}

generate_app(){
	echo "Generating app.py locally..."
	cat << 'EOF' > app.py

# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023
version chuchu
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

run_app() {
	#run gemini
	streamlit run app.py
}

check_python
check_pip
install_components
check_app_file
run_app

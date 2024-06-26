# -*- coding: utf-8 -*-
"""
Created on Sat Dec 23 10:12:47 2023

Author: kuany
"""

import streamlit as st
import os
import google.generativeai as genai
from PIL import Image
from dotenv import load_dotenv
from streamlit_js_eval import streamlit_js_eval

st.set_page_config(page_title='Gemini Project', layout='wide')

load_dotenv()  # Load all the environmental variables

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

# JavaScript to get the client IP address
ip_script = """
async function getUserIP() {
  const response = await fetch('https://api64.ipify.org?format=json');
  const data = await response.json();
  return data.ip;
}
getUserIP();
"""

# Embed the JavaScript in the Streamlit app
client_ip = streamlit_js_eval(ip_script, key="ip_script")

# Initialize Streamlit app
st.header('Gemini Pro / Gemini Pro Vision')

# Display the client's IP address
st.write(f"Your IP address is: {client_ip}")

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

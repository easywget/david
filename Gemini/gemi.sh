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
ExecStart=/usr/bin/streamlit run $location
Restart=always
WorkingDirectory=$path

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd to recognize the new service, enable it, and start it
systemctl daemon-reload
systemctl enable $service_name
systemctl start $service_name

encoded_content='''[IyAtKi0gY29kaW5nOiB1dGYtOCAtKi0NCiIiIg0KQ3JlYXRlZCBvbiBTYXQgRGVjIDIzIDEwOjEy
OjQ3IDIwMjMNCg0KQGF1dGhvcjoga3VhbnkNCiIiIg0KDQpmcm9tIGRvdGVudiBpbXBvcnQgbG9h
ZF9kb3RlbnYNCmxvYWRfZG90ZW52KCkgIyMjIExvYWRpbmcgYWxsIHRoZSBlbnZpcm9ubWVudGFs
IHZhcmlhYmxlcw0KDQppbXBvcnQgc3RyZWFtbGl0IGFzIHN0DQppbXBvcnQgb3MNCmltcG9ydCBn
b29nbGUuZ2VuZXJhdGl2ZWFpIGFzIGdlbmFpDQoNCmZyb20gUElMIGltcG9ydCBJbWFnZQ0KDQpn
ZW5haS5jb25maWd1cmUoYXBpX2tleT1vcy5nZXRlbnYoIkdPT0dMRV9BUElfS0VZIikpDQoNCnRl
eHRfbW9kZWwgPSBnZW5haS5HZW5lcmF0aXZlTW9kZWwoJ2dlbWluaS1wcm8nKQ0KaW1hZ2VfbW9k
ZWwgPSBnZW5haS5HZW5lcmF0aXZlTW9kZWwoJ2dlbWluaS1wcm8tdmlzaW9uJykNCg0KIyMjIENy
ZWF0ZSBhIGZ1bmN0aW9uIHRvIGxvYWQgR2VtaW5pIFBybyBtb2RlbCBhbmQgZ2V0IHJlc3BvbnNl
cw0KZGVmIGdldF9nZW1pbmlfcmVzcG9uc2UobW9kZWxfb3B0aW9uLCBxdWVzdGlvbiA9IE5vbmUs
IGltYWdlX2lucHV0ID0gTm9uZSk6DQogICAgaWYgbW9kZWxfb3B0aW9uID09ICdZZXMnOg0KICAg
ICAgICBtb2RlbCA9IGltYWdlX21vZGVsDQogICAgICAgIGlmIHF1ZXN0aW9uICE9ICcnOg0KICAg
ICAgICAgICAgcmVzcG9uc2UgPSBtb2RlbC5nZW5lcmF0ZV9jb250ZW50KFtxdWVzdGlvbiwgaW1h
Z2VfaW5wdXRdKQ0KICAgICAgICBlbHNlOg0KICAgICAgICAgICAgcmVzcG9uc2UgPSBtb2RlbC5n
ZW5lcmF0ZV9jb250ZW50KGltYWdlX2lucHV0KQ0KICAgIGVsc2U6DQogICAgICAgIG1vZGVsID0g
dGV4dF9tb2RlbA0KICAgICAgICByZXNwb25zZSA9IG1vZGVsLmdlbmVyYXRlX2NvbnRlbnQocXVl
c3Rpb24pDQogICAgcmV0dXJuIHJlc3BvbnNlLnRleHQNCg0KIyMjIEluaXRpYWxpemUgb3VyIHN0
cmVhbWxpdCBhcHANCnN0LnNldF9wYWdlX2NvbmZpZyhwYWdlX3RpdGxlID0gJ0dlbWluaSBQcm9q
ZWN0JywgbGF5b3V0PSd3aWRlJykNCg0Kc3QuaGVhZGVyKCdHZW1pbmkgUHJvIC8gR2VtaW5pIFBy
byBWaXNpb24nKQ0KDQpjb2wxLCBjb2wyID0gc3QuY29sdW1ucygyKQ0KDQp3aXRoIGNvbDE6DQoN
CiAgICBtb2RlbF9vcHRpb24gPSBzdC5zZWxlY3Rib3goJ0RvIHlvdSBuZWVkIHRvIHByb3ZpZGUg
aW1hZ2UgZm9yIHlvdXIgcXVlc3Rpb24/JywgDQogICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICgnTm8nLCAnWWVzJykpDQogICAgDQogICAgaWYgJ21vZGVsX29wdGlvbicgbm90IGluIHN0
LnNlc3Npb25fc3RhdGU6DQogICAgICAgIHN0LnNlc3Npb25fc3RhdGUubW9kZWxfb3B0aW9uID0g
JycNCiAgICAgICAgc3Quc2Vzc2lvbl9zdGF0ZS5tb2RlbF9vcHRpb24gPSBtb2RlbF9vcHRpb24N
CiAgICANCiAgICBpZiAnc3VibWl0X2J1dHRvbicgbm90IGluIHN0LnNlc3Npb25fc3RhdGU6DQog
ICAgICAgIHN0LnNlc3Npb25fc3RhdGUuc3VibWl0X2J1dHRvbiA9ICcnDQogICAgICAgIHN0LnNl
c3Npb25fc3RhdGUuaW5wdXQgPSAnJw0KICAgICAgICBzdC5zZXNzaW9uX3N0YXRlLmNsaWNrZWQg
PSBGYWxzZQ0KICAgICAgICBzdC5zZXNzaW9uX3N0YXRlLnF1ZXN0aW9uX2xvZyA9IFtdDQogICAg
ICAgIHN0LnNlc3Npb25fc3RhdGUucmVzcG9uc2VfbG9nID0gW10NCiAgICAgICAgc3Quc2Vzc2lv
bl9zdGF0ZS5pbWFnZV9sb2cgPSBbXQ0KICAgICAgICANCiAgICBkZWYgY2xpY2tfYnV0dG9uKCk6
DQogICAgICAgIHN0LnNlc3Npb25fc3RhdGUuY2xpY2tlZCA9IFRydWUNCiAgICAgICAgc3Quc2Vz
c2lvbl9zdGF0ZS5xdWVzdGlvbl9pbnB1dCA9IHN0LnNlc3Npb25fc3RhdGUuaW5wdXQNCiAgICAg
ICAgc3Quc2Vzc2lvbl9zdGF0ZS5pbnB1dCA9ICcnDQogICAgDQogICAgaWYgc3Quc2Vzc2lvbl9z
dGF0ZS5tb2RlbF9vcHRpb24gIT0gbW9kZWxfb3B0aW9uOg0KICAgICAgICBzdC5zZXNzaW9uX3N0
YXRlLnN1Ym1pdF9idXR0b24gPSAnJw0KICAgICAgICBzdC5zZXNzaW9uX3N0YXRlLmlucHV0ID0g
JycNCiAgICAgICAgc3Quc2Vzc2lvbl9zdGF0ZS5jbGlja2VkID0gRmFsc2UNCiAgICAgICAgc3Qu
c2Vzc2lvbl9zdGF0ZS5tb2RlbF9vcHRpb24gPSBtb2RlbF9vcHRpb24NCiAgICANCiAgICBpbWFn
ZSA9ICcnDQogICAgDQogICAgIyBpbnB1dCA9IHN0LnRleHRfaW5wdXQoJ0lucHV0OiAnLCBrZXk9
J2lucHV0Jywgb25fY2hhbmdlPWNsaWNrX2J1dHRvbikNCiAgICBpbnB1dCA9IHN0LnRleHRfYXJl
YSgnSW5wdXQ6ICcsIGtleT0naW5wdXQnKQ0KICAgIA0KICAgIGlmIG1vZGVsX29wdGlvbiA9PSAn
WWVzJzoNCiAgICAgICAgdXBsb2FkZWRfZmlsZSA9IHN0LmZpbGVfdXBsb2FkZXIoJ0Nob29zZSBh
biBpbWFnZScsIHR5cGU9WydqcGcnLCAnanBlZycsICdwbmcnXSkNCiAgICAgICAgaW1hZ2UgPSAn
Jw0KICAgICAgICBpZiB1cGxvYWRlZF9maWxlIGlzIG5vdCBOb25lOg0KICAgICAgICAgICAgaW1h
Z2UgPSBJbWFnZS5vcGVuKHVwbG9hZGVkX2ZpbGUpDQogICAgDQogICAgIyMjIFdoZW4gc3VibWl0
IGlzIGNsaWNrZWQNCiAgICBpZiBzdC5idXR0b24oIkdlbmVyYXRlIHJlc3BvbnNlIik6DQogICAg
ICAgIHN0LnNlc3Npb25fc3RhdGUucXVlc3Rpb25faW5wdXQgPSBpbnB1dA0KICAgICAgICBpZiBp
bWFnZSAhPSAnJzoNCiAgICAgICAgICAgIHJlc3BvbnNlID0gZ2V0X2dlbWluaV9yZXNwb25zZSht
b2RlbF9vcHRpb24sIHN0LnNlc3Npb25fc3RhdGUucXVlc3Rpb25faW5wdXQsIGltYWdlKQ0KICAg
ICAgICBlbHNlOg0KICAgICAgICAgICAgcmVzcG9uc2UgPSBnZXRfZ2VtaW5pX3Jlc3BvbnNlKG1v
ZGVsX29wdGlvbiwgc3Quc2Vzc2lvbl9zdGF0ZS5xdWVzdGlvbl9pbnB1dCkNCiAgICAgICAgDQog
ICAgICAgIHN0LnN1YmhlYWRlcignQ3VycmVudCBxdWVzdGlvbiBhc2tlZDonKQ0KICAgICAgICBz
dC53cml0ZShzdC5zZXNzaW9uX3N0YXRlLnF1ZXN0aW9uX2lucHV0KQ0KICAgICAgICANCiAgICAg
ICAgaWYgaW1hZ2UgIT0gJyc6DQogICAgICAgICAgICB0ZW1wX2ltYWdlID0gc3QuZW1wdHkoKQ0K
ICAgICAgICAgICAgc3QuaW1hZ2UoaW1hZ2UsIGNhcHRpb249J1VwbG9hZGVkIEltYWdlJywgdXNl
X2NvbHVtbl93aWR0aD1UcnVlKQ0KICAgICAgICANCiAgICAgICAgc3Quc3ViaGVhZGVyKCdDdXJy
ZW50IHJlc3BvbnNlIGlzJykNCiAgICAgICAgc3Qud3JpdGUocmVzcG9uc2UpDQogICAgICAgIA0K
ICAgICAgICBzdC5zZXNzaW9uX3N0YXRlLnF1ZXN0aW9uX2xvZy5hcHBlbmQoc3Quc2Vzc2lvbl9z
dGF0ZS5xdWVzdGlvbl9pbnB1dCkNCiAgICAgICAgc3Quc2Vzc2lvbl9zdGF0ZS5pbWFnZV9sb2cu
YXBwZW5kKGltYWdlKQ0KICAgICAgICBzdC5zZXNzaW9uX3N0YXRlLnJlc3BvbnNlX2xvZy5hcHBl
bmQocmVzcG9uc2UpDQogICAgZWxzZToNCiAgICAgICAgaWYgaW1hZ2UgIT0gJyc6DQogICAgICAg
ICAgICB0ZW1wX2ltYWdlID0gc3QuaW1hZ2UoaW1hZ2UsIGNhcHRpb249J1VwbG9hZGVkIEltYWdl
JywgdXNlX2NvbHVtbl93aWR0aD1UcnVlKQ0KDQp3aXRoIGNvbDI6DQogICAgc3Quc3ViaGVhZGVy
KCdQYXN0IFF1ZXN0aW9ucyBhbmQgUmVzcG9uc2VzOicpDQogICAgaWYgc3QuYnV0dG9uKCdDbGVh
ciBwYXN0IHJlc3BvbnNlcycpOg0KICAgICAgICBzdC5zZXNzaW9uX3N0YXRlLnF1ZXN0aW9uX2xv
Zywgc3Quc2Vzc2lvbl9zdGF0ZS5pbWFnZV9sb2csIHN0LnNlc3Npb25fc3RhdGUucmVzcG9uc2Vf
bG9nID0gW10sIFtdLCBbXQ0KICAgIGZvciBpbmRleCwgKGVhY2hfcXVlc3Rpb24sIGVhY2hfaW1h
Z2UsIGVhY2hfcmVzcG9uc2UpIGluIGVudW1lcmF0ZSh6aXAoc3Quc2Vzc2lvbl9zdGF0ZS5xdWVz
dGlvbl9sb2csIHN0LnNlc3Npb25fc3RhdGUuaW1hZ2VfbG9nLCBzdC5zZXNzaW9uX3N0YXRlLnJl
c3BvbnNlX2xvZykpOg0KICAgICAgICBzdC5zdWJoZWFkZXIoJ1F1ZXN0aW9uIHt9OicuZm9ybWF0
KGluZGV4ICsgMSkpDQogICAgICAgIHN0LndyaXRlKGVhY2hfcXVlc3Rpb24pDQogICAgICAgIA0K
ICAgICAgICBpZiBlYWNoX2ltYWdlICE9ICcnOg0KICAgICAgICAgICAgc3Quc3ViaGVhZGVyKCdJ
bWFnZSB7fTonLmZvcm1hdChpbmRleCArIDEpKQ0KICAgICAgICAgICAgc3QuaW1hZ2UoZWFjaF9p
bWFnZSkNCiAgICAgICAgDQogICAgICAgIHN0LnN1YmhlYWRlcignUmVzcG9uc2Uge306Jy5mb3Jt
YXQoaW5kZXggKyAxKSkNCiAgICAgICAgc3Qud3JpdGUoZWFjaF9yZXNwb25zZSkNCiAgICANCiAg
ICBzdC5zZXNzaW9uX3N0YXRlLnF1ZXN0aW9uX2lucHV0ID0gJycNCg==
]'''

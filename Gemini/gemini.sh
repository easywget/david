#!/bin/bash

apt-get update
apt install python3-pip -y
apt install python3.11-venv -y
python3 -m venv /opt/gemini/venv
source /opt/gemini/venv/bin/activate
pip install streamlit
pip install python-dotenv
pip install google-generativeai

wget https://raw.githubusercontent.com/easywget/david/main/Gemini/app.py -O /opt/gemini/app.py

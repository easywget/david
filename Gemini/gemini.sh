#!/bin/bash

#check if python3 is installed
python3 --version

#install python3
apt update
apt install python3 -y

#install pip
apt install python3-pip -y

pip install streamlit
pip install python-dotenv
pip install google-generativeai

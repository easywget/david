#!/bin/bash

#check if python3 is installed
python3 --version

#install python3
sudo apt update
sudo apt install python3 -y

#install pip
sudo apt install python3-pip -y

pip install streamlit
pip install python-dotenv
pip google-generativeai

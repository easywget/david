#!/bin/bash

# Create the streamlit_app.py file
cat <<EOL > /opt/gemini/streamlit_app.py
import streamlit as st
import sqlite3
from datetime import datetime

# Function to log visitor information
def log_visitor(ip, user_agent, timestamp):
    conn = sqlite3.connect('/opt/visitor/visitors.db')
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO visitors (ip, user_agent, timestamp) VALUES (?, ?, ?)
    ''', (ip, user_agent, timestamp))
    conn.commit()
    cursor.execute('SELECT COUNT(*) FROM visitors')
    visitor_count = cursor.fetchone()[0]
    conn.close()
    return visitor_count

# Get visitor information
ip = st.experimental_get_query_params().get('REMOTE_ADDR', ['Unknown'])[0]
user_agent = st.experimental_get_query_params().get('HTTP_USER_AGENT', ['Unknown'])[0]
timestamp = datetime.now()

# Log visitor information
visitor_count = log_visitor(ip, user_agent, timestamp)

# Display the welcome message
st.title("Welcome to my site (8051)")
st.write(f"You are visitor number {visitor_count}. Your IP is {ip}.")
EOL

echo "streamlit_app.py has been created."

# Create the visitor_app.py file
cat <<EOL > /opt/visitor/visitor_app.py
from flask import Flask, request
from datetime import datetime
import sqlite3

app = Flask(__name__)

def init_db():
    conn = sqlite3.connect('/opt/visitor/visitors.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS visitors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ip TEXT,
            user_agent TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return "Visitor Tracker is running."

if __name__ == '__main__':
    init_db()
    app.run(debug=True, port=5000)  # Adjust port if needed
EOL

echo "visitor_app.py has been created."

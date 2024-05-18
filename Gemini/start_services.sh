#!/bin/bash

# Function to start the Flask application (Visitor Tracker)
start_flask() {
    echo "Starting Flask application..."
    su - geminiuser -c "source /opt/visitor/venv/bin/activate && nohup python /opt/visitor/visitor_app.py > /opt/visitor/visitor_app.log 2>&1 &"
}

# Function to start the Streamlit application (Gemini)
start_streamlit() {
    echo "Starting Streamlit application..."
    su - geminiuser -c "source /opt/gemini/venv/bin/activate && nohup streamlit run /opt/gemini/streamlit_app.py --server.port 8051 > /opt/gemini/streamlit_app.log 2>&1 &"
}

# Start both services
start_flask
start_streamlit

echo "Both services have been started."

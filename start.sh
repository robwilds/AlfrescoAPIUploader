#!/bin/bash

# Alfresco API Uploader - Startup Script (Linux/macOS)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "=== Alfresco API Uploader ==="
echo ""
echo "How would you like to run the app?"
echo "  1) Local (Python)"
echo "  2) Docker"
echo ""
read -p "Enter choice [1-2]: " CHOICE

case "$CHOICE" in
    2)
        if ! command -v docker &> /dev/null; then
            echo "Error: Docker is not installed. Please install Docker and try again."
            exit 1
        fi

        echo "Building Docker image..."
        docker build -t alfresco-uploader . || { echo "Docker build failed."; exit 1; }

        echo "Starting container on http://localhost:5001"
        docker run -d --name alfresco-uploader -p 5001:5001 alfresco-uploader

        echo ""
        echo "Alfresco API Uploader is running in Docker!"
        echo "Press Ctrl+C to stop the container."
        echo ""

        # Open the web page
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open http://localhost:5001
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open http://localhost:5001
        fi

        trap "docker stop alfresco-uploader 2>/dev/null && docker rm alfresco-uploader 2>/dev/null; echo 'Container stopped.'; exit 0" INT

        # Tail container logs to keep script alive
        docker logs -f alfresco-uploader
        ;;
    1|"")
        # Start the Flask app directly without virtual environment
        # Try both python and python3 (for cross-platform compatibility)
        echo "Checking Python installation..."
        PYTHON_CMD=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
        if [ -z "$PYTHON_CMD" ]; then
            echo "Error: Python 3 not found. Please install Python 3 and try again."
            exit 1
        fi
        echo "Using: $PYTHON_CMD"
        
        echo "Starting backend server on http://localhost:5001"
        pip install -r requirements.txt > /dev/null 2>&1
        
        # Replace 'python' with the detected python3 binary
        $PYTHON_CMD backend.py &
        BACKEND_PID=$!

        # Wait a moment for server to start
        sleep 2

        # Open the web page
        echo "Opening web interface..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open http://localhost:5001
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open http://localhost:5001
        fi

        echo ""
        echo "Alfresco API Uploader is running!"
        echo "Backend PID: $BACKEND_PID"
        echo "Press Ctrl+C to stop the server"
        echo ""

        # Trap Ctrl+C to kill background process
        trap "kill $BACKEND_PID 2>/dev/null; echo 'Server stopped.'; exit 0" INT

        # Wait for background process
        wait $BACKEND_PID
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

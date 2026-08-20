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

        # Ensure the Docker daemon is running.
        if ! docker info &> /dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "Docker daemon is not running. Trying to start Docker Desktop..."
                open -a Docker
                sleep 5
                if ! docker info &> /dev/null; then
                    echo "Docker Desktop did not start. Please launch it manually from your Applications folder."
                    exit 1
                fi
                echo "Docker Desktop started."
            else
                echo "Starting Docker daemon..."
                if ! command -v sudo &> /dev/null; then
                    echo "Error: 'sudo' not found. Please start the Docker daemon manually."
                    exit 1
                fi
                sudo dockerd > /dev/null 2>&1 &
                sleep 3
                if ! docker info &> /dev/null; then
                    echo "Docker daemon failed to start. Please start it manually."
                    exit 1
                fi
                echo "Docker daemon started."
            fi
        fi

        # If the container is already running, just open it instead of rebuilding.
        if docker ps --filter "name=alfresco-uploader" --format '{{.Names}}' | grep -qx 'alfresco-uploader'; then
            echo "Alfresco API Uploader container is already running on http://localhost:5001"
            # Open the web page
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open http://localhost:5001
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                xdg-open http://localhost:5001
            fi
            exit 0
        fi

        echo "How would you like to launch the container?"
        echo "  1) Automatically (build + run, then tail logs)"
        echo "  2) Build only (start it manually later)"
        read -p "Enter choice [1-2] (default 1): " DOLLAUNCH
        case "$DOLLAUNCH" in
            1|"") DOLLAUNCH=1 ;;
            2) DOLLAUNCH=2 ;;
            *) echo "Invalid choice. Defaulting to auto-launch."; DOLLAUNCH=1 ;;
        esac

        if [ "$DOLLAUNCH" = "1" ]; then
            echo "Building Docker image..."
            docker build -t alfresco-uploader . || { echo "Docker build failed."; exit 1; }

            echo "Starting container on http://localhost:5001"
            docker run -d --name alfresco-uploader -p 5001:5001 alfresco-uploader || { echo "Failed to start container."; exit 1; }

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
        else
            echo "Building Docker image..."
            docker build -t alfresco-uploader . || { echo "Docker build failed."; exit 1; }

            echo "Container built. Start it manually:"
            echo "  docker run -p 5001:5001 alfresco-uploader"
        fi
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

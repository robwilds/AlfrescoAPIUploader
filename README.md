# Alfresco API Uploader

A Python backend with HTML/JS frontend for uploading files to Alfresco via REST API.

## Setup

```bash
pip install -r requirements.txt
```

## Run

```bash
python backend.py
```

Then open http://localhost:5001 in your browser.

## Quick Start

```bash
# Option 1: Run locally (with choice prompt)
# Windows: start.bat
# Linux: start.sh

# Option 2: Run Docker (recommended for production)
./start.sh   # prompts for Local vs Docker; Docker auto-launches
```

### Start scripts behavior

Both `start.sh` (Linux/macOS) and `start.bat` (Windows) prompt for **Local (Python)** or **Docker**, then:

- **Docker**: auto-launches the container if not already running, auto-starts the Docker daemon when needed, and opens the browser. Re-running while the container is up just reopens it without rebuilding. On Windows, Ctrl+C stops and removes the container.
- **Local**: installs dependencies (if missing), then runs the Flask app on http://localhost:5001.

## Features

- Two-card layout: Connection (URL, username, password) and Folder & API settings
- Test connection before uploading
- Select multiple files or entire folders
- Upload to specified folder (default: `-my-`)
- Sidebar folder browser with back navigation
- Click folders to browse sub-folders
- Click files or folders to open directly in Alfresco Share UI
- Upload results with per-file status and "Open in Alfresco" links
- Dark mode toggle (persisted in localStorage)

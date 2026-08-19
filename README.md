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
docker build -t alfresco-uploader .
docker run -p 5001:5001 alfresco-uploader
```

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

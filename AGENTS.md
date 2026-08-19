# Agent Instructions: Alfresco API Uploader

## Quick Start

```bash
pip install -r requirements.txt
python backend.py
```

Open `http://localhost:5001` (not 5000). Development server runs on port 5001 by default.

## Running with Docker

```bash
docker build -t alfresco-uploader .
docker run -p 5001:5001 alfresco-uploader
```

Or with docker-compose:

```bash
docker compose up --build
```

`start.sh` and `start.bat` prompt for local vs Docker on launch.

## Architecture

- **Single Python app**: `backend.py` is the only code file. Flask handles all logic.
- **Embedded frontend**: Single HTML/JS file at `frontend/index.html`. Served via static directory in Flask config (no separate build).
- **Upload temp folder**: `/tmp/alfresco_uploads` (auto-created by werkzeug)
- **Dockerfile**: Uses `python:3.11-slim`, copies `backend.py` and `frontend/` into `/app`.

## API Endpoints

### POST /api/upload
- Required form fields: `alfresco_url`, `files` (multipart), `username`, `password`, `target_folder`, `api_path`
- Default target folder: `-my-` (user's current folder)
- Default API path: `/alfresco/api/-default-/public/alfresco/versions/1`
- Supports uploading to nodeRef targets (extracts UUID from `workspace://SpacesStore/{uuid}`)
- Returns per-file results including `share_url` for opening in Alfresco Share

### POST /api/test-connection
- Accepts JSON body with connection credentials
- Tests connectivity via HTTP GET to `"{url}{api_path}/nodes/-my-"`

### GET /api/list-folder
- Query params: `alfresco_url`, `target_folder`, `api_path`, `username`, `password`
- Calls Alfresco `GET .../nodes/{target_folder}/children` with `depth=0`
- Supports nodeRef targets: extracts UUID from `workspace://SpacesStore/{uuid}` before building API URL
- Returns `{success, folder, entries: [{name, nodeId, isFolder, shareUrl, size}], totalEntries}`
- `shareUrl` is a direct link to open the item in Alfresco Share: `{server}/share/page/document-details?nodeRef=workspace://SpacesStore/{nodeId}`
- Used by the sidebar folder browser panel

## Frontend

- **Two-card layout**: Connection card (URL, username, password) and Folder & API card (target folder, API path, buttons)
- **Folder browser**: Sidebar panel with back navigation, breadcrumb path display, and click-to-navigate into sub-folders
- **Open in Alfresco**: Each file/folder entry has a link icon that opens the item in Alfresco Share UI in a new tab. Files also open on row click.
- **Dark mode**: Toggle button persists preference in localStorage. Styles cover cards, inputs, buttons, sidebar, and all status indicators.

## Authentication

Basic Auth (`username`, `password`). Always test connection before bulk uploads.

## Key Constraints

- No separate frontend build step needed (Flask serves static files directly)
- All file uploads are processed client-side; backend handles HTTP upload to Alfresco
- Results returned as JSON with per-file status, errors, and Share URLs included
- HTML data attributes use kebab-case (`data-node-id`, `data-share-url`) because `dataset` API maps `data-node-id` → `dataset.nodeId`

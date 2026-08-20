# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A Flask web app with an embedded HTML/JS frontend that lets users authenticate to an Alfresco server (Basic Auth) and upload local files into a chosen folder. No separate frontend build step. Detailed operational notes live in [`AGENTS.md`](./AGENTS.md) — read it first.

## Commands

```bash
pip install -r requirements.txt   # flask, requests, werkzeug
python backend.py                 # run on http://localhost:5001 (debug=True, host 0.0.0.0)
```

- `start.sh` / `start.bat` prompt for **Local** (Python) vs **Docker** and auto-open the browser.
- Docker: `docker build -t alfresco-uploader .` then `docker run -p 5001:5001 alfresco-uploader`.
- There is **no linter, no test runner, and no test suite** in this repo. Do not add CI/pytest scaffolding unless the user asks.

## Architecture (the parts that span files)

- **`backend.py`** — a single-file Flask app. `static_folder` is pointed at `frontend/`, so `GET /` serves `frontend/index.html` directly (`backend.py:14-16`). No separate static route needed.
- **`frontend/index.html`** — the entire UI. It contains all CSS *and* the full JS DOM logic inline; there are no imported assets. The backend has no awareness of JS beyond three endpoints.
- **Data flow is entirely client-driven**: the UI holds the credentials, target folder, and selected files. On submit it POSTs everything to the backend, which does the HTTP work and returns JSON. The backend never reads the local filesystem except `/tmp/alfresco_uploads` (a werkzeug upload temp dir, `backend.py:11-12`).

### Backend endpoints

- **`POST /api/upload`** — the core path. Reads form fields `alfresco_url`, `username`, `password`, `target_folder`, `api_path` plus multipart `files`. Uploads each file to `.../nodes/{target_folder}/children` (POST).
  - `target_folder` may be a plain node id (`-my-`) **or** a full node ref (`workspace://SpacesStore/{uuid}`). When it starts with `workspace://`/`cmp://`, the backend strips to the last path segment to use as the node id (`backend.py:44-47`).
  - On HTTP 200/201 it parses the returned `entry.id`, builds a `share_url`, and reports per-file status. Any non-2xx or exception is recorded as a per-file error with the raw response body — uploads are **per-file, not all-or-nothing**.
  - The upload prints the request URL, status, and body to stdout (`backend.py:54-57`) — useful when debugging but noisy.
- **`POST /api/test-connection`** — JSON body; GETs `.../nodes/-my-` with a 10s timeout and returns success/failure.
- **`GET /api/list-folder`** — query params; GETs `.../nodes/{folder}/children?depth=0` and returns `{success, folder, entries:[{name, nodeId, isFolder, shareUrl, size}], totalEntries}`. Powers the sidebar folder browser.

### Frontend behaviors worth knowing

- **Dark mode**: toggled by a fixed button; the class is `body.dark`. Preference is read from and written to `localStorage` key `alfresco-uploader-theme`, defaulting to dark (`index.html:962-964`).
- **Folder browser**: `listFolderBtn` opens a fixed sidebar with back navigation. Navigation pushes onto `folderHistory` and calls `listFolderContents`.
- **`data-*` kebab-case convention**: HTML uses `data-node-id` / `data-share-url` on `.dir-entry` (read via `this.dataset.nodeId`), and `data-share-url` on result rows. This exists because the `dataset` API lowercases/dashes keys — matching the backend's JSON key casing (`node_id`/`share_url`). New JS ↔ JSON ↔ `data-*` bindings must keep these in sync.
- **Share URLs** are built as `{server}/share/page/document-details?nodeRef=workspace://SpacesStore/{nodeId}`.

## Conventions & gotchas

- Port is **5001** (not Flask's default 5000). Keep it that way; the startup scripts and README reference it.
- Credentials are passed over the wire in `FormData`/JSON with no obfuscation — expected for this tool but no server-side secrets exist.
- No validation library, no auth, no CSRF protection. If adding features, match this deliberately-simple posture rather than introducing a framework.

from flask import Flask, request, jsonify, send_from_directory
import os
import requests
from werkzeug.utils import secure_filename

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FRONTEND_DIR = os.path.join(BASE_DIR, 'frontend')

app = Flask(__name__, static_folder=FRONTEND_DIR)

UPLOAD_FOLDER = '/tmp/alfresco_uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/')
def index():
    return send_from_directory(FRONTEND_DIR, 'index.html')

@app.route('/api/upload', methods=['POST'])
def upload_to_alfresco():
    alfresco_url = request.form.get('alfresco_url', '').rstrip('/')
    username = request.form.get('username', '')
    password = request.form.get('password', '')
    target_folder = request.form.get('target_folder', '-my-')
    api_path = request.form.get('api_path', '/alfresco/api/-default-/public/alfresco/versions/1').rstrip('/')

    if not alfresco_url:
        return jsonify({'error': 'Alfresco server URL is required'}), 400

    files = request.files.getlist('files')
    if not files:
        return jsonify({'error': 'No files selected'}), 400

    results = []
    session = requests.Session()
    session.auth = (username, password)

    for uploaded_file in files:
        if uploaded_file.filename == '':
            continue

        filename = secure_filename(uploaded_file.filename)
        file_content = uploaded_file.read()

        target_id = target_folder
        if target_id.startswith('workspace://') or target_id.startswith('cmp://'):
            target_id = target_id.rsplit('/', 1)[-1]
        upload_url = f"{alfresco_url}{api_path}/nodes/{target_id}/children"

        files_data = {
            'filedata': (filename, file_content, uploaded_file.content_type)
        }

        try:
            print(f"Uploading to: {upload_url}")
            response = session.post(upload_url, files=files_data)
            print(f"Response status: {response.status_code}")
            print(f"Response body: {response.text}")

            if response.status_code in (200, 201):
                response_json = response.json()
                entry = response_json.get('entry', {})
                node_id = entry.get('id', 'unknown')
                share_url = f"{alfresco_url}/share/page/document-details?nodeRef=workspace://SpacesStore/{node_id}"

                results.append({'file': filename, 'status': 'success', 'response': response_json, 'node_id': node_id, 'share_url': share_url})
            else:
                results.append({'file': filename, 'status': 'error', 'error': response.text, 'code': response.status_code})
        except Exception as e:
            results.append({'file': filename, 'status': 'error', 'error': str(e)})

    return jsonify({'results': results})

@app.route('/api/test-connection', methods=['POST'])
def test_connection():
    alfresco_url = request.json.get('alfresco_url', '').rstrip('/')
    username = request.json.get('username', '')
    password = request.json.get('password', '')
    api_path = request.json.get('api_path', '/alfresco/api/-default-/public/alfresco/versions/1').rstrip('/')

    if not alfresco_url:
        return jsonify({'error': 'Alfresco server URL is required'}), 400

    try:
        test_url = f"{alfresco_url}{api_path}/nodes/-my-"
        print(f"Testing connection to: {test_url}")
        response = requests.get(test_url, auth=(username, password), timeout=10)

        if response.status_code == 200:
            return jsonify({'success': True, 'message': 'Connection successful', 'tested_url': test_url})
        else:
            return jsonify({'success': False, 'error': f'HTTP {response.status_code}: {response.text}', 'tested_url': test_url})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e), 'tested_url': test_url if 'test_url' in locals() else 'unknown'})

@app.route('/api/list-folder', methods=['GET'])
def list_folder():
    alfresco_url = request.args.get('alfresco_url', '').rstrip('/')
    target_folder = request.args.get('target_folder', '-my-')
    api_path = request.args.get('api_path', '/alfresco/api/-default-/public/alfresco/versions/1').rstrip('/')
    username = request.args.get('username', '')
    password = request.args.get('password', '')

    if not alfresco_url:
        return jsonify({'error': 'Alfresco server URL is required'}), 400

    try:
        folder_id = target_folder

        if folder_id.startswith('workspace://') or folder_id.startswith('cmp://'):
            folder_id = folder_id.rsplit('/', 1)[-1]

        listing_url = f"{alfresco_url}{api_path}/nodes/{folder_id}/children"

        listing_response = requests.get(listing_url, auth=(username, password), params={'depth': '0'}, timeout=10)
        response = listing_response

        if response.status_code in (200, 207):
            data = response.json()

            entries = []
            list_data = data.get('list', data)
            raw_entries = list_data.get('entries', [])

            for item in raw_entries:
                entry = item.get('entry', item)
                name = entry.get('name', 'Unknown')
                node_id = entry.get('id', '')
                is_folder = entry.get('isFolder', False)
                node_type = entry.get('nodeType', '')

                size = 0
                content = entry.get('content', {})
                if content and isinstance(content, dict):
                    size = content.get('sizeInBytes', 0)

                if not is_folder and isinstance(node_type, str) and 'folder' in node_type.lower():
                    is_folder = True

                share_url = f"{alfresco_url}/share/page/document-details?nodeRef=workspace://SpacesStore/{node_id}"

                entries.append({
                    'name': name,
                    'nodeId': node_id,
                    'isFolder': is_folder,
                    'shareUrl': share_url,
                    'size': size,
                })

            return jsonify({
                'success': True,
                'folder': target_folder,
                'entries': entries,
                'totalEntries': len(entries),
            })
        else:
            return jsonify({
                'success': False,
                'error': f'HTTP {response.status_code}: {response.text}',
                'code': response.status_code,
            })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e), 'folder': target_folder})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)

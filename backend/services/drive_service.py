import os
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

def get_drive_service():
    scopes = ["https://www.googleapis.com/auth/drive"]
    sa_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_PATH")
    sa_json_str = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON")
    if sa_path and os.path.exists(sa_path):
        creds = service_account.Credentials.from_service_account_file(sa_path, scopes=scopes)
    elif sa_json_str:
        cred_dict = json.loads(sa_json_str)
        creds = service_account.Credentials.from_service_account_info(cred_dict, scopes=scopes)
    else:
        raise ValueError("Google Service Account credentials not provided.")
    return build("drive", "v3", credentials=creds)

def upload_to_drive(drive_service, filename: str, date_str: str) -> tuple:
    try:
        folder_name = f"Job_Scrapes_{date_str}"
        query = f"mimeType='application/vnd.google-apps.folder' and name='{folder_name}' and trashed=false"
        results = drive_service.files().list(q=query, spaces="drive", fields="files(id, webViewLink)").execute()
        items = results.get("files", [])
        if not items:
            folder_metadata = {"name": folder_name, "mimeType": "application/vnd.google-apps.folder"}
            folder = drive_service.files().create(body=folder_metadata, fields="id, webViewLink").execute()
            folder_id = folder.get("id")
            folder_url = folder.get("webViewLink")
        else:
            folder_id = items[0].get("id")
            folder_url = items[0].get("webViewLink")
        file_metadata = {"name": os.path.basename(filename), "parents": [folder_id]}
        media = MediaFileUpload(filename, resumable=True)
        file = drive_service.files().create(body=file_metadata, media_body=media, fields="id, webViewLink").execute()
        file_id = file.get("id")
        file_url = file.get("webViewLink")
        permission = {"type": "anyone", "role": "reader"}
        drive_service.permissions().create(fileId=file_id, body=permission).execute()
        return folder_id, folder_url, file_id, file_url
    except Exception as e:
        print(f"Failed to upload to Google Drive: {e}")
        return None, None, None, None

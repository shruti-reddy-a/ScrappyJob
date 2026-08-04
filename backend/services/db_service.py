import os
import json
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from datetime import datetime

def initialize_firebase():
    if not firebase_admin._apps:
        sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        sa_json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
        if sa_path and os.path.exists(sa_path):
            cred = credentials.Certificate(sa_path)
        elif sa_json_str:
            cred_dict = json.loads(sa_json_str)
            cred = credentials.Certificate(cred_dict)
        else:
            cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)
    return firestore.client()

def should_run_job(db, job_id, scrape_frequency, current_time: datetime) -> bool:
    if scrape_frequency == "Now":
        return True
    runs = db.collection("job_runs").where(filter=FieldFilter("job_id", "==", job_id)).order_by("created_at", direction="DESCENDING").limit(1).get()
    if not runs: return True
    last_run_doc = runs[0].to_dict()
    created_at = last_run_doc.get("created_at")
    if not created_at: return True
    try:
        last_run_time = created_at.replace(tzinfo=None)
    except AttributeError:
        return True
    hours_diff = (current_time - last_run_time).total_seconds() / 3600
    if scrape_frequency == "Every 4 Hours" and hours_diff >= 3.9: return True
    if scrape_frequency == "Every 6 Hours" and hours_diff >= 5.9: return True
    if scrape_frequency == "Every 12 Hours" and hours_diff >= 11.9: return True
    if scrape_frequency == "Daily" and hours_diff >= 23.9: return True
    return False

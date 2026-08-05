import os
import time
from datetime import datetime
from dotenv import load_dotenv

from firebase_admin import firestore
from firecrawl import FirecrawlApp

# Import modular services
from services.db_service import initialize_firebase, should_run_job
from services.scraper_service import scrape_jobs
from services.excel_service import generate_excel
from services.email_service import send_email
from services.drive_service import get_drive_service, upload_to_drive
from utils.logger import JobLogger

load_dotenv()

# Initialize Firebase
db = initialize_firebase()

# Initialize Firecrawl SDK
firecrawl = FirecrawlApp(api_key=os.getenv("FIRECRAWL_API_KEY"))

# Initialize Google Drive SDK
drive_service = None
try:
    drive_service = get_drive_service()
    print("Google Drive authentication successful.")
except Exception as e:
    print(f"Google Drive auth failed: {e}. Skipping Drive uploads.")


def run_job(doc_id: str, config: dict, logger: JobLogger):
    user_id = config.get("user_id", "unknown_user")
    job_titles = config.get("job_titles", [])
    target_email = config.get("target_email")
    
    logger.log(f"==================================================")
    logger.log(f"Starting job run for: {', '.join(job_titles)}")
    logger.log(f"User ID: {user_id}")
    
    start_time = time.time()
    
    # Create the job run document first
    job_run_ref = db.collection("job_runs").document()
    job_run_id = job_run_ref.id
    job_run_ref.set({
        "config_id": doc_id,
        "user_id": user_id,
        "job_titles": config.get("job_titles", []),
        "locations": config.get("locations", []),
        "total_found": 0,
        "status": "IN_PROGRESS",
        "created_at": firestore.SERVER_TIMESTAMP,
        "logs": logger.logs
    })
    
    # 1. Scrape
    logger.log("Starting scraping phase...")
    all_jobs = scrape_jobs(config, firecrawl, db, user_id, doc_id, job_run_id, logger)
    
    # Check if we got cancelled
    progress_doc = db.collection("run_progress").document(doc_id).get()
    if progress_doc.exists and progress_doc.to_dict().get("status") == "CANCELLED":
        logger.log("Job was cancelled. Skipping reporting.")
        exec_time_ms = int((time.time() - start_time) * 1000)
        _update_job_run(job_run_ref, len(all_jobs), "CANCELLED", logger, jobs=all_jobs, exec_time=exec_time_ms)
        return

    # 2. Excel Generation
    logger.log("Generating Excel report...")
    date_str = datetime.now().strftime("%Y-%m-%d")
    filename = f"Job_Postings_{date_str}_{str(doc_id)[-6:]}.xlsx"
    generate_excel(all_jobs, filename)
    
    # 3. Cloud Uploads & Emails
    if drive_service and all_jobs:
        logger.log("Uploading report to Google Drive...")
        folder_id, folder_url, file_id, file_url = upload_to_drive(drive_service, filename, date_str)
        if folder_url:
            logger.log(f"Drive Folder: {folder_url}")
            logger.log(f"Drive File: {file_url}")
    
    if target_email and all_jobs:
        logger.log(f"Sending email report to {target_email}...")
        success = send_email(target_email, all_jobs, filename, date_str)
        if success:
            logger.log("Email sent successfully.")
    
    # Cleanup local file
    if os.path.exists(filename):
        os.remove(filename)
        logger.log(f"Cleaned up local file: {filename}")
        
    # 4. Save Final Status
    logger.log(f"Job completed successfully. Total jobs found: {len(all_jobs)}")
    exec_time_ms = int((time.time() - start_time) * 1000)
    _update_job_run(job_run_ref, len(all_jobs), "SUCCESS", logger, jobs=all_jobs, exec_time=exec_time_ms)


def _update_job_run(job_run_ref, total_found: int, status: str, logger: JobLogger, jobs: list = None, exec_time: int = 0):
    data = {
        "total_found": total_found,
        "status": status,
        "logs": logger.logs
    }
    if exec_time > 0:
        data["execution_time_ms"] = exec_time
    if jobs is not None:
        data["jobs"] = jobs
    job_run_ref.update(data)


def main(job_id: str = None):
    # This is called by the Flask server for on-demand execution
    if not job_id:
        print("No job_id provided.")
        return
        
    doc = db.collection("jobs").document(job_id).get()
    if doc.exists:
        config = doc.to_dict()
        logger = JobLogger()
        run_job(job_id, config, logger)
    else:
        print(f"Job config {job_id} not found.")

def main_loop():
    print("ScrappyJob Agent is starting... Listening for scheduled jobs.")
    while True:
        try:
            active_jobs = db.collection("jobs").where("is_active", "==", True).get()
            current_time = datetime.now()
            
            for job_doc in active_jobs:
                config = job_doc.to_dict()
                job_id = job_doc.id
                freq = config.get("scrape_frequency", "Every 4 Hours")
                
                if should_run_job(db, job_id, freq, current_time):
                    logger = JobLogger()
                    run_job(job_id, config, logger)
                    
        except Exception as e:
            print(f"Error in main loop: {e}")
            
        # Poll every 60 seconds
        time.sleep(60)

if __name__ == "__main__":
    main_loop()

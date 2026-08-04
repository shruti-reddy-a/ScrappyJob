import os
import json
import uuid
import smtplib
from datetime import datetime
from email.message import EmailMessage
from typing import List, Dict, Any

from dotenv import load_dotenv
import pandas as pd
from openpyxl.styles import PatternFill, Font, Alignment
from openpyxl.utils import get_column_letter

import firebase_admin
from firebase_admin import credentials, firestore

from firecrawl import FirecrawlApp

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

load_dotenv()

# ==========================================
# Configuration & Initialization
# ==========================================
def initialize_firebase():
    if not firebase_admin._apps:
        # Check for service account path or raw JSON string
        sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        sa_json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
        
        if sa_path and os.path.exists(sa_path):
            cred = credentials.Certificate(sa_path)
        elif sa_json_str:
            cred_dict = json.loads(sa_json_str)
            cred = credentials.Certificate(cred_dict)
        else:
            # Fallback for default application credentials
            cred = credentials.ApplicationDefault()
            
        firebase_admin.initialize_app(cred)
    return firestore.client()

def get_drive_service():
    scopes = ['https://www.googleapis.com/auth/drive']
    sa_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_PATH")
    sa_json_str = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON")
    
    if sa_path and os.path.exists(sa_path):
        creds = service_account.Credentials.from_service_account_file(sa_path, scopes=scopes)
    elif sa_json_str:
        cred_dict = json.loads(sa_json_str)
        creds = service_account.Credentials.from_service_account_info(cred_dict, scopes=scopes)
    else:
        raise ValueError("Google Service Account credentials not provided.")
        
    return build('drive', 'v3', credentials=creds)

# ==========================================
# Scraping Logic
# ==========================================
def scrape_jobs(config: Dict[str, Any], firecrawl: FirecrawlApp) -> List[Dict[str, Any]]:
    # Extract config
    job_titles = config.get("job_titles", [])
    locations = config.get("locations", [])
    target_ats = config.get("target_ats", [])
    
    all_jobs = []
    seen_urls = set()
    
    # Map friendly names to domains
    ats_domains = {
        "Greenhouse": "boards.greenhouse.io",
        "Ashby": "jobs.ashbyhq.com",
        "Lever": "jobs.lever.co",
        "Workday": "myworkdayjobs.com",
        "iCIMS": "icims.com",
        "BambooHR": "bamboohr.com",
        "Workable": "apply.workable.com",
        "LinkedIn": "linkedin.com/jobs",
        "Indeed": "indeed.com"
    }

    # Construct search prompt based on config
    title_str = ", ".join(job_titles)
    loc_str = ", ".join(locations)
    
    schema = {
        "type": "object",
        "properties": {
            "jobs": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "job_title": {"type": "string"},
                        "company": {"type": "string"},
                        "location": {"type": "string"},
                        "application_link": {"type": "string"},
                        "posted_date": {"type": "string"},
                        "snippet": {"type": "string"}
                    },
                    "required": ["job_title", "company", "application_link"]
                }
            }
        },
        "required": ["jobs"]
    }

    for ats in target_ats:
        if ats not in ats_domains:
            continue
            
        domain = ats_domains[ats]
        prompt = f"Find recently posted jobs matching titles: {title_str} in locations: {loc_str}."
        
        try:
            response = firecrawl.extract(
                urls=[f"https://{domain}"],
                params={
                    "prompt": prompt,
                    "schema": schema,
                    "enableSearch": True,
                    "searchQuery": f"site:{domain} ({' OR '.join(job_titles)}) ({' OR '.join(locations)})"
                }
            )
            
            if response and response.get('success'):
                extracted_data = response.get('data', {}).get('jobs', [])
                for job in extracted_data:
                    url = job.get('application_link', '')
                    if url and url not in seen_urls:
                        seen_urls.add(url)
                        all_jobs.append({
                            "Source ATS": ats,
                            "Job Title": job.get("job_title", "N/A"),
                            "Company": job.get("company", "N/A"),
                            "Location": job.get("location", "N/A"),
                            "Application Link": url,
                            "Posted Date": job.get("posted_date", "N/A"),
                            "Snippet/Notes": job.get("snippet", "")
                        })
        except Exception as e:
            print(f"Error scraping {ats}: {e}")
            
    return all_jobs

# ==========================================
# Excel Generation
# ==========================================
def generate_excel(jobs: List[Dict[str, Any]], filename: str) -> str:
    df = pd.DataFrame(jobs)
    if df.empty:
        df = pd.DataFrame(columns=["Source ATS", "Job Title", "Company", "Location", "Application Link", "Posted Date", "Snippet/Notes"])
        
    writer = pd.ExcelWriter(filename, engine='openpyxl')
    df.to_excel(writer, index=False, sheet_name='Job Postings')
    
    workbook = writer.book
    worksheet = writer.sheets['Job Postings']
    
    # Header Styling
    header_fill = PatternFill(start_color='002060', end_color='002060', fill_type='solid')
    header_font = Font(color='FFFFFF', bold=True)
    
    for cell in worksheet[1]:
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal='center', vertical='center')
        
    # Formatting hyperlink column (index 5)
    link_col_idx = 5
    for row in range(2, len(df) + 2):
        cell = worksheet.cell(row=row, column=link_col_idx)
        if cell.value and isinstance(cell.value, str) and cell.value.startswith('http'):
            cell.hyperlink = cell.value
            cell.value = "Apply Here"
            cell.font = Font(color='0563C1', underline='single')
            
    # Auto-adjust column widths
    for i, col in enumerate(df.columns):
        column_len = max(df[col].astype(str).map(len).max(), len(col)) + 2
        worksheet.column_dimensions[get_column_letter(i+1)].width = min(column_len, 50)

    writer.close()
    return filename

# ==========================================
# Google Drive Integration
# ==========================================
def upload_to_drive(drive_service, filename: str, date_str: str) -> tuple:
    folder_name = f"Job_Scrapes_{date_str}"
    
    query = f"mimeType='application/vnd.google-apps.folder' and name='{folder_name}' and trashed=false"
    results = drive_service.files().list(q=query, spaces='drive', fields='files(id, webViewLink)').execute()
    items = results.get('files', [])
    
    if not items:
        folder_metadata = {
            'name': folder_name,
            'mimeType': 'application/vnd.google-apps.folder'
        }
        folder = drive_service.files().create(body=folder_metadata, fields='id, webViewLink').execute()
        folder_id = folder.get('id')
        folder_url = folder.get('webViewLink')
    else:
        folder_id = items[0].get('id')
        folder_url = items[0].get('webViewLink')
        
    file_metadata = {
        'name': os.path.basename(filename),
        'parents': [folder_id]
    }
    media = MediaFileUpload(filename, resumable=True)
    file = drive_service.files().create(body=file_metadata, media_body=media, fields='id, webViewLink').execute()
    file_id = file.get('id')
    file_url = file.get('webViewLink')
    
    permission = {
        'type': 'anyone',
        'role': 'reader'
    }
    drive_service.permissions().create(fileId=file_id, body=permission).execute()
    
    return folder_id, folder_url, file_id, file_url

# ==========================================
# Email Notification
# ==========================================
def send_email(target_email: str, jobs: List[Dict[str, Any]], spreadsheet_url: str, date_str: str):
    smtp_server = "smtp.gmail.com"
    smtp_port = 587
    smtp_username = os.getenv("SMTP_USERNAME")
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    if not smtp_username or not smtp_password:
        print("SMTP credentials missing, skipping email.")
        return False
        
    msg = EmailMessage()
    msg['Subject'] = f"Job Scraper Report - {date_str}"
    msg['From'] = smtp_username
    msg['To'] = target_email
    
    total_jobs = len(jobs)
    top_jobs_html = ""
    for job in jobs[:5]:
        link = job.get('Application Link', '#')
        top_jobs_html += f"""
        <tr>
            <td style="padding: 8px; border: 1px solid #ddd;">{job.get('Job Title')}</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{job.get('Company')}</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{job.get('Location')}</td>
            <td style="padding: 8px; border: 1px solid #ddd;"><a href="{link}">Apply</a></td>
        </tr>
        """
        
    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>Automated Job Scraper Report</h2>
        <p>Your scheduled job scrape for <strong>{date_str}</strong> is complete.</p>
        <p><strong>Total Jobs Found:</strong> {total_jobs}</p>
        
        <h3>Top 5 Job Highlights</h3>
        <table style="border-collapse: collapse; width: 100%; max-width: 600px;">
          <thead>
            <tr style="background-color: #002060; color: white;">
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Title</th>
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Company</th>
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Location</th>
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Link</th>
            </tr>
          </thead>
          <tbody>
            {top_jobs_html}
          </tbody>
        </table>
        
        <br>
        <a href="{spreadsheet_url}" style="display: inline-block; padding: 10px 20px; background-color: #0563C1; color: white; text-decoration: none; border-radius: 5px; font-weight: bold;">
          View Full Spreadsheet in Google Drive
        </a>
      </body>
    </html>
    """
    
    msg.set_content(f"Job Scraper Report for {date_str}. Total found: {total_jobs}. View here: {spreadsheet_url}")
    msg.add_alternative(html_content, subtype='html')
    
    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_username, smtp_password)
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

# ==========================================
# Main Execution Flow
# ==========================================
def main():
    start_time = datetime.now()
    date_str = start_time.strftime("%Y-%m-%d")
    
    print(f"Starting Job Scraper Agent at {start_time}")
    
    db = initialize_firebase()
    fc_api_key = os.getenv("FIRECRAWL_API_KEY")
    if not fc_api_key:
        print("Missing FIRECRAWL_API_KEY. Exiting.")
        return
        
    firecrawl = FirecrawlApp(api_key=fc_api_key)
    
    try:
        drive_service = get_drive_service()
    except Exception as e:
        print(f"Failed to initialize Drive service: {e}")
        return
        
    configs_ref = db.collection('scraping_config').where('is_active', '==', True)
    docs = configs_ref.stream()
    
    for doc in docs:
        config = doc.to_dict()
        user_id = config.get('user_id', doc.id)
        target_email = config.get('target_email')
        
        print(f"Processing config for user {user_id}")
        
        jobs = scrape_jobs(config, firecrawl)
        total_found = len(jobs)
        
        filename = f"Job_Postings_{date_str}_{uuid.uuid4().hex[:6]}.xlsx"
        generate_excel(jobs, filename)
        
        folder_id, folder_url, file_id, file_url = upload_to_drive(drive_service, filename, date_str)
        
        email_sent = False
        if target_email:
            email_sent = send_email(target_email, jobs, file_url, date_str)
            
        if os.path.exists(filename):
            os.remove(filename)
            
        execution_time_ms = int((datetime.now() - start_time).total_seconds() * 1000)
        
        run_record = {
            "config_id": doc.id,
            "user_id": user_id,
            "run_date": date_str,
            "total_found": total_found,
            "drive_folder_id": folder_id,
            "drive_folder_url": folder_url,
            "excel_file_id": file_id,
            "excel_file_url": file_url,
            "email_sent": email_sent,
            "status": "SUCCESS" if total_found > 0 else "WARNING",
            "execution_time_ms": execution_time_ms,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        
        db.collection('job_runs').add(run_record)
        print(f"Completed run for user {user_id}. Logged to job_runs.")

if __name__ == "__main__":
    main()

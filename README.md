# ScrappyJob: Automated Job Search & Aggregation

ScrappyJob is an intelligent, automated job hunting system designed to take the manual effort out of finding startup roles. It automatically scrapes thousands of job boards and ATS platforms (like Greenhouse, Lever, Ashby, and Workday) to find the exact roles you are looking for, builds a neat Excel report, uploads it to your Google Drive, and emails it directly to you!

## What It Does

1. **Massive ATS Aggregation**: Instead of manually checking LinkedIn or individual startup careers pages, ScrappyJob connects directly to ATS pipelines (like Greenhouse and Ashby) via the JobSpy aggregator to securely extract job postings that match your exact query.
2. **Beautiful Control Dashboard**: You manage all your job searches through a sleek, web-based Flutter dashboard. 
3. **Automated Reporting**: When a job run finishes, the agent creates a clean `.xlsx` spreadsheet of all the jobs found (including direct application links), uploads it to Google Drive, and emails you a summary.
4. **"Set It and Forget It"**: Powered by GitHub Actions, you can configure your scraper to run on a set schedule (e.g., daily or every 4 hours). It runs completely in the background without needing your computer to be on!

## How to Use ScrappyJob

### 1. The Dashboard (Configuring Jobs)
When you log into the ScrappyJob Web Dashboard, you can create **Job Configurations**. 
- **Job Titles**: What roles are you looking for? (e.g., "Product Manager", "Senior Product Manager")
- **Locations**: Where do you want to work? (e.g., "SF Bay area, CA, USA")
- **Target ATS Platforms**: A multi-select checklist of which ATS platforms the system should scrape (Greenhouse, Lever, Ashby, Workday, etc.). You can easily select all of them!
- **Target Email**: Where the final Excel reports will be delivered.

### 2. Running a Job
You have two ways to execute a job search:
- **Manual Run**: Click the "Run" (Play icon) button on any job in your dashboard. The backend server will immediately begin scraping the internet in real-time, and you can watch the live terminal logs stream directly into your browser!
- **Automated Schedule**: If you deployed this to GitHub Actions, the scraper will wake up automatically based on the schedule you set, run the job quietly in the cloud, and send you the results via email.

### 3. Reviewing Results
Once a job run completes:
- You will get an email saying "Job Scraper Report for [Your Job]" with the total number of jobs found.
- The email contains direct links to a beautifully formatted **Excel Spreadsheet** hosted on your Google Drive.
- Open the spreadsheet to view all the extracted data, including the exact posting date, the hiring company, and the **Direct Application Link**.

---

## Technical Details for Developers

If you are a developer looking to deploy or modify this system:

- **Backend (`backend/`)**: Python-based scraper utilizing `JobSpy` (for ATS aggregation) and `Firecrawl` (for deep web scraping). Exposes a local Flask server for manual triggers.
- **Frontend (`frontend/`)**: Flutter Web interface that connects to Firebase Cloud Firestore.
- **Database (`database/`)**: Firebase Cloud Firestore stores user configurations, job run history, and live streaming logs.
- **CI/CD (`.github/workflows/`)**: GitHub Actions workflow that executes the Python backend daily.

### Environment Setup
If running locally, you must provide a `backend/.env` file with the following keys:
- `FIRECRAWL_API_KEY`
- `GEMINI_API_KEY`
- `SMTP_USERNAME` & `SMTP_PASSWORD` (For emailing)
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `GOOGLE_SERVICE_ACCOUNT_JSON` (For Google Drive uploads)

To test locally:
1. **Start the Frontend**: `cd frontend && flutter run -d chrome`
2. **Start the Backend**: `cd backend && source venv/bin/activate && python server.py`

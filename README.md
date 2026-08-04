# Automated Job-Scraping Agent & Flutter Control Center

This repository contains a full-stack automated job scraping system using Python and Flutter Web. 

## System Components

1. **Backend (`backend/`)**: A Python agent leveraging `firecrawl-py` to scrape job postings from various ATS platforms (Greenhouse, Ashby, Lever, etc.). It deduplicates data, generates an Excel spreadsheet, uploads it to Google Drive, and emails a summary report.
2. **Frontend (`frontend/`)**: A Flutter Web application serving as a Control Center. It connects to Firebase Cloud Firestore to manage scraping parameters (Job titles, Locations, ATS targets, etc.) and view execution logs.
3. **Database (`database/`)**: Firebase Cloud Firestore for storing user configurations and job run logs.
4. **CI/CD (`.github/workflows/`)**: GitHub Actions workflow running daily at 07:00 UTC to execute the Python backend.

## Initial Setup & Deployment

### 1. Firebase Setup
1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firestore Database**.
3. Enable **Authentication** (Anonymous or Email/Password).
4. Apply the security rules found in `database/firestore.rules`.
5. Run `flutterfire configure` in the `frontend` directory to connect the Flutter app.
6. Generate a Service Account JSON for the backend (Project Settings -> Service Accounts -> Generate new private key).

### 2. Google Drive Setup
1. Go to Google Cloud Console.
2. Enable the **Google Drive API**.
3. Create a Service Account and download the JSON key.

### 3. GitHub Actions Secrets
Add the following secrets to your GitHub Repository (Settings -> Secrets and variables -> Actions):
- `FIREBASE_SERVICE_ACCOUNT_JSON`: The raw JSON string of your Firebase Service Account.
- `GOOGLE_SERVICE_ACCOUNT_JSON`: The raw JSON string of your Google Cloud Service Account.
- `FIRECRAWL_API_KEY`: Your API key from Firecrawl.
- `SMTP_USERNAME`: Your Gmail address used for sending reports.
- `SMTP_PASSWORD`: Your Gmail App Password (requires 2FA enabled on Google).

### 4. Deploy Frontend to Vercel
1. Create an account on [Vercel](https://vercel.com).
2. Connect your GitHub repository.
3. Vercel will automatically use the `vercel.json` file configuration to build and deploy the Flutter Web app.

## Local Development Commands

**Initialize Git and Push to GitHub:**
```bash
cd job-scraper-system
git init
git add .
git commit -m "Initial commit: Job Scraper System"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/job-scraper-system.git
git push -u origin main
```

**Run Flutter Web Locally:**
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

**Run Python Agent Locally:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your local credentials
python agent.py
```

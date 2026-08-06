import time
from typing import List, Dict, Any
from firebase_admin import firestore
from bs4 import BeautifulSoup
from services.custom_crawler import CustomScraperClient
from config.settings import ats_domains, max_retries

def scrape_jobs(
    config: Dict[str, Any], crawler_client: Any, db, user_id: str, job_id: str, job_run_id: str, logger
) -> List[Dict[str, Any]]:
    job_titles = config.get("job_titles", [])
    locations = config.get("locations", [])
    target_ats = config.get("target_ats", [])
    all_jobs = []
    seen_urls = set()
    title_str = ", ".join(job_titles)
    loc_str = ", ".join(locations)
    
    # Initialize dictionary to keep track of job counts per ATS
    jobs_per_ats = {ats: 0 for ats in target_ats}

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
                        "posting_time": {"type": "string"},
                        "posted_iso_datetime": {"type": "string"},
                        "snippet": {"type": "string"},
                    },
                    "required": ["job_title", "company", "application_link"],
                },
            }
        },
        "required": ["jobs"],
    }

    total_ats = len(target_ats)
    ats_completed = 0
    progress_ref = db.collection("run_progress").document(job_id)
    progress_ref.set({
        "status": "RUNNING",
        "current_ats": "Starting...",
        "jobs_found_so_far": 0,
        "ats_completed": 0,
        "total_ats": total_ats,
        "jobs_per_ats": jobs_per_ats,
        "job_run_id": job_run_id,
        "user_id": user_id,
        "start_time": firestore.SERVER_TIMESTAMP,
        "updated_at": firestore.SERVER_TIMESTAMP,
    })

    # Fetch user's ATS platforms from Firestore
    ats_platforms_ref = db.collection("ats_platforms").where("user_id", "==", user_id).stream()
    dynamic_ats_domains = {}
    for doc in ats_platforms_ref:
        data = doc.to_dict()
        if data.get("is_enabled", True):
            dynamic_ats_domains[data.get("name")] = data.get("domain")
    
    if not dynamic_ats_domains:
        dynamic_ats_domains = ats_domains

    # Batch execute for JobSpy
    logger.log("\n--- Scraping comprehensively via JobSpy Aggregator ---")
    progress_ref.update({"current_ats": "JobSpy Aggregator", "updated_at": firestore.SERVER_TIMESTAMP})
    
    target_domains = []
    for ats in target_ats:
        if ats in dynamic_ats_domains:
            target_domains.append(dynamic_ats_domains[ats])
            
    # Also include user-provided target urls
    custom_target_urls = config.get("target_urls", [])
    target_domains.extend(custom_target_urls)
            
    prompt = f"Find recently posted jobs matching titles: {title_str} in locations: {loc_str}. Search specifically for: {' OR '.join(job_titles)}"
    
    try:
        response = crawler_client.extract(urls=target_domains, prompt=prompt, schema=schema)
        if response and response.success:
            extracted_data = response.data.get("jobs", []) if isinstance(response.data, dict) else []
            for job in extracted_data:
                url = job.get("application_link", "")
                if url and url not in seen_urls:
                    seen_urls.add(url)
                    
                    # Determine which ATS this belongs to
                    source_ats = "Other (Startup)"
                    for ats in target_ats:
                        domain = dynamic_ats_domains.get(ats)
                        if domain and domain in url:
                            source_ats = ats
                            jobs_per_ats[ats] += 1
                            break
                    
                    all_jobs.append({
                        "Source ATS": source_ats,
                        "Job Title": job.get("job_title", "N/A"),
                        "Company": job.get("company", "N/A"),
                        "Location": job.get("location", "N/A"),
                        "Application Link": url,
                        "Posted Date": job.get("posted_date", "N/A"),
                        "Posting Time": job.get("posting_time", "N/A"),
                        "_iso_dt": job.get("posted_iso_datetime", ""),
                        "Snippet/Notes": job.get("snippet", ""),
                    })
        ats_completed = total_ats
        progress_ref.update({
            "jobs_found_so_far": len(all_jobs),
            "ats_completed": ats_completed,
            "jobs_per_ats": jobs_per_ats,
            "updated_at": firestore.SERVER_TIMESTAMP,
        })
    except Exception as e:
        logger.log(f"Error scraping with Custom Crawler: {str(e)}")

    progress_ref.update({
        "status": "COMPLETED",
        "current_ats": "Finished",
        "updated_at": firestore.SERVER_TIMESTAMP,
    })
    
    # Sort all_jobs by the hidden ISO datetime descending
    all_jobs.sort(key=lambda x: x.get("_iso_dt", ""), reverse=True)
    return all_jobs

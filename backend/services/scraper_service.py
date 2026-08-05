import time
from typing import List, Dict, Any
from firebase_admin import firestore
from firecrawl import FirecrawlApp
from config.settings import ats_domains, max_retries

def scrape_jobs(
    config: Dict[str, Any], firecrawl: FirecrawlApp, db, user_id: str, job_id: str, job_run_id: str, logger
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
                        "posted_iso_datetime": {"type": "string", "description": "ISO 8601 format of when the job was posted (e.g. YYYY-MM-DDTHH:MM:SS) for sorting."},
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

    for ats in target_ats:
        doc = progress_ref.get()
        if doc.exists and doc.to_dict().get("command") == "STOP":
            logger.log("Received STOP command. Halting execution.")
            progress_ref.update({
                "status": "CANCELLED",
                "current_ats": "Cancelled by user",
                "command": firestore.DELETE_FIELD,
                "updated_at": firestore.SERVER_TIMESTAMP,
            })
            return all_jobs

        if ats not in dynamic_ats_domains:
            continue

        progress_ref.update({"current_ats": ats, "updated_at": firestore.SERVER_TIMESTAMP})
        logger.log(f"\n--- Scraping {ats} ---")
        domain = dynamic_ats_domains[ats]
        prompt = f"Find recently posted jobs matching titles: {title_str} in locations: {loc_str}."

        for attempt in range(max_retries):
            try:
                logger.log(f"Scraping {ats} (Attempt {attempt+1}/{max_retries})...")
                response = firecrawl.extract(
                    urls=[f"https://{domain}"],
                    prompt=f"{prompt} Search specifically for: {' OR '.join(job_titles)}",
                    schema=schema,
                    enable_web_search=True,
                )
                if response and response.success:
                    extracted_data = response.data.get("jobs", []) if isinstance(response.data, dict) else []
                    for job in extracted_data:
                        url = job.get("application_link", "")
                        if url and url not in seen_urls:
                            seen_urls.add(url)
                            all_jobs.append({
                                "Source ATS": ats,
                                "Job Title": job.get("job_title", "N/A"),
                                "Company": job.get("company", "N/A"),
                                "Location": job.get("location", "N/A"),
                                "Application Link": url,
                                "Posted Date": job.get("posted_date", "N/A"),
                                "Posting Time": job.get("posting_time", "N/A"),
                                "_iso_dt": job.get("posted_iso_datetime", ""), # hidden field for sorting
                                "Snippet/Notes": job.get("snippet", ""),
                            })
                            jobs_per_ats[ats] += 1
                break
            except Exception as e:
                error_str = str(e)
                logger.log(f"Error scraping {ats}: {error_str}")
                if "Rate Limit" in error_str or "429" in error_str:
                    if attempt < max_retries - 1:
                        logger.log("Rate limit hit. Waiting 60 seconds before retrying...")
                        progress_ref.update({
                            "current_ats": "Rate limit hit. Retrying in 60s...",
                            "updated_at": firestore.SERVER_TIMESTAMP,
                        })
                        should_stop = False
                        for _ in range(12):
                            time.sleep(5)
                            doc = progress_ref.get()
                            if doc.exists and doc.to_dict().get("command") == "STOP":
                                should_stop = True
                                break
                        if should_stop:
                            progress_ref.update({
                                "status": "CANCELLED",
                                "current_ats": "Cancelled by user",
                                "command": firestore.DELETE_FIELD,
                                "updated_at": firestore.SERVER_TIMESTAMP,
                            })
                            return sorted(all_jobs, key=lambda x: x.get("_iso_dt", ""), reverse=True)
                    else:
                        logger.log(f"Max retries reached for {ats}.")
                else:
                    break

        ats_completed += 1
        progress_ref.update({
            "jobs_found_so_far": len(all_jobs),
            "ats_completed": ats_completed,
            "jobs_per_ats": jobs_per_ats,
            "updated_at": firestore.SERVER_TIMESTAMP,
        })

        if ats != target_ats[-1]:
            logger.log("Sleeping for 30 seconds to respect rate limits...")
            progress_ref.update({
                "current_ats": "Waiting for rate limit (30s)...",
                "updated_at": firestore.SERVER_TIMESTAMP,
            })
            for _ in range(6):
                time.sleep(5)
                doc = progress_ref.get()
                if doc.exists and doc.to_dict().get("command") == "STOP":
                    logger.log("Received STOP command during rate limit wait. Halting execution.")
                    progress_ref.update({
                        "status": "CANCELLED",
                        "current_ats": "Cancelled by user",
                        "command": firestore.DELETE_FIELD,
                        "updated_at": firestore.SERVER_TIMESTAMP,
                    })
                    return sorted(all_jobs, key=lambda x: x.get("_iso_dt", ""), reverse=True)

    progress_ref.update({
        "status": "COMPLETED",
        "current_ats": "Finished",
        "updated_at": firestore.SERVER_TIMESTAMP,
    })
    
    # Sort all_jobs by the hidden ISO datetime descending
    all_jobs.sort(key=lambda x: x.get("_iso_dt", ""), reverse=True)
    return all_jobs

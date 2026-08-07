from typing import List, Dict, Any
from firebase_admin import firestore
from services.dork_crawler import DorkCrawler
from config.settings import ats_domains

def _generate_job_hash(company: str, title: str) -> str:
    """Generate a deterministic hash key for deduplication based on company and title."""
    c = str(company).lower().strip().replace(" ", "")
    t = str(title).lower().strip().replace(" ", "")
    return f"{c}_{t}"

def scrape_jobs(
    config: Dict[str, Any], crawler_client: Any, db, user_id: str, job_id: str, job_run_id: str, logger
) -> List[Dict[str, Any]]:
    job_titles = config.get("job_titles", [])
    locations = config.get("locations", [])
    target_ats = config.get("target_ats", [])
    
    # Initialize dictionary to keep track of job counts per ATS
    jobs_per_ats = {ats: 0 for ats in target_ats}
    
    total_ats = len(target_ats)
    progress_ref = db.collection("run_progress").document(job_id)
    progress_ref.set({
        "status": "RUNNING",
        "current_ats": "Starting orchestration...",
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

    # Separate ATS selections into Major Boards and Startup ATS domains
    major_boards = {"LinkedIn", "Indeed", "Glassdoor", "ZipRecruiter", "Google Careers"}
    
    selected_major_boards = []
    startup_domains = []
    
    for ats in target_ats:
        if ats in major_boards:
            selected_major_boards.append(ats)
        else:
            if ats in dynamic_ats_domains:
                startup_domains.append(dynamic_ats_domains[ats])
                
    # Also include custom target URLs to the startup domains
    custom_target_urls = config.get("target_urls", [])
    startup_domains.extend(custom_target_urls)
    
    all_raw_jobs = []
    
    # Run crawlers sequentially (or could be in parallel)
    
    # 1. Crawler A: JobSpy Engine (Major Boards)
    if selected_major_boards or not target_ats:
        logger.log(f"Routing to JobSpy Engine for Major Boards: {', '.join(selected_major_boards) if selected_major_boards else 'All'}")
        progress_ref.update({"current_ats": "JobSpy Aggregator", "updated_at": firestore.SERVER_TIMESTAMP})
        
        prompt = f"Find recently posted jobs matching titles: {', '.join(job_titles)} in locations: {', '.join(locations)}. Search specifically for: {' OR '.join(job_titles)}"
        
        try:
            response = crawler_client.extract(urls=[], prompt=prompt, schema={}, job_titles=job_titles)
            if response and response.success:
                extracted_data = response.data.get("jobs", []) if isinstance(response.data, dict) else []
                for job in extracted_data:
                    # By default assume LinkedIn or Indeed for JobSpy results
                    url = job.get("application_link", "")
                    source_ats = "JobSpy Source"
                    if "linkedin.com" in url: source_ats = "LinkedIn"
                    elif "indeed.com" in url: source_ats = "Indeed"
                    elif "glassdoor.com" in url: source_ats = "Glassdoor"
                    
                    if source_ats in jobs_per_ats:
                        jobs_per_ats[source_ats] += 1
                        
                    all_raw_jobs.append({
                        "Source ATS": source_ats,
                        "Job Title": job.get("job_title", "N/A"),
                        "Company": job.get("company", "N/A"),
                        "Location": job.get("location", "N/A"),
                        "Application Link": url,
                        "Posted Date": job.get("posted_date", "N/A"),
                        "Posting Time": job.get("posting_time", "N/A"),
                        "Salary": job.get("salary", "N/A"),
                        "_iso_dt": job.get("posted_iso_datetime", ""),
                        "Snippet/Notes": job.get("snippet", ""),
                    })
        except Exception as e:
            logger.log(f"Error scraping with JobSpy: {str(e)}")

    # 2. Crawler B: Google Dork Engine (Startup ATS)
    if startup_domains:
        logger.log(f"Routing to Dork Engine for Domains: {', '.join(startup_domains)}")
        progress_ref.update({"current_ats": "Dork Engine", "updated_at": firestore.SERVER_TIMESTAMP})
        
        dork_crawler = DorkCrawler()
        try:
            dork_jobs = dork_crawler.scrape(job_titles=job_titles, locations=locations, domains=startup_domains)
            for job in dork_jobs:
                url = job.get("application_link", "")
                
                source_ats = "Other ATS"
                for ats in target_ats:
                    if ats in dynamic_ats_domains and dynamic_ats_domains[ats] in url:
                        source_ats = ats
                        if ats in jobs_per_ats:
                            jobs_per_ats[ats] += 1
                        break
                        
                all_raw_jobs.append({
                    "Source ATS": source_ats,
                    "Job Title": job.get("job_title", "N/A"),
                    "Company": job.get("company", "N/A"),
                    "Location": job.get("location", "N/A"),
                    "Application Link": url,
                    "Posted Date": job.get("posted_date", "N/A"),
                    "Posting Time": job.get("posting_time", "N/A"),
                    "Salary": job.get("salary", "N/A"),
                    "_iso_dt": job.get("posted_iso_datetime", ""),
                    "Snippet/Notes": job.get("snippet", ""),
                })
        except Exception as e:
            logger.log(f"Error scraping with Dork Engine: {str(e)}")


    # 3. Deduplication Strategy
    logger.log(f"Found {len(all_raw_jobs)} raw jobs. Deduplicating...")
    unique_jobs_map = {}
    
    for job in all_raw_jobs:
        job_hash = _generate_job_hash(job["Company"], job["Job Title"])
        
        # If the job is already in the map, we skip it (or we could merge better links)
        # We prefer JobSpy links over generic dork links if both exist, but first-come-first-serve is fine.
        if job_hash not in unique_jobs_map:
            unique_jobs_map[job_hash] = job

    final_jobs = list(unique_jobs_map.values())
    logger.log(f"After deduplication: {len(final_jobs)} unique jobs remaining.")
    
    progress_ref.update({
        "jobs_found_so_far": len(final_jobs),
        "ats_completed": total_ats,
        "jobs_per_ats": jobs_per_ats,
        "status": "COMPLETED",
        "current_ats": "Finished",
        "updated_at": firestore.SERVER_TIMESTAMP,
    })
    
    # Sort all_jobs by the hidden ISO datetime descending
    final_jobs.sort(key=lambda x: x.get("_iso_dt", ""), reverse=True)
    return final_jobs

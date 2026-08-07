import os
import json
from typing import List, Optional, Dict, Any
from jobspy import scrape_jobs
from datetime import datetime
from pydantic import BaseModel

class CustomCrawlerResponse:
    def __init__(self, success: bool, data: Any = None, error: str = None):
        self.success = success
        self.data = data
        self.error = error

class CustomScraperClient:
    def __init__(self, gemini_api_key: str = None):
        self.api_key = gemini_api_key or os.getenv("GEMINI_API_KEY")

    def extract(self, urls: List[str], prompt: str, schema: dict, enable_web_search: bool = False) -> CustomCrawlerResponse:
        """
        Since we are using JobSpy to comprehensively search startups, `urls` will be a list of target ATS domains 
        (e.g. `['greenhouse.io', 'lever.co']`).
        `prompt` contains job titles and locations. We will parse it simply.
        """
        all_jobs = []
        
        # We need to extract the search terms and location from the prompt or from args.
        # But in scraper_service.py, they pass prompt like:
        # f"Find recently posted jobs matching titles: {title_str} in locations: {loc_str}. Search specifically for: {' OR '.join(job_titles)}"
        
        # A simple parsing mechanism:
        search_term = "Product Manager"
        if "Search specifically for:" in prompt:
            search_term = prompt.split("Search specifically for:")[-1].strip()
        
        location = "San Francisco, CA"
        if "locations:" in prompt and "Search specifically for:" in prompt:
            loc_part = prompt.split("locations:")[1].split(". Search")[0].strip()
            if loc_part:
                location = loc_part.split(",")[0].strip() # just take first location for jobspy
        
        print(f"JobSpy starting search for '{search_term}' in '{location}'...")
        
        try:
            # We scrape LinkedIn, Indeed, Glassdoor using JobSpy
            jobs_df = scrape_jobs(
                site_name=["linkedin", "indeed", "glassdoor"],
                search_term=search_term,
                location=location,
                results_wanted=30,
                country_indeed='usa'
            )
            
            print(f"JobSpy found {len(jobs_df)} jobs before filtering.")
            
            if len(jobs_df) > 0:
                for index, row in jobs_df.iterrows():
                    job_url_direct = str(row.get("job_url_direct", ""))
                    job_url = str(row.get("job_url", ""))
                    
                    # If any of the target ATS domains exist in the direct URL, it's a match!
                    is_match = False
                    for ats_url in urls:
                        ats_domain = ats_url.replace("https://", "").replace("http://", "")
                        aliases = [ats_domain]
                        
                        # Add known short-links used on LinkedIn
                        if "greenhouse.io" in ats_domain:
                            aliases.extend(["grnh.se", "greenhouse"])
                        elif "lever.co" in ats_domain:
                            aliases.extend(["lever"])
                        elif "workable.com" in ats_domain:
                            aliases.extend(["workable"])
                            
                        for alias in aliases:
                            if alias in job_url_direct or alias in job_url:
                                is_match = True
                                break
                        if is_match:
                            break
                    
                    # If urls list is empty or we matched, include it.
                    if not urls or is_match:
                        date_posted = row.get("date_posted", None)
                        posted_date_str = "N/A"
                        posting_time_str = "N/A"
                        iso_dt = ""
                        
                        if date_posted:
                            if hasattr(date_posted, "strftime"):
                                posted_date_str = date_posted.strftime("%Y-%m-%d")
                                if hasattr(date_posted, "hour") and (date_posted.hour != 0 or date_posted.minute != 0):
                                    posting_time_str = date_posted.strftime("%H:%M:%S")
                                iso_dt = date_posted.strftime("%Y-%m-%dT%H:%M:%S")
                            else:
                                posted_date_str = str(date_posted)
                                iso_dt = posted_date_str
                        
                        # Parse Salary
                        min_amt = row.get("min_amount")
                        max_amt = row.get("max_amount")
                        currency = row.get("currency", "")
                        interval = row.get("interval", "")
                        salary_str = "N/A"
                        
                        if min_amt and not (isinstance(min_amt, float) and __import__("math").isnan(min_amt)):
                            if max_amt and not (isinstance(max_amt, float) and __import__("math").isnan(max_amt)):
                                salary_str = f"{currency}{min_amt} - {currency}{max_amt} / {interval}".strip()
                            else:
                                salary_str = f"{currency}{min_amt} / {interval}".strip()
                        
                        all_jobs.append({
                            "job_title": str(row.get("title", "N/A")),
                            "company": str(row.get("company", "N/A")),
                            "location": str(row.get("location", "N/A")),
                            "application_link": job_url_direct if job_url_direct != "nan" and job_url_direct else job_url,
                            "posted_date": posted_date_str,
                            "posting_time": posting_time_str,
                            "salary": salary_str,
                            "posted_iso_datetime": iso_dt,
                            "snippet": str(row.get("description", ""))[:200]
                        })
            
            return CustomCrawlerResponse(success=True, data={"jobs": all_jobs})
            
        except Exception as e:
            print(f"JobSpy extraction error: {e}")
            return CustomCrawlerResponse(success=False, error=str(e))

if __name__ == "__main__":
    client = CustomScraperClient()
    urls = ["greenhouse.io"]
    prompt = "Find recently posted jobs matching titles: Product Manager in locations: San Francisco, CA. Search specifically for: Product Manager"
    response = client.extract(urls=urls, prompt=prompt, schema={})
    if response.success:
        print(f"Extracted {len(response.data.get('jobs'))} jobs!")
        print(json.dumps(response.data, indent=2))
    else:
        print(response.error)

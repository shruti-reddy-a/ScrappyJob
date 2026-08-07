import re
from typing import List, Dict, Any
from datetime import datetime
from duckduckgo_search import DDGS

class DorkCrawler:
    def __init__(self):
        self.ddgs = DDGS()

    def scrape(self, job_titles: List[str], locations: List[str], domains: List[str]) -> List[Dict[str, Any]]:
        all_jobs = []
        
        # Determine the search query terms
        title_query = ""
        if job_titles:
            title_query = " OR ".join([f'"{t}"' for t in job_titles])
        else:
            title_query = "Software Engineer"
            
        loc_query = ""
        if locations:
            # Just take the first location to avoid over-constraining the search
            loc_query = f'"{locations[0].split(",")[0].strip()}"'
            
        for domain in domains:
            # e.g., site:greenhouse.io ("Product Manager" OR "AI Product Manager") "San Francisco"
            query = f'site:{domain} ({title_query})'
            if loc_query:
                query += f' {loc_query}'
                
            print(f"DorkCrawler executing query: {query}")
            
            try:
                results = self.ddgs.text(query, max_results=30)
                if not results:
                    continue
                    
                for r in results:
                    title_raw = r.get("title", "")
                    body = r.get("body", "")
                    href = r.get("href", "")
                    
                    # Try to parse company and exact title from the raw title
                    # e.g. "Product Manager at Stripe - Greenhouse" or "Acme Corp - Senior Engineer"
                    parsed_title = title_raw
                    parsed_company = "N/A"
                    
                    if " at " in title_raw:
                        parts = title_raw.split(" at ")
                        parsed_title = parts[0].strip()
                        parsed_company = parts[1].split("-")[0].split("|")[0].strip()
                    elif "-" in title_raw:
                        parts = title_raw.split("-")
                        if len(parts) > 1:
                            parsed_title = parts[0].strip()
                            parsed_company = parts[1].strip()
                    
                    # Strict title filtering
                    if job_titles:
                        is_relevant = False
                        row_title_lower = parsed_title.lower()
                        for jt in job_titles:
                            jt_lower = jt.lower()
                            if len(jt_lower) <= 3:
                                if re.search(r'\b' + re.escape(jt_lower) + r'\b', row_title_lower):
                                    is_relevant = True
                                    break
                            else:
                                if jt_lower in row_title_lower:
                                    is_relevant = True
                                    break
                        if not is_relevant:
                            continue
                            
                    iso_dt = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
                            
                    all_jobs.append({
                        "job_title": parsed_title,
                        "company": parsed_company,
                        "location": locations[0] if locations else "N/A",
                        "application_link": href,
                        "posted_date": "Today", 
                        "posting_time": "",
                        "salary": "N/A",
                        "posted_iso_datetime": iso_dt,
                        "snippet": body[:200]
                    })
            except Exception as e:
                print(f"DorkCrawler error on domain {domain}: {e}")
                
        return all_jobs

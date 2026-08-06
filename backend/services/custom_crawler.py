import asyncio
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from duckduckgo_search import DDGS
from playwright.async_api import async_playwright
from playwright_stealth import Stealth
from bs4 import BeautifulSoup
import markdownify
import os
import json
from google import genai
from google.genai import types

class Job(BaseModel):
    job_title: str
    company: str
    location: Optional[str]
    application_link: str
    posted_date: Optional[str]
    posting_time: Optional[str]
    posted_iso_datetime: Optional[str]
    snippet: Optional[str]

class JobExtraction(BaseModel):
    jobs: List[Job]

class CustomCrawlerResponse:
    def __init__(self, success: bool, data: Any = None, error: str = None):
        self.success = success
        self.data = data
        self.error = error

class CustomScraperClient:
    def __init__(self, gemini_api_key: str = None):
        self.api_key = gemini_api_key or os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            print("Warning: No Gemini API Key provided for Custom Crawler")
        
    @property
    def client(self):
        # Initialize client lazily to avoid issues if API key is set later
        return genai.Client(api_key=self.api_key) if self.api_key else None

    def search_urls(self, domain: str, query: str) -> List[str]:
        # URL Discovery via DuckDuckGo
        ddgs = DDGS()
        search_term = f"site:{domain} {query}"
        results = ddgs.text(search_term, max_results=10)
        urls = [r.get("href") for r in results if r.get("href")]
        return urls

    async def fetch_html(self, url: str) -> str:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            await Stealth().apply_stealth_async(page)
            try:
                await page.goto(url, wait_until="domcontentloaded", timeout=30000)
                html = await page.content()
                return html
            except Exception as e:
                print(f"Error fetching {url}: {e}")
                # Ideally, take screenshot here
                return ""
            finally:
                await browser.close()

    def minify_html(self, html: str) -> str:
        soup = BeautifulSoup(html, "html.parser")
        for tag in soup(["script", "style", "nav", "footer", "header", "aside", "svg", "img"]):
            tag.decompose()
        clean_html = str(soup)
        md = markdownify.markdownify(clean_html, heading_style="ATX").strip()
        # truncate massive texts
        return md[:25000] 

    def extract_with_llm(self, text: str, prompt: str) -> Dict[str, Any]:
        if not self.client:
            print("Skipping LLM extraction: No API key.")
            return {"jobs": []}
            
        full_prompt = f"{prompt}\n\nExtract the jobs from the following markdown content:\n\n{text}"
        
        response = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=full_prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=JobExtraction,
            )
        )
        try:
            return json.loads(response.text)
        except Exception as e:
            print(f"Error parsing LLM response: {e}")
            return {"jobs": []}

    def extract(self, urls: List[str], prompt: str, schema: dict, enable_web_search: bool = False) -> CustomCrawlerResponse:
        # Synchronous wrapper to mimic Firecrawl
        return asyncio.run(self._async_extract(urls, prompt, schema, enable_web_search))

    async def _async_extract(self, urls: List[str], prompt: str, schema: dict, enable_web_search: bool) -> CustomCrawlerResponse:
        all_jobs = []
        target_urls = urls.copy()

        if enable_web_search and urls:
            base_url = urls[0].replace("https://", "").replace("http://", "")
            domain = base_url.split("/")[0] 
            search_query = prompt.split("Search specifically for:")[-1].strip() if "Search specifically for:" in prompt else "jobs"
            print(f"Discovering URLs for {domain} with query: {search_query}...")
            discovered = self.search_urls(domain, search_query)
            target_urls.extend(discovered)

        # Deduplicate
        target_urls = list(set(target_urls))
        
        # We process sequentially for now to avoid overloading
        for url in target_urls:
            print(f"Fetching {url}...")
            html = await self.fetch_html(url)
            if not html:
                continue
                
            md_text = self.minify_html(html)
            
            print(f"Extracting structured data via LLM...")
            extracted = self.extract_with_llm(md_text, prompt)
            
            jobs = extracted.get("jobs", [])
            for job in jobs:
                if not job.get("application_link"):
                    job["application_link"] = url
                all_jobs.append(job)

        return CustomCrawlerResponse(success=True, data={"jobs": all_jobs})

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()
    
    print("Testing Custom Scraper Client...")
    client = CustomScraperClient()
    
    prompt = "Find recently posted jobs matching titles: Product Manager in locations: SF Bay area. Search specifically for: Product Manager"
    urls = ["https://jobs.lever.co/figma"]
    
    response = client.extract(urls=urls, prompt=prompt, schema={}, enable_web_search=True)
    
    if response.success:
        print(f"Successfully extracted {len(response.data.get('jobs', []))} jobs:")
        print(json.dumps(response.data, indent=2))
    else:
        print("Failed:", response.error)

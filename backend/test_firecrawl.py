import os
from dotenv import load_dotenv
from firecrawl import FirecrawlApp

load_dotenv()
fc_api_key = os.getenv("FIRECRAWL_API_KEY")
firecrawl = FirecrawlApp(api_key=fc_api_key)

schema = {
    "type": "object",
    "properties": {
        "jobs": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "job_title": {"type": "string"},
                    "application_link": {"type": "string"}
                }
            }
        }
    }
}

try:
    print("Sending request...")
    response = firecrawl.extract(
        urls=["https://boards.greenhouse.io"],
        prompt="Find job listings.",
        schema=schema,
        enable_web_search=True
    )
    print("Response type:", type(response))
    print("Response dir:", dir(response))
    if hasattr(response, 'success'):
        print("Success:", response.success)
    if hasattr(response, 'data'):
        print("Data type:", type(response.data))
        print("Data:", response.data)
except Exception as e:
    print("Error:", e)

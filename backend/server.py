import threading
from flask import Flask, jsonify, request
from flask_cors import CORS
from agent import main as run_agent

app = Flask(__name__)
CORS(app)


@app.route("/run", methods=["POST"])
def trigger_agent():
    data = request.get_json(silent=True) or {}
    job_id = data.get("job_id")

    # Run the agent in a background thread so the HTTP request doesn't timeout
    thread = threading.Thread(target=run_agent, args=(job_id,))
    thread.start()
    return (
        jsonify(
            {
                "status": "success",
                "message": "Job Scraper Agent has started in the background!",
            }
        ),
        200,
    )


if __name__ == "__main__":
    print("🚀 Starting Job Scraper Local Server...")
    print("Listening on http://127.0.0.1:5000")
    print("Press Ctrl+C to stop.")
    app.run(host="127.0.0.1", port=5000)

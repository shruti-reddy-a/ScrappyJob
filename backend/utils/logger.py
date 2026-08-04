from datetime import datetime

class JobLogger:
    def __init__(self):
        self.logs = []
    
    def log(self, msg):
        print(msg)
        self.logs.append({
            "timestamp": datetime.now().isoformat(),
            "message": str(msg)
        })

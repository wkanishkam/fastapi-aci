from fastapi import FastAPI
from datetime import datetime
import time

app = FastAPI(title="FastAPI Uptime Service", version="1.0.0")

start_time = time.time()

@app.get("/")
async def root():
    current_time = time.time()
    uptime_seconds = current_time - start_time
    
    hours = int(uptime_seconds // 3600)
    minutes = int((uptime_seconds % 3600) // 60)
    seconds = int(uptime_seconds % 60)
    
    return {
        "message": f"FastAPI service is running in Azure Container Instance! Uptime: {hours}h {minutes}m {seconds}s ",
        "uptime_seconds": round(uptime_seconds, 2),
        "start_time": datetime.fromtimestamp(start_time).isoformat(),
        "current_time": datetime.fromtimestamp(current_time).isoformat()
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
from fastapi import FastAPI
from pydantic import BaseModel
import os

app = FastAPI(title="KaspaZof API", version="0.1.0")

@app.get("/health")
async def health():
    return {"status":"ok","service":"api","version":"0.1.0"}

@app.get("/api/system")
async def system_info():
    return {
        "platform": "local",
        "services": {
            "postgres": os.getenv("DATABASE_URL") is not None,
            "redis": os.getenv("REDIS_URL") is not None,
            "minio": os.getenv("MINIO_ENDPOINT") is not None
        }
    }

class WalletCreate(BaseModel):
    label: str

@app.post("/api/wallet/create")
async def create_wallet(payload: WalletCreate):
    # stub: generate placeholder wallet address (for dev only)
    import secrets
    addr = "kaspa:" + secrets.token_hex(16)
    return {"address": addr, "label": payload.label}
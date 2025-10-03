from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import asyncio
import os
import json
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
import aioredis
import logging

# Configuration logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="KaspaZof API",
    version="0.1.0",
    description="API pour monitoring Kaspa et gestion wallet"
)

# CORS pour le frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8081", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cache Redis
redis_client = None

@app.on_startup
async def startup():
    global redis_client
    redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
    try:
        redis_client = aioredis.from_url(redis_url)
        await redis_client.ping()
        logger.info("Redis connecté")
    except Exception as e:
        logger.warning(f"Redis non disponible: {e}")
        redis_client = None

# Models
class WalletCreate(BaseModel):
    label: str
    password: str

class PriceResponse(BaseModel):
    kaspa_usd: float
    kaspa_eur: float
    last_updated: str
    change_24h: float

class NodeStatus(BaseModel):
    is_synced: bool
    block_count: int
    peer_count: int
    network: str
    version: str

# Endpoints de base
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "kaspazof-api",
        "version": "0.1.0",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@app.get("/api/system")
async def system_info():
    return {
        "platform": "docker",
        "services": {
            "postgres": os.getenv("DATABASE_URL") is not None,
            "redis": redis_client is not None,
            "minio": os.getenv("MINIO_ENDPOINT") is not None,
            "kaspa_node": os.getenv("KASPA_RPC_URL") is not None
        },
        "environment": os.getenv("ENVIRONMENT", "development")
    }

# Cache helper
async def get_cached_data(key: str) -> Optional[Dict[Any, Any]]:
    if not redis_client:
        return None
    try:
        data = await redis_client.get(key)
        return json.loads(data) if data else None
    except (json.JSONDecodeError, TypeError, ValueError) as e:
        logger.error(f"Erreur cache lecture {key}: {e}")
        return None
    except Exception as e:
        logger.error(f"Erreur cache inattendue {key}: {e}")
        return None

async def set_cached_data(key: str, data: Dict[Any, Any], ttl: int = 300):
    if not redis_client:
        return
    try:
        await redis_client.setex(key, ttl, json.dumps(data))
    except Exception as e:
        logger.error(f"Erreur cache écriture {key}: {e}")

# Prix Kaspa (proxy CoinGecko)
@app.get("/api/prices", response_model=PriceResponse)
async def get_kaspa_prices():
    cache_key = "kaspa_prices"
    
    # Vérifier cache
    cached = await get_cached_data(cache_key)
    if cached:
        return PriceResponse(**cached)
    
    # Appel CoinGecko
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.coingecko.com/api/v3/simple/price",
                params={
                    "ids": "kaspa",
                    "vs_currencies": "usd,eur",
                    "include_24hr_change": "true"
                },
                timeout=10.0
            )
            response.raise_for_status()
            data = response.json()
            
            price_data = {
                "kaspa_usd": data["kaspa"]["usd"],
                "kaspa_eur": data["kaspa"]["eur"],
                "last_updated": datetime.now(timezone.utc).isoformat(),
                "change_24h": data["kaspa"].get("usd_24h_change", 0.0)
            }
            
            # Cache 5 minutes
            await set_cached_data(cache_key, price_data, 300)
            return PriceResponse(**price_data)
            
    except Exception as e:
        logger.error(f"Erreur récupération prix: {e}")
        raise HTTPException(status_code=503, detail="Service prix temporairement indisponible")

# Status du nœud Kaspa
@app.get("/api/node/status", response_model=NodeStatus)
async def get_node_status():
    kaspa_rpc = os.getenv("KASPA_RPC_URL", "http://localhost:16210")
    
    try:
        async with httpx.AsyncClient() as client:
            # Appel RPC Kaspa pour obtenir le status
            rpc_payload = {
                "jsonrpc": "2.0",
                "method": "getInfo",
                "params": {},
                "id": 1
            }
            
            response = await client.post(
                kaspa_rpc,
                json=rpc_payload,
                timeout=5.0
            )
            response.raise_for_status()
            data = response.json()
            
            if "result" in data:
                result = data["result"]
                return NodeStatus(
                    is_synced=result.get("isSynced", False),
                    block_count=result.get("blockCount", 0),
                    peer_count=result.get("peerCount", 0),
                    network=result.get("network", "unknown"),
                    version=result.get("serverVersion", "unknown")
                )
            else:
                raise HTTPException(status_code=503, detail="Nœud Kaspa non disponible")
                
    except Exception as e:
        logger.error(f"Erreur status nœud: {e}")
        raise HTTPException(status_code=503, detail="Impossible de contacter le nœud Kaspa")

# Gestion wallet (basique pour dev)
@app.post("/api/wallet/create")
async def create_wallet(payload: WalletCreate):
    try:
        # Génération d'une adresse de test (remplacer par vraie génération)
        import secrets
        wallet_id = secrets.token_hex(16)
        address = f"kaspa:qz{secrets.token_hex(32)}"
        
        # Hash du password pour stockage sécurisé
        password_hash = hashlib.sha256(payload.password.encode()).hexdigest()
        
        wallet_data = {
            "id": wallet_id,
            "label": payload.label,
            "address": address,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "encrypted": True
        }
        
        # Sauvegarder dans le dossier wallets (chiffré en production)
        wallet_file = f"/app/wallets/{wallet_id}.json"
        os.makedirs("/app/wallets", exist_ok=True)
        
        with open(wallet_file, "w") as f:
            json.dump(wallet_data, f, indent=2)
        
        logger.info(f"Wallet créé: {wallet_id}")
        
        return {
            "wallet_id": wallet_id,
            "address": address,
            "label": payload.label,
            "status": "created"
        }
        
    except Exception as e:
        logger.error(f"Erreur création wallet: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la création du wallet")

@app.get("/api/wallets")
async def list_wallets():
    try:
        wallets_dir = "/app/wallets"
        if not os.path.exists(wallets_dir):
            return {"wallets": []}
        
        wallets = []
        for filename in os.listdir(wallets_dir):
            if filename.endswith(".json"):
                with open(os.path.join(wallets_dir, filename), "r") as f:
                    wallet_data = json.load(f)
                    # Ne pas exposer les données sensibles
                    wallets.append({
                        "id": wallet_data["id"],
                        "label": wallet_data["label"],
                        "address": wallet_data["address"],
                        "created_at": wallet_data["created_at"]
                    })
        
        return {"wallets": wallets}
        
    except Exception as e:
        logger.error(f"Erreur liste wallets: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des wallets")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
#!/usr/bin/env python3
"""
Service de monitoring du minage Kaspa
Collecte les métriques de performance et les statistiques de minage
"""

import asyncio
import json
import logging
import os
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import requests
import uvicorn
from fastapi import FastAPI, HTTPException
from prometheus_client import Counter, Gauge, Histogram, generate_latest
from pydantic import BaseModel

# Configuration
KASPA_RPC_URL = os.getenv("KASPA_RPC_URL", "http://localhost:16210")
KASPA_RPC_USER = os.getenv("KASPA_RPC_USER", "kaspa")
KASPA_RPC_PASS = os.getenv("KASPA_RPC_PASS", "changeme123")
MINING_ADDRESS = os.getenv("MINING_ADDRESS", "")

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Métriques Prometheus
mining_hashrate = Gauge('kaspa_mining_hashrate', 'Hashrate de minage en H/s')
mining_blocks_found = Counter('kaspa_mining_blocks_found_total', 'Nombre de blocs trouvés')
mining_shares_submitted = Counter('kaspa_mining_shares_submitted_total', 'Nombre de shares soumises')
mining_difficulty = Gauge('kaspa_mining_difficulty', 'Difficulté actuelle du réseau')
node_block_height = Gauge('kaspa_node_block_height', 'Hauteur du bloc actuel')
node_peer_count = Gauge('kaspa_node_peer_count', 'Nombre de peers connectés')
mining_uptime = Gauge('kaspa_mining_uptime_seconds', 'Temps de fonctionnement du minage')

app = FastAPI(title="KaspaZof Mining Monitor", version="1.0.0")

class MiningStats(BaseModel):
    hashrate: float
    blocks_found: int
    shares_submitted: int
    difficulty: float
    uptime: int
    last_block_time: Optional[datetime]

class KaspaRPCClient:
    """Client RPC pour communiquer avec le nœud Kaspa"""
    
    def __init__(self, url: str, user: str, password: str):
        self.url = url
        self.auth = (user, password)
        self.session = requests.Session()
    
    def call(self, method: str, params: List = None) -> Dict:
        """Effectuer un appel RPC"""
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params or []
        }
        
        try:
            response = self.session.post(
                self.url,
                json=payload,
                auth=self.auth,
                timeout=10
            )
            response.raise_for_status()
            
            result = response.json()
            if "error" in result:
                raise Exception(f"RPC Error: {result['error']}")
            
            return result.get("result", {})
        
        except Exception as e:
            logger.error(f"Erreur RPC {method}: {e}")
            raise

class MiningMonitor:
    """Moniteur de minage Kaspa"""
    
    def __init__(self):
        self.rpc = KaspaRPCClient(KASPA_RPC_URL, KASPA_RPC_USER, KASPA_RPC_PASS)
        self.start_time = time.time()
        self.stats = {
            "hashrate": 0.0,
            "blocks_found": 0,
            "shares_submitted": 0,
            "difficulty": 0.0,
            "last_block_time": None
        }
    
    async def collect_metrics(self):
        """Collecter les métriques de minage"""
        try:
            # Informations du nœud
            node_info = self.rpc.call("getInfo")
            if node_info:
                node_block_height.set(node_info.get("blockCount", 0))
                node_peer_count.set(node_info.get("peerCount", 0))
            
            # Informations de minage
            mining_info = self.rpc.call("getMiningInfo")
            if mining_info:
                difficulty = mining_info.get("difficulty", 0)
                mining_difficulty.set(difficulty)
                self.stats["difficulty"] = difficulty
            
            # Statistiques du pool (si disponible)
            try:
                pool_stats = self.rpc.call("getPoolStats")
                if pool_stats:
                    hashrate = pool_stats.get("hashrate", 0)
                    mining_hashrate.set(hashrate)
                    self.stats["hashrate"] = hashrate
            except:
                pass  # Pool stats pas toujours disponibles
            
            # Temps de fonctionnement
            uptime = time.time() - self.start_time
            mining_uptime.set(uptime)
            
            logger.info(f"Métriques collectées - Difficulté: {difficulty}, Hauteur: {node_info.get('blockCount', 0)}")
            
        except Exception as e:
            logger.error(f"Erreur lors de la collecte des métriques: {e}")
    
    async def monitor_loop(self):
        """Boucle de monitoring principal"""
        while True:
            try:
                await self.collect_metrics()
                await asyncio.sleep(30)  # Collecter toutes les 30 secondes
            except Exception as e:
                logger.error(f"Erreur dans la boucle de monitoring: {e}")
                await asyncio.sleep(60)

# Instance globale du moniteur
monitor = MiningMonitor()

@app.on_event("startup")
async def startup_event():
    """Démarrer le monitoring au lancement de l'app"""
    asyncio.create_task(monitor.monitor_loop())
    logger.info("🚀 Service de monitoring du minage démarré")

@app.get("/health")
async def health_check():
    """Vérification de santé du service"""
    try:
        # Tester la connexion RPC
        node_info = monitor.rpc.call("getInfo")
        return {
            "status": "healthy",
            "kaspa_node": "connected" if node_info else "disconnected",
            "uptime": time.time() - monitor.start_time
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {e}")

@app.get("/stats", response_model=MiningStats)
async def get_mining_stats():
    """Obtenir les statistiques de minage actuelles"""
    uptime = int(time.time() - monitor.start_time)
    
    return MiningStats(
        hashrate=monitor.stats["hashrate"],
        blocks_found=monitor.stats["blocks_found"],
        shares_submitted=monitor.stats["shares_submitted"],
        difficulty=monitor.stats["difficulty"],
        uptime=uptime,
        last_block_time=monitor.stats["last_block_time"]
    )

@app.get("/node/info")
async def get_node_info():
    """Obtenir les informations du nœud Kaspa"""
    try:
        return monitor.rpc.call("getInfo")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur RPC: {e}")

@app.get("/mining/info")
async def get_mining_info():
    """Obtenir les informations de minage"""
    try:
        return monitor.rpc.call("getMiningInfo")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur RPC: {e}")

@app.get("/metrics")
async def get_prometheus_metrics():
    """Endpoint pour les métriques Prometheus"""
    return generate_latest().decode('utf-8')

@app.get("/")
async def root():
    """Page d'accueil du service"""
    return {
        "service": "KaspaZof Mining Monitor",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "stats": "/stats",
            "node_info": "/node/info",
            "mining_info": "/mining/info",
            "metrics": "/metrics"
        }
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=False,
        log_level="info"
    )
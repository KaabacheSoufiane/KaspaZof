import aioredis
import json
import logging
from typing import Any, Optional, Dict
from datetime import datetime, timezone

from ..core.config import settings

logger = logging.getLogger(__name__)

class CacheService:
    def __init__(self):
        self.redis_client: Optional[aioredis.Redis] = None
        self.connected = False
        
    async def connect(self):
        """Initialise la connexion Redis"""
        try:
            self.redis_client = aioredis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True,
                retry_on_timeout=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            
            # Test de connexion
            await self.redis_client.ping()
            self.connected = True
            logger.info("Redis cache connected successfully")
            
        except Exception as e:
            logger.warning(f"Redis connection failed: {e}")
            self.connected = False
            self.redis_client = None
    
    async def disconnect(self):
        """Ferme la connexion Redis"""
        if self.redis_client:
            await self.redis_client.close()
            self.connected = False
            logger.info("Redis cache disconnected")
    
    async def get(self, key: str) -> Optional[Dict[str, Any]]:
        """Récupère une valeur du cache"""
        if not self.connected or not self.redis_client:
            return None
            
        try:
            data = await self.redis_client.get(key)
            if data:
                return json.loads(data)
            return None
            
        except json.JSONDecodeError as e:
            logger.error(f"Cache JSON decode error for key {key}: {e}")
            # Supprimer la clé corrompue
            await self.delete(key)
            return None
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return None
    
    async def set(self, key: str, value: Dict[str, Any], ttl: int = 300) -> bool:
        """Stocke une valeur dans le cache"""
        if not self.connected or not self.redis_client:
            return False
            
        try:
            # Ajouter metadata
            cache_data = {
                "data": value,
                "cached_at": datetime.now(timezone.utc).isoformat(),
                "ttl": ttl
            }
            
            serialized = json.dumps(cache_data, default=str)
            await self.redis_client.setex(key, ttl, serialized)
            return True
            
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Supprime une clé du cache"""
        if not self.connected or not self.redis_client:
            return False
            
        try:
            result = await self.redis_client.delete(key)
            return result > 0
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """Vérifie si une clé existe"""
        if not self.connected or not self.redis_client:
            return False
            
        try:
            result = await self.redis_client.exists(key)
            return result > 0
        except Exception as e:
            logger.error(f"Cache exists error for key {key}: {e}")
            return False
    
    async def clear_pattern(self, pattern: str) -> int:
        """Supprime toutes les clés correspondant au pattern"""
        if not self.connected or not self.redis_client:
            return 0
            
        try:
            keys = await self.redis_client.keys(pattern)
            if keys:
                return await self.redis_client.delete(*keys)
            return 0
        except Exception as e:
            logger.error(f"Cache clear pattern error for {pattern}: {e}")
            return 0
    
    async def get_stats(self) -> Dict[str, Any]:
        """Récupère les statistiques du cache"""
        if not self.connected or not self.redis_client:
            return {"connected": False}
            
        try:
            info = await self.redis_client.info()
            return {
                "connected": True,
                "used_memory": info.get("used_memory_human", "unknown"),
                "connected_clients": info.get("connected_clients", 0),
                "total_commands_processed": info.get("total_commands_processed", 0),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0),
                "uptime_in_seconds": info.get("uptime_in_seconds", 0)
            }
        except Exception as e:
            logger.error(f"Cache stats error: {e}")
            return {"connected": False, "error": str(e)}
    
    async def health_check(self) -> bool:
        """Vérifie la santé du cache"""
        try:
            if not self.redis_client:
                return False
            await self.redis_client.ping()
            return True
        except Exception:
            return False

# Instance globale
cache_service = CacheService()
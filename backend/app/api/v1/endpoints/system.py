from fastapi import APIRouter, Depends
from datetime import datetime, timezone
import psutil
import os

from ....models.schemas import SystemResponse, SystemInfo, ServiceStatus
from ....services.cache_service import cache_service
from ....services.kaspa_service import KaspaService
from ....services.price_service import PriceService

router = APIRouter()

async def get_kaspa_service() -> KaspaService:
    return KaspaService()

async def get_price_service() -> PriceService:
    return PriceService(cache_service)

@router.get("/info", response_model=SystemResponse)
async def get_system_info(
    kaspa_service: KaspaService = Depends(get_kaspa_service),
    price_service: PriceService = Depends(get_price_service)
):
    """Récupère les informations système et l'état des services"""
    
    # Vérifier l'état des services
    services = []
    
    # Cache Redis
    cache_healthy = await cache_service.health_check()
    services.append(ServiceStatus(
        name="redis_cache",
        status=cache_healthy,
        last_check=datetime.now(timezone.utc)
    ))
    
    # Nœud Kaspa
    kaspa_healthy = await kaspa_service.health_check()
    services.append(ServiceStatus(
        name="kaspa_node",
        status=kaspa_healthy,
        last_check=datetime.now(timezone.utc)
    ))
    
    # API Prix
    price_healthy = await price_service.health_check()
    services.append(ServiceStatus(
        name="price_api",
        status=price_healthy,
        last_check=datetime.now(timezone.utc)
    ))
    
    # Base de données (si configurée)
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        services.append(ServiceStatus(
            name="database",
            status=db_url is not None,
            last_check=datetime.now(timezone.utc)
        ))
    
    # Informations système
    try:
        uptime = int(psutil.boot_time())
        current_time = int(datetime.now(timezone.utc).timestamp())
        uptime_seconds = current_time - uptime
    except:
        uptime_seconds = 0
    
    system_info = SystemInfo(
        environment=os.getenv("ENVIRONMENT", "development"),
        version=os.getenv("VERSION", "0.1.0"),
        uptime=uptime_seconds,
        services=services
    )
    
    return SystemResponse(data=system_info)

@router.get("/health")
async def health_check():
    """Health check simple pour monitoring"""
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@router.get("/cache/stats")
async def get_cache_stats():
    """Statistiques du cache Redis"""
    stats = await cache_service.get_stats()
    return {"cache_stats": stats}
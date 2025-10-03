from fastapi import APIRouter, Depends, Query
from typing import Optional

from ....models.schemas import PriceResponse
from ....services.price_service import PriceService
from ....services.cache_service import cache_service

router = APIRouter()

async def get_price_service() -> PriceService:
    return PriceService(cache_service)

@router.get("/current", response_model=PriceResponse)
async def get_current_price(
    price_service: PriceService = Depends(get_price_service)
):
    """Récupère le prix actuel de Kaspa"""
    price_data = await price_service.get_kaspa_price()
    return PriceResponse(data=price_data)

@router.get("/history")
async def get_price_history(
    days: int = Query(7, ge=1, le=365, description="Nombre de jours d'historique"),
    price_service: PriceService = Depends(get_price_service)
):
    """Récupère l'historique des prix"""
    history = await price_service.get_price_history(days)
    return {
        "success": True,
        "data": history,
        "period_days": days
    }
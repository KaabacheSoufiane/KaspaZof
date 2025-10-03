from fastapi import APIRouter, Depends, Query
from typing import Optional

from ....models.schemas import NodeStatusResponse
from ....services.kaspa_service import KaspaService

router = APIRouter()

async def get_kaspa_service() -> KaspaService:
    return KaspaService()

@router.get("/status", response_model=NodeStatusResponse)
async def get_node_status(
    kaspa_service: KaspaService = Depends(get_kaspa_service)
):
    """Récupère l'état du nœud Kaspa"""
    node_info = await kaspa_service.get_node_info()
    return NodeStatusResponse(data=node_info)

@router.get("/block")
async def get_block_info(
    block_hash: Optional[str] = Query(None, description="Hash du bloc (dernier bloc si omis)"),
    kaspa_service: KaspaService = Depends(get_kaspa_service)
):
    """Récupère les informations d'un bloc"""
    block_info = await kaspa_service.get_block_info(block_hash)
    return {
        "success": True,
        "data": block_info
    }
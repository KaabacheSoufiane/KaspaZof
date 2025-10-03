from fastapi import APIRouter
from .endpoints import system, prices, node, wallets

api_router = APIRouter()

# Inclure tous les endpoints
api_router.include_router(
    system.router,
    prefix="/system",
    tags=["system"]
)

api_router.include_router(
    prices.router,
    prefix="/prices",
    tags=["prices"]
)

api_router.include_router(
    node.router,
    prefix="/node",
    tags=["kaspa-node"]
)

api_router.include_router(
    wallets.router,
    prefix="/wallets",
    tags=["wallets"]
)
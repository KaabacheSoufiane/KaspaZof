import httpx
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime, timezone
import logging

from ..core.config import settings
from ..core.exceptions import PriceException
from ..models.schemas import PriceData

logger = logging.getLogger(__name__)

class PriceService:
    def __init__(self, cache_service=None):
        self.api_url = settings.COINGECKO_API_URL
        self.cache_service = cache_service
        self.timeout = 10.0
        self.cache_ttl = 300  # 5 minutes
        
    async def get_kaspa_price(self) -> PriceData:
        """Récupère le prix Kaspa depuis CoinGecko avec cache"""
        cache_key = "kaspa_price_data"
        
        # Vérifier le cache
        if self.cache_service:
            cached_data = await self.cache_service.get(cache_key)
            if cached_data:
                try:
                    return PriceData(**cached_data)
                except Exception as e:
                    logger.warning(f"Invalid cached price data: {e}")
        
        # Récupérer depuis l'API
        try:
            price_data = await self._fetch_from_coingecko()
            
            # Mettre en cache
            if self.cache_service:
                await self.cache_service.set(
                    cache_key, 
                    price_data.dict(), 
                    ttl=self.cache_ttl
                )
            
            return price_data
            
        except Exception as e:
            logger.error(f"Failed to get Kaspa price: {e}")
            raise PriceException("Unable to fetch current price data")
    
    async def _fetch_from_coingecko(self) -> PriceData:
        """Récupère les données depuis CoinGecko API"""
        url = f"{self.api_url}/simple/price"
        params = {
            "ids": "kaspa",
            "vs_currencies": "usd,eur",
            "include_24hr_change": "true",
            "include_24hr_vol": "true",
            "include_market_cap": "true"
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    url,
                    params=params,
                    timeout=self.timeout,
                    headers={"Accept": "application/json"}
                )
                response.raise_for_status()
                data = response.json()
                
                if "kaspa" not in data:
                    raise PriceException("Kaspa data not found in API response")
                
                kaspa_data = data["kaspa"]
                
                # Validation des données requises
                required_fields = ["usd", "eur"]
                for field in required_fields:
                    if field not in kaspa_data:
                        raise PriceException(f"Missing required field: {field}")
                
                return PriceData(
                    kaspa_usd=float(kaspa_data["usd"]),
                    kaspa_eur=float(kaspa_data["eur"]),
                    change_24h=float(kaspa_data.get("usd_24h_change", 0.0)),
                    last_updated=datetime.now(timezone.utc),
                    volume_24h=kaspa_data.get("usd_24h_vol"),
                    market_cap=kaspa_data.get("usd_market_cap")
                )
                
        except httpx.TimeoutException:
            raise PriceException("Timeout fetching price data")
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:
                raise PriceException("Rate limit exceeded, please try again later")
            else:
                raise PriceException(f"API error: {e.response.status_code}")
        except ValueError as e:
            raise PriceException(f"Invalid price data format: {e}")
        except Exception as e:
            logger.error(f"Unexpected error fetching price: {e}")
            raise PriceException("Unexpected error fetching price data")
    
    async def get_price_history(self, days: int = 7) -> Dict[str, Any]:
        """Récupère l'historique des prix (optionnel)"""
        if days > 365:
            raise PriceException("Maximum 365 days of history allowed")
        
        url = f"{self.api_url}/coins/kaspa/market_chart"
        params = {
            "vs_currency": "usd",
            "days": days,
            "interval": "daily" if days > 1 else "hourly"
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    url,
                    params=params,
                    timeout=self.timeout * 2  # Plus de temps pour l'historique
                )
                response.raise_for_status()
                return response.json()
                
        except Exception as e:
            logger.error(f"Failed to get price history: {e}")
            raise PriceException("Unable to fetch price history")
    
    async def health_check(self) -> bool:
        """Vérifie si l'API CoinGecko est accessible"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.api_url}/ping",
                    timeout=5.0
                )
                return response.status_code == 200
        except Exception:
            return False
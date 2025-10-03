import httpx
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime, timezone
import logging

from ..core.config import settings
from ..core.exceptions import NodeException
from ..models.schemas import NodeInfo, NetworkType

logger = logging.getLogger(__name__)

class KaspaService:
    def __init__(self):
        self.rpc_url = settings.KASPA_RPC_URL
        self.timeout = 10.0
        
    async def _make_rpc_call(self, method: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Effectue un appel RPC au nœud Kaspa"""
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params or {},
            "id": 1
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self.rpc_url,
                    json=payload,
                    timeout=self.timeout
                )
                response.raise_for_status()
                data = response.json()
                
                if "error" in data:
                    raise NodeException(f"RPC Error: {data['error']}")
                
                if "result" not in data:
                    raise NodeException("Invalid RPC response format")
                
                return data["result"]
                
        except httpx.TimeoutException:
            raise NodeException("Timeout connecting to Kaspa node")
        except httpx.ConnectError:
            raise NodeException("Cannot connect to Kaspa node")
        except Exception as e:
            logger.error(f"RPC call failed: {e}")
            raise NodeException(f"RPC call failed: {str(e)}")
    
    async def get_node_info(self) -> NodeInfo:
        """Récupère les informations du nœud"""
        try:
            # Appels RPC parallèles pour optimiser
            info_task = self._make_rpc_call("getInfo")
            peers_task = self._make_rpc_call("getPeerInfo")
            
            info_result, peers_result = await asyncio.gather(
                info_task, peers_task, return_exceptions=True
            )
            
            # Gérer les erreurs des tâches
            if isinstance(info_result, Exception):
                raise info_result
            if isinstance(peers_result, Exception):
                logger.warning(f"Failed to get peer info: {peers_result}")
                peers_result = {"peers": []}
            
            # Mapper les données
            network_map = {
                "kaspa-mainnet": NetworkType.MAINNET,
                "kaspa-testnet": NetworkType.TESTNET,
                "kaspa-devnet": NetworkType.DEVNET
            }
            
            network = network_map.get(
                info_result.get("network", "").lower(),
                NetworkType.MAINNET
            )
            
            return NodeInfo(
                is_synced=info_result.get("isSynced", False),
                block_count=info_result.get("blockCount", 0),
                peer_count=len(peers_result.get("peers", [])),
                network=network,
                version=info_result.get("serverVersion", "unknown"),
                uptime=info_result.get("uptime"),
                sync_progress=self._calculate_sync_progress(info_result)
            )
            
        except NodeException:
            raise
        except Exception as e:
            logger.error(f"Failed to get node info: {e}")
            raise NodeException("Failed to retrieve node information")
    
    def _calculate_sync_progress(self, info: Dict[str, Any]) -> Optional[float]:
        """Calcule le pourcentage de synchronisation"""
        try:
            if info.get("isSynced", False):
                return 100.0
            
            current_block = info.get("blockCount", 0)
            header_count = info.get("headerCount", 0)
            
            if header_count > 0 and current_block > 0:
                return min(100.0, (current_block / header_count) * 100)
            
            return None
        except Exception:
            return None
    
    async def get_block_info(self, block_hash: str = None) -> Dict[str, Any]:
        """Récupère les informations d'un bloc"""
        try:
            if block_hash:
                return await self._make_rpc_call("getBlock", {"hash": block_hash})
            else:
                # Récupérer le dernier bloc
                dag_info = await self._make_rpc_call("getBlockDagInfo")
                tip_hash = dag_info.get("tipHashes", [None])[0]
                if tip_hash:
                    return await self._make_rpc_call("getBlock", {"hash": tip_hash})
                else:
                    raise NodeException("No tip block found")
                    
        except NodeException:
            raise
        except Exception as e:
            logger.error(f"Failed to get block info: {e}")
            raise NodeException("Failed to retrieve block information")
    
    async def health_check(self) -> bool:
        """Vérifie si le nœud est accessible"""
        try:
            await self._make_rpc_call("getInfo")
            return True
        except Exception:
            return False
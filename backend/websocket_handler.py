from fastapi import WebSocket, WebSocketDisconnect
import asyncio
import json
import logging

logger = logging.getLogger(__name__)

class WebSocketManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WebSocket connecté. Total: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        logger.info(f"WebSocket déconnecté. Total: {len(self.active_connections)}")

    async def send_personal_message(self, message: str, websocket: WebSocket):
        try:
            await websocket.send_text(message)
        except Exception as e:
            logger.error(f"Erreur envoi message WebSocket: {e}")

    async def broadcast(self, message: str):
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception as e:
                logger.error(f"Erreur broadcast WebSocket: {e}")
                disconnected.append(connection)
        
        # Nettoyer les connexions fermées
        for conn in disconnected:
            self.disconnect(conn)

manager = WebSocketManager()

async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Envoyer des données de test périodiquement
            test_data = {
                "type": "status_update",
                "data": {
                    "timestamp": "2024-01-01T00:00:00Z",
                    "kaspa_price": 0.025,
                    "node_status": "synced",
                    "block_count": 1000000
                }
            }
            await manager.send_personal_message(json.dumps(test_data), websocket)
            await asyncio.sleep(30)  # Envoyer toutes les 30 secondes
            
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"Erreur WebSocket: {e}")
        manager.disconnect(websocket)
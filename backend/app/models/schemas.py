from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime
from enum import Enum

# Enums
class NetworkType(str, Enum):
    MAINNET = "mainnet"
    TESTNET = "testnet"
    DEVNET = "devnet"

class WalletStatus(str, Enum):
    ACTIVE = "active"
    LOCKED = "locked"
    ARCHIVED = "archived"

# Base models
class BaseResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# Wallet models
class WalletCreate(BaseModel):
    label: str = Field(..., min_length=1, max_length=50)
    password: str = Field(..., min_length=8, max_length=128)
    
    @validator('label')
    def validate_label(cls, v):
        if not v.strip():
            raise ValueError('Label cannot be empty')
        return v.strip()
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v

class WalletResponse(BaseModel):
    id: str
    label: str
    address: str
    status: WalletStatus
    created_at: datetime
    balance: Optional[float] = None

class WalletList(BaseResponse):
    wallets: List[WalletResponse]
    total: int

# Price models
class PriceData(BaseModel):
    kaspa_usd: float = Field(..., gt=0)
    kaspa_eur: float = Field(..., gt=0)
    change_24h: float
    last_updated: datetime
    volume_24h: Optional[float] = None
    market_cap: Optional[float] = None

class PriceResponse(BaseResponse):
    data: PriceData

# Node models
class NodeInfo(BaseModel):
    is_synced: bool
    block_count: int = Field(..., ge=0)
    peer_count: int = Field(..., ge=0)
    network: NetworkType
    version: str
    uptime: Optional[int] = None
    sync_progress: Optional[float] = Field(None, ge=0, le=100)

class NodeStatusResponse(BaseResponse):
    data: NodeInfo

# System models
class ServiceStatus(BaseModel):
    name: str
    status: bool
    latency_ms: Optional[float] = None
    last_check: datetime

class SystemInfo(BaseModel):
    environment: str
    version: str
    uptime: int
    services: List[ServiceStatus]

class SystemResponse(BaseResponse):
    data: SystemInfo

# Error models
class ErrorDetail(BaseModel):
    code: str
    message: str
    field: Optional[str] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error: ErrorDetail
    timestamp: datetime = Field(default_factory=datetime.utcnow)
from pydantic_settings import BaseSettings
from typing import List, Optional

class Settings(BaseSettings):
    # API
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "KaspaZof"
    VERSION: str = "0.1.0"
    
    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    DATABASE_URL: Optional[str] = None
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    
    # Kaspa
    KASPA_RPC_URL: str = "http://localhost:16210"
    KASPA_NETWORK: str = "mainnet"
    
    # External APIs
    COINGECKO_API_URL: str = "https://api.coingecko.com/api/v3"
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:8081", "http://localhost:3000"]
    
    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    
    class Config:
        env_file = ".env"

settings = Settings()
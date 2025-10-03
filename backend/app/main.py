from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from contextlib import asynccontextmanager
import logging
import time

from .core.config import settings
from .core.exceptions import (
    KaspaZofException,
    kaspazof_exception_handler,
    validation_exception_handler,
    http_exception_handler,
    general_exception_handler
)
from .services.cache_service import cache_service
from .api.v1.router import api_router

# Configuration logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting KaspaZof API...")
    
    # Initialiser les services
    await cache_service.connect()
    
    logger.info("KaspaZof API started successfully")
    yield
    
    # Shutdown
    logger.info("Shutting down KaspaZof API...")
    await cache_service.disconnect()
    logger.info("KaspaZof API shutdown complete")

# Créer l'application FastAPI
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API sécurisée pour monitoring Kaspa et gestion de wallets",
    openapi_url=f"{settings.API_V1_STR}/openapi.json" if settings.DEBUG else None,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan
)

# Middleware de sécurité
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "*.localhost"] if settings.DEBUG else ["yourdomain.com"]
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Middleware de logging des requêtes
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Log de la requête
    logger.info(f"Request: {request.method} {request.url}")
    
    response = await call_next(request)
    
    # Log de la réponse
    process_time = time.time() - start_time
    logger.info(f"Response: {response.status_code} - {process_time:.3f}s")
    
    return response

# Gestionnaires d'exceptions
app.add_exception_handler(KaspaZofException, kaspazof_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# Routes
app.include_router(api_router, prefix=settings.API_V1_STR)

# Health check endpoint (sans préfixe pour les load balancers)
@app.get("/health")
async def health_check():
    """Health check endpoint pour monitoring externe"""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT
    }

# Root endpoint
@app.get("/")
async def root():
    """Endpoint racine avec informations de base"""
    return {
        "message": f"Welcome to {settings.PROJECT_NAME} API",
        "version": settings.VERSION,
        "docs_url": "/docs" if settings.DEBUG else None,
        "health_url": "/health"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )
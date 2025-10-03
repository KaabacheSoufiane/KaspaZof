from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

# Custom exceptions
class KaspaZofException(Exception):
    def __init__(self, message: str, code: str = "INTERNAL_ERROR"):
        self.message = message
        self.code = code
        super().__init__(self.message)

class WalletException(KaspaZofException):
    def __init__(self, message: str, code: str = "WALLET_ERROR"):
        super().__init__(message, code)

class NodeException(KaspaZofException):
    def __init__(self, message: str, code: str = "NODE_ERROR"):
        super().__init__(message, code)

class PriceException(KaspaZofException):
    def __init__(self, message: str, code: str = "PRICE_ERROR"):
        super().__init__(message, code)

class ValidationException(KaspaZofException):
    def __init__(self, message: str, field: str = None):
        self.field = field
        super().__init__(message, "VALIDATION_ERROR")

# Exception handlers
async def kaspazof_exception_handler(request: Request, exc: KaspaZofException):
    logger.error(f"KaspaZof error: {exc.code} - {exc.message}")
    
    return JSONResponse(
        status_code=400,
        content={
            "success": False,
            "error": {
                "code": exc.code,
                "message": exc.message,
                "field": getattr(exc, 'field', None)
            },
            "timestamp": datetime.utcnow().isoformat()
        }
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.error(f"Validation error: {exc.errors()}")
    
    errors = []
    for error in exc.errors():
        field = ".".join(str(x) for x in error["loc"][1:]) if len(error["loc"]) > 1 else "unknown"
        errors.append({
            "field": field,
            "message": error["msg"],
            "type": error["type"]
        })
    
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Données d'entrée invalides",
                "details": errors
            },
            "timestamp": datetime.utcnow().isoformat()
        }
    )

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": f"HTTP_{exc.status_code}",
                "message": exc.detail
            },
            "timestamp": datetime.utcnow().isoformat()
        }
    )

async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {type(exc).__name__} - {str(exc)}", exc_info=True)
    
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "Erreur interne du serveur"
            },
            "timestamp": datetime.utcnow().isoformat()
        }
    )
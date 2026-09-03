import os
import secrets
from pydantic_settings import BaseSettings
from typing import List, Optional


def _generate_secure_secret() -> str:
    """Generate a cryptographically secure random secret."""
    return secrets.token_urlsafe(64)


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    
    Security Notes:
    - JWT_SECRET_KEY: MUST be set in production via environment variable
    - CORS_ORIGINS: Use specific domains, NEVER use '*' in production
    - DATABASE_URL: Use PostgreSQL for production workloads
    """

    # ===== Database =====
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite+aiosqlite:///./yarmouk_water_pro.db"
    )
    DATABASE_URL_SYNC: str = os.getenv(
        "DATABASE_URL_SYNC",
        "sqlite:///./yarmouk_water_pro.db"
    )

    # ===== Redis =====
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # ===== JWT =====
    # CRITICAL: In production, JWT_SECRET_KEY MUST be set via environment variable
    # If not set, a random key is generated (tokens will invalidate on restart - DEV ONLY)
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY") or _generate_secure_secret()
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("JWT_REFRESH_TOKEN_EXPIRE_DAYS", "7"))

    # ===== CORS =====
    # SECURITY: Always use whitelist. NEVER use '*' in production.
    # Default: localhost-only for development
    _cors_env = os.getenv("CORS_ORIGINS", "")
    if _cors_env:
        CORS_ORIGINS: List[str] = [
            origin.strip() 
            for origin in _cors_env.split(",") 
            if origin.strip()
        ]
    else:
        CORS_ORIGINS: List[str] = [
            "*",
        ]

    # ===== Rate Limiting =====
    RATE_LIMIT_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "120"))

    # ===== Environment =====
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"

    @property
    def is_sqlite(self) -> bool:
        return self.DATABASE_URL.startswith("sqlite")

    class Config:
        env_file = ".env"
        extra = "allow"


settings = Settings()

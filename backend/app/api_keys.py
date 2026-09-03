"""
API Key Management
Yarmouk Water Management Pro
"""
import os
import secrets
import hashlib
from datetime import datetime, timedelta
from typing import Optional, List, Tuple
from pydantic import BaseModel
from sqlalchemy import Column, String, DateTime, Boolean, Integer
from sqlalchemy.orm import relationship
from app.database import Base


class APIKey(Base):
    """API Key model for external integrations."""
    __tablename__ = "api_keys"
    
    key_id = Column(Integer, primary_key=True, index=True)
    key_prefix = Column(String(8), nullable=False)  # First 8 chars for identification
    key_hash = Column(String(64), nullable=False, unique=True)  # SHA-256 hash
    name = Column(String(100), nullable=False)  # Friendly name
    description = Column(String(500), nullable=True)
    employee_id = Column(Integer, nullable=True)  # Associated employee
    
    # Permissions (JSON array of permission strings)
    permissions = Column(String(1000), default="[]")
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    last_used_at = Column(DateTime, nullable=True)
    usage_count = Column(Integer, default=0)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    revoked_at = Column(DateTime, nullable=True)
    
    def to_dict(self):
        return {
            "key_id": self.key_id,
            "key_prefix": self.key_prefix,
            "name": self.name,
            "description": self.description,
            "is_active": self.is_active,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "last_used_at": self.last_used_at.isoformat() if self.last_used_at else None,
            "usage_count": self.usage_count,
            "created_at": self.created_at.isoformat(),
        }


class APIKeyManager:
    """Manages API keys."""
    
    @staticmethod
    def generate_key() -> Tuple[str, str, str]:
        """
        Generate a new API key.
        Returns: (full_key, key_prefix, key_hash)
        """
        full_key = secrets.token_urlsafe(32)
        key_prefix = full_key[:8]
        key_hash = hashlib.sha256(full_key.encode()).hexdigest()
        
        return full_key, key_prefix, key_hash
    
    @staticmethod
    def verify_key(provided_key: str, stored_hash: str) -> bool:
        """Verify an API key against its hash."""
        import hashlib
        provided_hash = hashlib.sha256(provided_key.encode()).hexdigest()
        return secrets.compare_digest(provided_hash, stored_hash)
    
    @staticmethod
    def is_expired(expires_at: Optional[datetime]) -> bool:
        """Check if an API key is expired."""
        if expires_at is None:
            return False
        return datetime.utcnow() > expires_at


# Request/Response models
class APIKeyCreate(BaseModel):
    name: str
    description: Optional[str] = None
    employee_id: Optional[int] = None
    permissions: List[str] = []
    expires_in_days: Optional[int] = None  # None = never expires


class APIKeyResponse(BaseModel):
    key_id: int
    key_prefix: str
    name: str
    description: Optional[str]
    is_active: bool
    expires_at: Optional[datetime]
    last_used_at: Optional[datetime]
    usage_count: int
    created_at: datetime


class APIKeyCreatedResponse(APIKeyResponse):
    full_key: str  # Only returned on creation

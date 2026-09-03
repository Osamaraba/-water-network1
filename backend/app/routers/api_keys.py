"""
API Keys Management API
Yarmouk Water Management Pro
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
from app.database import get_db
from app.middleware.auth import get_current_user
from app.models import Employee
from app.api_keys import APIKey, APIKeyManager, APIKeyCreate, APIKeyResponse, APIKeyCreatedResponse

router = APIRouter(prefix="/api-keys", tags=["api-keys"])


# =============================================================================
# Endpoints
# =============================================================================

@router.post("/", response_model=APIKeyCreatedResponse)
async def create_api_key(
    request: APIKeyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Create a new API key."""
    full_key, key_prefix, key_hash = APIKeyManager.generate_key()
    
    expires_at = None
    if request.expires_in_days:
        expires_at = datetime.utcnow() + timedelta(days=request.expires_in_days)
    
    api_key = APIKey(
        key_prefix=key_prefix,
        key_hash=key_hash,
        name=request.name,
        description=request.description,
        employee_id=request.employee_id or current_user.employee_id,
        permissions=str(request.permissions),
        expires_at=expires_at,
    )
    
    db.add(api_key)
    await db.commit()
    await db.refresh(api_key)
    
    return APIKeyCreatedResponse(
        **api_key.to_dict(),
        full_key=full_key,
    )


@router.get("/", response_model=List[APIKeyResponse])
async def list_api_keys(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """List all API keys."""
    result = await db.execute(select(APIKey).order_by(APIKey.created_at.desc()))
    keys = result.scalars().all()
    return [APIKeyResponse(**k.to_dict()) for k in keys]


@router.get("/{key_id}", response_model=APIKeyResponse)
async def get_api_key(
    key_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Get an API key by ID."""
    result = await db.execute(select(APIKey).where(APIKey.key_id == key_id))
    key = result.scalar_one_or_none()
    
    if not key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    return APIKeyResponse(**key.to_dict())


@router.delete("/{key_id}")
async def revoke_api_key(
    key_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Revoke an API key."""
    result = await db.execute(select(APIKey).where(APIKey.key_id == key_id))
    key = result.scalar_one_or_none()
    
    if not key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    key.is_active = False
    key.revoked_at = datetime.utcnow()
    await db.commit()
    
    return {"message": "API key revoked"}


@router.post("/{key_id}/regenerate", response_model=APIKeyCreatedResponse)
async def regenerate_api_key(
    key_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Regenerate an API key."""
    result = await db.execute(select(APIKey).where(APIKey.key_id == key_id))
    key = result.scalar_one_or_none()
    
    if not key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    full_key, key_prefix, key_hash = APIKeyManager.generate_key()
    
    key.key_prefix = key_prefix
    key.key_hash = key_hash
    key.is_active = True
    key.revoked_at = None
    key.last_used_at = None
    key.usage_count = 0
    await db.commit()
    await db.refresh(key)
    
    return APIKeyCreatedResponse(
        **key.to_dict(),
        full_key=full_key,
    )

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from app.database import get_db
from app.models import MaintenanceComplaint
from app.middleware.auth import get_current_user
from app.models.organization import Employee

router = APIRouter(prefix="/maintenance", tags=["maintenance"])


@router.get("/")
async def list_complaints(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List maintenance complaints - requires authentication."""
    result = await db.execute(
        select(MaintenanceComplaint)
        .order_by(desc(MaintenanceComplaint.created_at))
        .limit(limit)
    )
    complaints = result.scalars().all()
    
    return [
        {
            "complaint_id": c.complaint_id,
            "complaint_number": c.complaint_number,
            "description": c.description,
            "priority": c.priority,
            "status": c.status,
            "reported_by": c.reported_by,
            "latitude": c.latitude,
            "longitude": c.longitude,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        }
        for c in complaints
    ]


@router.get("/me")
async def my_complaints(
    limit: int = Query(default=30, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get current user's maintenance complaints - requires authentication."""
    result = await db.execute(
        select(MaintenanceComplaint)
        .where(MaintenanceComplaint.reported_by == current_user.employee_id)
        .order_by(desc(MaintenanceComplaint.created_at))
        .limit(limit)
    )
    complaints = result.scalars().all()
    
    return [
        {
            "complaint_id": c.complaint_id,
            "complaint_number": c.complaint_number,
            "description": c.description,
            "status": c.status,
            "priority": c.priority,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        }
        for c in complaints
    ]

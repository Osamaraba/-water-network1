from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from app.database import get_db
from app.models import OvertimeWorkRequest
from app.middleware.auth import get_current_user
from app.models.organization import Employee

router = APIRouter(prefix="/overtime_work", tags=["overtime_work"])


@router.get("/")
async def list_overtime_requests(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List overtime work requests - requires authentication."""
    result = await db.execute(
        select(OvertimeWorkRequest)
        .order_by(desc(OvertimeWorkRequest.created_at))
        .limit(limit)
    )
    requests = result.scalars().all()
    
    return [
        {
            "request_id": r.request_id,
            "employee_id": r.employee_id,
            "task_description": r.task_description,
            "area_name": r.area_name,
            "requested_hours": r.requested_hours,
            "total_approved_hours": r.total_approved_hours,
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in requests
    ]


@router.get("/me")
async def my_overtime_requests(
    limit: int = Query(default=30, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get current user's overtime requests - requires authentication."""
    result = await db.execute(
        select(OvertimeWorkRequest)
        .where(OvertimeWorkRequest.employee_id == current_user.employee_id)
        .order_by(desc(OvertimeWorkRequest.created_at))
        .limit(limit)
    )
    requests = result.scalars().all()
    
    return [
        {
            "request_id": r.request_id,
            "task_description": r.task_description,
            "area_name": r.area_name,
            "requested_hours": r.requested_hours,
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in requests
    ]

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from app.database import get_db
from app.models import LeaveRequest
from app.middleware.auth import get_current_user
from app.models.organization import Employee

router = APIRouter(prefix="/leave_requests", tags=["leave_requests"])


@router.get("/")
async def list_leave_requests(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List leave requests - requires authentication."""
    result = await db.execute(
        select(LeaveRequest)
        .order_by(desc(LeaveRequest.created_at))
        .limit(limit)
    )
    requests = result.scalars().all()

    return {
        "items": [
            {
                "request_id": r.request_id,
                "employee_id": r.employee_id,
                "leave_type": r.leave_type,
                "leave_type_custom": r.leave_type_custom,
                "start_date": r.start_date.isoformat() if r.start_date else None,
                "end_date": r.end_date.isoformat() if r.end_date else None,
                "reason": r.reason,
                "status": r.status,
                "approved_by": r.approved_by,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in requests
        ]
    }


@router.get("/my")
async def my_leave_requests(
    limit: int = Query(default=30, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get current user's leave requests - requires authentication."""
    result = await db.execute(
        select(LeaveRequest)
        .where(LeaveRequest.employee_id == current_user.employee_id)
        .order_by(desc(LeaveRequest.created_at))
        .limit(limit)
    )
    requests = result.scalars().all()

    return {
        "items": [
            {
                "request_id": r.request_id,
                "leave_type": r.leave_type,
                "start_date": r.start_date.isoformat() if r.start_date else None,
                "end_date": r.end_date.isoformat() if r.end_date else None,
                "status": r.status,
            }
            for r in requests
        ]
    }


@router.get("/all")
async def all_leaves(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get all leave requests - compatibility for /leave/all."""
    result = await db.execute(
        select(LeaveRequest).order_by(desc(LeaveRequest.created_at)).limit(100)
    )
    requests = result.scalars().all()
    return {
        "items": [
            {
                "request_id": r.request_id,
                "employee_id": r.employee_id,
                "leave_type": r.leave_type,
                "start_date": r.start_date.isoformat() if r.start_date else None,
                "end_date": r.end_date.isoformat() if r.end_date else None,
                "status": r.status,
            }
            for r in requests
        ]
    }


@router.get("/{request_id}")
async def get_leave_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get leave request by ID - requires authentication."""
    result = await db.execute(
        select(LeaveRequest).where(LeaveRequest.request_id == request_id)
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Leave request not found")

    return {
        "request_id": req.request_id,
        "employee_id": req.employee_id,
        "leave_type": req.leave_type,
        "start_date": req.start_date.isoformat() if req.start_date else None,
        "end_date": req.end_date.isoformat() if req.end_date else None,
        "status": req.status,
    }

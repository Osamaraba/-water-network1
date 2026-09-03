"""
Bulk Actions API - Approve/Reject multiple items at once
Yarmouk Water Management Pro
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import update
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from app.database import get_db
from app.models import LeaveRequest, OvertimeWorkRequest, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/bulk", tags=["bulk-actions"])


# =============================================================================
# Request Models
# =============================================================================

class BulkActionRequest(BaseModel):
    ids: List[int]
    action: str  # "approve" or "reject"
    reason: Optional[str] = None


# =============================================================================
# Leave Bulk Actions
# =============================================================================

@router.post("/leave/approve")
async def bulk_approve_leave(
    request: BulkActionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Bulk approve or reject leave requests."""
    if request.action not in ("approve", "reject"):
        raise HTTPException(status_code=400, detail="Action must be 'approve' or 'reject'")
    
    new_status = "approved" if request.action == "approve" else "rejected"
    
    try:
        result = await db.execute(
            update(LeaveRequest)
            .where(LeaveRequest.request_id.in_(request.ids))
            .where(LeaveRequest.status == "pending")
            .values(
                status=new_status,
                reviewed_by=current_user.employee_id,
                reviewed_at=datetime.utcnow(),
                review_note=request.reason,
            )
        )
        
        await db.commit()
        
        return {
            "message": f"{result.rowcount} leave requests {new_status}",
            "updated_count": result.rowcount,
            "action": request.action,
        }
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Overtime Bulk Actions
# =============================================================================

@router.post("/overtime/approve")
async def bulk_approve_overtime(
    request: BulkActionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Bulk approve or reject overtime requests."""
    if request.action not in ("approve", "reject"):
        raise HTTPException(status_code=400, detail="Action must be 'approve' or 'reject'")
    
    new_status = "approved" if request.action == "approve" else "rejected"
    
    result = await db.execute(
        update(OvertimeWorkRequest)
        .where(OvertimeWorkRequest.request_id.in_(request.ids))
        .where(OvertimeWorkRequest.status == "pending")
        .values(
            status=new_status,
            reviewed_by=current_user.employee_id,
            reviewed_at=datetime.utcnow(),
            review_note=request.reason,
        )
    )
    
    await db.commit()
    
    return {
        "message": f"{len(request.ids)} overtime requests {new_status}",
        "updated_count": result.rowcount,
        "action": request.action,
    }

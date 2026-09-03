from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import AuditLog, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("/")
async def list_audit_logs(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List audit logs - requires authentication."""
    result = await db.execute(select(AuditLog).limit(limit))
    logs = result.scalars().all()
    return [
        {"log_id": l.log_id, "action": l.action, "employee_id": l.employee_id, "entity_type": l.entity_type, "timestamp": str(l.created_at) if l.created_at else None}
        for l in logs
    ]

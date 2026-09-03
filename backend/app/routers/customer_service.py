from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import CustomerServiceRequest, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/customer_service", tags=["customer_service"])


@router.get("/")
async def list_customer_requests(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List customer service requests - requires authentication."""
    result = await db.execute(select(CustomerServiceRequest).limit(limit))
    requests = result.scalars().all()
    return [
        {"request_id": r.request_id, "request_type": r.request_type, "status": r.status, "created_at": str(r.created_at) if r.created_at else None}
        for r in requests
    ]

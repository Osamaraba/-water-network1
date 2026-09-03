from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import WaterDistributionPlan, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/water_distribution", tags=["water_distribution"])


@router.get("/")
async def list_plans(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List water distribution plans - requires authentication."""
    result = await db.execute(select(WaterDistributionPlan).limit(limit))
    plans = result.scalars().all()
    return [
        {"plan_id": p.plan_id, "title": p.title, "status": p.status, "created_at": str(p.created_at) if p.created_at else None}
        for p in plans
    ]

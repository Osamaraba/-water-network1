from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import WorkScope, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/work_scopes", tags=["work_scopes"])


@router.get("/")
async def list_work_scopes(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List work scopes - requires authentication."""
    result = await db.execute(select(WorkScope))
    scopes = result.scalars().all()
    return [{"work_scope_id": s.work_scope_id, "scope_name": s.scope_name, "area": s.area} for s in scopes]

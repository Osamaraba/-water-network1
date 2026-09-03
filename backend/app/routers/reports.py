from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from app.database import get_db
from app.models import Report, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/inbox")
async def reports_inbox(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get reports inbox (compatibility endpoint)."""
    result = await db.execute(
        select(Report).order_by(desc(Report.created_at)).limit(50)
    )
    reports = result.scalars().all()
    return {
        "items": [
            {
                "report_id": r.report_id,
                "title": r.title,
                "report_type": r.report_type,
                "status": r.status,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reports
        ]
    }


@router.get("/")
async def list_reports(
    report_type: Optional[str] = None,
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List reports - requires authentication."""
    query = select(Report).order_by(desc(Report.created_at)).limit(limit)

    if report_type:
        query = query.where(Report.report_type == report_type)

    result = await db.execute(query)
    reports = result.scalars().all()

    return {
        "items": [
            {
                "report_id": r.report_id,
                "report_type": r.report_type,
                "title": r.title,
                "status": r.status,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reports
        ]
    }


@router.get("/daily")
async def daily_report(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get daily report (compatibility)."""
    result = await db.execute(
        select(Report).order_by(desc(Report.created_at)).limit(1)
    )
    r = result.scalar_one_or_none()
    if not r:
        return {"title": "", "items": []}
    return {
        "title": "Daily Report",
        "items": [
            {
                "report_id": r.report_id,
                "title": r.title,
                "description": r.description,
                "status": r.status,
            }
        ]
    }


@router.get("/{report_id}")
async def get_report(
    report_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get report by ID - requires authentication."""
    result = await db.execute(
        select(Report).where(Report.report_id == report_id)
    )
    r = result.scalar_one_or_none()
    if not r:
        raise HTTPException(status_code=404, detail="Report not found")

    return {
        "report_id": r.report_id,
        "report_type": r.report_type,
        "title": r.title,
        "description": r.description,
        "status": r.status,
        "created_at": r.created_at.isoformat() if r.created_at else None,
    }

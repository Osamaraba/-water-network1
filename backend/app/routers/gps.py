from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from datetime import datetime
from app.database import get_db
from app.models import FieldTrackingSession, FieldTrackingPoint, GeofenceBreach
from app.middleware.auth import get_current_user
from app.models.organization import Employee

router = APIRouter(prefix="/gps", tags=["gps"])


@router.get("/")
async def gps_root():
    """GPS tracking endpoints."""
    return {
        "message": "GPS Tracking API",
        "endpoints": {
            "GET /gps/sessions": "List tracking sessions",
            "GET /gps/sessions/me": "My active session",
            "GET /gps/breaches": "List geofence breaches",
        }
    }


@router.get("/sessions")
async def list_sessions(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List GPS tracking sessions - requires authentication."""
    result = await db.execute(
        select(FieldTrackingSession)
        .order_by(desc(FieldTrackingSession.started_at))
        .limit(limit)
    )
    sessions = result.scalars().all()
    
    return [
        {
            "session_id": s.session_id,
            "employee_id": s.employee_id,
            "tracking_type": s.tracking_type,
            "started_at": s.started_at.isoformat() if s.started_at else None,
            "ended_at": s.ended_at.isoformat() if s.ended_at else None,
            "status": s.status,
        }
        for s in sessions
    ]


@router.get("/sessions/me")
async def my_active_session(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get current user's active GPS session - requires authentication."""
    result = await db.execute(
        select(FieldTrackingSession)
        .where(
            FieldTrackingSession.employee_id == current_user.employee_id,
            FieldTrackingSession.status == "active"
        )
        .order_by(desc(FieldTrackingSession.started_at))
        .limit(1)
    )
    session = result.scalar_one_or_none()
    
    if not session:
        return {"message": "No active session"}
    
    return {
        "session_id": session.session_id,
        "employee_id": session.employee_id,
        "tracking_type": session.tracking_type,
        "started_at": session.started_at.isoformat() if session.started_at else None,
        "status": session.status,
    }


@router.get("/breaches")
async def list_breaches(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List geofence breaches - requires authentication."""
    result = await db.execute(
        select(GeofenceBreach)
        .order_by(desc(GeofenceBreach.started_at))
        .limit(limit)
    )
    breaches = result.scalars().all()
    
    return [
        {
            "breach_id": b.breach_id,
            "employee_id": b.employee_id,
            "session_id": b.session_id,
            "started_at": b.started_at.isoformat() if b.started_at else None,
            "ended_at": b.ended_at.isoformat() if b.ended_at else None,
            "duration_seconds": b.duration_seconds,
            "distance_m": b.distance_m,
            "start_latitude": b.start_latitude,
            "start_longitude": b.start_longitude,
        }
        for b in breaches
    ]

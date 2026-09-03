from fastapi import APIRouter, Depends, Query, Body, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from app.database import get_db
from app.models import Notification, User
from app.middleware.auth import get_current_user
from app.models.organization import Employee
from app.models.auth import Role, UserRole
from pydantic import BaseModel

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/")
async def list_notifications(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List notifications - requires authentication."""
    result = await db.execute(
        select(Notification)
        .where(Notification.employee_id == current_user.employee_id)
        .order_by(desc(Notification.created_at))
        .limit(limit)
    )
    notifications = result.scalars().all()
    
    return {
        "items": [
            {
                "notification_id": n.notification_id,
                "title": n.title,
                "body": n.message,
                "is_read": n.is_read,
                "severity": n.severity,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
            for n in notifications
        ]
    }


@router.get("/unread")
async def unread_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get unread notifications count - requires authentication."""
    result = await db.execute(
        select(Notification)
        .where(
            Notification.employee_id == current_user.employee_id,
            Notification.is_read == False
        )
    )
    notifications = result.scalars().all()

    return {
        "unread_count": len(notifications),
        "notifications": [
            {
                "notification_id": n.notification_id,
                "title": n.title,
                "body": n.message,
                "severity": n.severity,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
            for n in notifications
        ]
    }


@router.post("/{notification_id}/read")
async def mark_as_read(
    notification_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Mark notification as read - requires authentication."""
    result = await db.execute(
        select(Notification).where(Notification.notification_id == notification_id)
    )
    n = result.scalar_one_or_none()
    if not n:
        return {"error": "Notification not found"}
    
    n.is_read = True
    await db.commit()
    
    return {"message": "Marked as read"}


class NotificationCreate(BaseModel):
    employee_id: int
    title: str
    body: str
    severity: str = "info"


@router.post("/")
async def create_notification(
    payload: NotificationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Create notification for an employee - requires authentication."""
    # Check if target employee exists
    emp_res = await db.execute(
        select(Employee).where(Employee.employee_id == payload.employee_id)
    )
    target_emp = emp_res.scalar_one_or_none()
    if not target_emp:
        raise HTTPException(status_code=404, detail="Target employee not found")
    
    notification = Notification(
        employee_id=payload.employee_id,
        title=payload.title,
        message=payload.body,
        severity=payload.severity,
    )
    db.add(notification)
    await db.commit()
    await db.refresh(notification)
    
    return {
        "notification_id": notification.notification_id,
        "title": notification.title,
        "body": notification.message,
        "is_read": notification.is_read,
        "severity": notification.severity,
        "created_at": notification.created_at.isoformat() if notification.created_at else None,
    }


@router.post("/bulk")
async def create_bulk_notifications(
    payload: List[NotificationCreate],
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Create notifications for multiple employees."""
    results = []
    for item in payload:
        emp_res = await db.execute(
            select(Employee).where(Employee.employee_id == item.employee_id)
        )
        target_emp = emp_res.scalar_one_or_none()
        if not target_emp:
            results.append({"employee_id": item.employee_id, "error": "Employee not found"})
            continue
            
        notification = Notification(
            employee_id=item.employee_id,
            title=item.title,
            message=item.body,
            severity=item.severity,
        )
        db.add(notification)
        results.append({
            "employee_id": item.employee_id,
            "title": item.title,
            "status": "created"
        })
    
    await db.commit()
    return {"created": len(results), "results": results}

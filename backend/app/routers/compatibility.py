from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func, and_
from typing import Optional
from datetime import datetime, date
from app.database import get_db
from app.models import LeaveRequest
from app.middleware.auth import get_current_user
from app.models.organization import Employee
from app.models import Attendance, FieldTrackingSession
from app.models.field_tracking import FieldTrackingPoint

router = APIRouter(tags=["compatibility"])


class LeaveCreateRequest:
    pass

from pydantic import BaseModel

class LeaveCreateSchema(BaseModel):
    leave_type: str
    start_date: str
    end_date: str
    reason: Optional[str] = None
    leave_type_custom: Optional[str] = None


@router.post("/leave/")
async def create_leave_request(
    body: LeaveCreateSchema,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Create a leave request (compatibility endpoint)."""
    leave = LeaveRequest(
        employee_id=current_user.employee_id,
        leave_type=body.leave_type,
        leave_type_custom=body.leave_type_custom,
        start_date=datetime.fromisoformat(body.start_date).date() if body.start_date else None,
        end_date=datetime.fromisoformat(body.end_date).date() if body.end_date else None,
        reason=body.reason,
        status="pending",
    )
    db.add(leave)
    await db.commit()
    await db.refresh(leave)

    from app.services.notifications import notify_direct_manager
    leave_type_labels = {'annual': 'سنوية', 'sick': 'مرضية', 'unpaid': 'بدون راتب', 'maternity': 'أمومة', 'paternity': 'أبوة', 'other': 'أخرى'}
    leave_type_label = leave_type_labels.get(body.leave_type, body.leave_type)
    await notify_direct_manager(
        db,
        current_user.employee_id,
        "طلب إجازة جديد",
        f" الموظف {current_user.full_name} تقدم بطلب إجازة {leave_type_label} من {body.start_date} إلى {body.end_date}",
        severity="info",
    )

    return {"request_id": leave.request_id, "status": leave.status}


@router.get("/leave/my")
async def my_leaves_compat(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get current user's leave requests (compatibility for /leave/my)."""
    result = await db.execute(
        select(LeaveRequest)
        .where(LeaveRequest.employee_id == current_user.employee_id)
        .order_by(desc(LeaveRequest.created_at))
        .limit(100)
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


@router.get("/leave/all")
async def get_all_leaves_compat(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get all leaves (compatibility)."""
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


@router.get("/gps/my-active")
async def gps_my_active(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get active GPS session (compatibility)."""
    result = await db.execute(
        select(FieldTrackingSession).where(
            and_(
                FieldTrackingSession.employee_id == current_user.employee_id,
                FieldTrackingSession.status == "active"
            )
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        return {"session": None}
    return {
        "session": {
            "session_id": session.session_id,
            "is_active": session.status == "active",
            "started_at": session.started_at.isoformat() if session.started_at else None,
        }
    }


@router.get("/gps/view")
async def gps_view(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get GPS view data (compatibility)."""
    result = await db.execute(
        select(FieldTrackingSession).where(
            FieldTrackingSession.status == "active"
        ).limit(50)
    )
    sessions = result.scalars().all()
    items = []
    for s in sessions:
        emp_res = await db.execute(select(Employee).where(Employee.employee_id == s.employee_id))
        emp = emp_res.scalar_one_or_none()
        viewer_name = None
        if s.viewer_employee_id:
            v_res = await db.execute(select(Employee).where(Employee.employee_id == s.viewer_employee_id))
            v = v_res.scalar_one_or_none()
            viewer_name = v.full_name if v else None
        items.append({
            "session_id": s.session_id, "employee_id": s.employee_id,
            "is_active": True, "track_mode": s.track_mode, "track_interval": s.track_interval,
            "track_color": s.track_color, "is_outside": s.is_outside,
            "outside_started_at": s.outside_started_at.isoformat() if s.outside_started_at else None,
            "outside_distance_m": s.outside_distance_m,
            "started_at": s.started_at.isoformat() if s.started_at else None,
            "viewer_employee_id": s.viewer_employee_id, "viewer_name": viewer_name,
            "started_by_id": s.started_by_id,
            "target": {
                "employee_id": s.employee_id,
                "full_name": emp.full_name if emp else "",
                "employee_number": emp.employee_number if emp else "",
                "geofence_lat": emp.geofence_lat if emp else None,
                "geofence_lng": emp.geofence_lng if emp else None,
                "geofence_radius_m": emp.geofence_radius_m if emp else 200,
            },
        })
    return {"items": items}


@router.get("/gps/employees")
async def gps_employees(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get employees with GPS tracking (compatibility)."""
    result = await db.execute(
        select(FieldTrackingSession).where(
            FieldTrackingSession.status == "active"
        ).limit(100)
    )
    sessions = result.scalars().all()
    items = []
    for s in sessions:
        emp_res = await db.execute(select(Employee).where(Employee.employee_id == s.employee_id))
        emp = emp_res.scalar_one_or_none()
        pts_res = await db.execute(
            select(FieldTrackingPoint).where(FieldTrackingPoint.session_id == s.session_id)
            .order_by(desc(FieldTrackingPoint.recorded_at)).limit(100)
        )
        points = [{"latitude": p.latitude, "longitude": p.longitude, "recorded_at": p.recorded_at.isoformat() if p.recorded_at else None} for p in pts_res.scalars().all()]
        items.append({
            "employee_id": s.employee_id,
            "session_id": s.session_id,
            "is_active": True,
            "track_color": s.track_color,
            "is_outside": s.is_outside,
            "outside_started_at": s.outside_started_at.isoformat() if s.outside_started_at else None,
            "outside_distance_m": s.outside_distance_m,
            "track_mode": s.track_mode,
            "track_interval": s.track_interval,
            "started_at": s.started_at.isoformat() if s.started_at else None,
            "full_name": emp.full_name if emp else "",
            "employee_number": emp.employee_number if emp else "",
            "geofence_lat": emp.geofence_lat if emp else None,
            "geofence_lng": emp.geofence_lng if emp else None,
            "geofence_radius_m": emp.geofence_radius_m if emp else 200,
            "points": points,
        })
    return {"items": items}


@router.get("/organization/units")
async def org_units(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get organization units (compatibility)."""
    from app.models.organization import OrganizationUnit
    result = await db.execute(
        select(OrganizationUnit).limit(200)
    )
    units = result.scalars().all()
    return {
        "items": [
            {
                "org_unit_id": u.org_unit_id,
                "unit_name": u.unit_name,
                "unit_name_en": u.unit_name_en,
                "unit_code": u.unit_code,
                "parent_id": u.parent_id,
                "unit_type": u.unit_type,
                "is_active": u.is_active,
            }
            for u in units
        ]
    }


@router.get("/organization/tree")
async def org_tree(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get organization tree (compatibility)."""
    from app.models.organization import OrganizationUnit
    result = await db.execute(select(OrganizationUnit).limit(100))
    units = result.scalars().all()
    return {
        "tree": [
            {
                "org_unit_id": u.org_unit_id,
                "name": u.unit_name,
                "parent_id": u.parent_id,
                "children": []
            }
            for u in units
        ]
    }


@router.get("/employees/roles")
async def get_roles(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get roles (compatibility)."""
    from app.models.auth import Role
    result = await db.execute(select(Role).order_by(Role.role_id))
    roles = result.scalars().all()
    return {
        "items": [
            {"role_id": r.role_id, "role_name": r.role_name, "role_label": r.role_label or r.role_name} for r in roles
        ]
    }


@router.get("/employees/work-types")
async def get_work_types(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get work types (compatibility)."""
    from app.models.organization import WorkType
    result = await db.execute(select(WorkType).order_by(WorkType.work_type_id))
    types = result.scalars().all()
    return {
        "items": [
            {"work_type_id": t.work_type_id, "type_name": t.type_name, "type_name_ar": t.type_name_ar, "is_field": t.is_field} for t in types
        ]
    }


# maintenance complaints endpoints moved to maintenance_teams.py


@router.get("/reports/inbox")
async def reports_inbox(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get reports inbox (compatibility)."""
    from app.models.report import Report
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

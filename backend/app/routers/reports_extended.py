"""
Extended Reports API - Dashboard KPIs, Analytics & Export
Yarmouk Water Management Pro
"""
from fastapi import APIRouter, Depends, Query, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from datetime import date, datetime, timedelta
from typing import Optional
from app.database import get_db
from app.models import (
    Employee, Attendance, LeaveRequest, OvertimeWorkRequest,
    Report, AuditLog
)
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/reports-extended", tags=["reports-extended"])


# =============================================================================
# Dashboard KPIs
# =============================================================================

@router.get("/dashboard")
async def dashboard_kpis(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """
    Real-time dashboard KPIs:
    - Total active employees
    - Present today
    - On leave today
    - Late arrivals today
    - Overtime requests pending
    - Reports submitted this week
    """
    today = date.today()
    week_start = today - timedelta(days=today.weekday())

    # Total active employees
    total_result = await db.execute(
        select(func.count(Employee.employee_id)).where(Employee.is_active == True)
    )
    total_employees = total_result.scalar() or 0

    # Present today
    from sqlalchemy import cast, Date
    present_result = await db.execute(
        select(func.count(Attendance.attendance_id)).where(
            and_(
                cast(Attendance.check_in_time, Date) == today,
                Attendance.status == "present"
            )
        )
    )
    present_today = present_result.scalar() or 0

    # On leave today
    leave_result = await db.execute(
        select(func.count(LeaveRequest.request_id)).where(
            and_(
                LeaveRequest.start_date <= today,
                LeaveRequest.end_date >= today,
                LeaveRequest.status == "approved"
            )
        )
    )
    on_leave = leave_result.scalar() or 0

    # Late arrivals today
    late_result = await db.execute(
        select(func.count(Attendance.attendance_id)).where(
            and_(
                cast(Attendance.check_in_time, Date) == today,
                Attendance.status == "late"
            )
        )
    )
    late_arrivals = late_result.scalar() or 0

    # Overtime requests pending
    overtime_pending_result = await db.execute(
        select(func.count(OvertimeWorkRequest.request_id)).where(
            OvertimeWorkRequest.status == "pending"
        )
    )
    overtime_pending = overtime_pending_result.scalar() or 0

    # Reports this week
    reports_week_result = await db.execute(
        select(func.count(Report.report_id)).where(
            Report.created_at >= week_start.isoformat()
        )
    )
    reports_this_week = reports_week_result.scalar() or 0

    return {
        "date": today.isoformat(),
        "total_employees": total_employees,
        "present_today": present_today,
        "on_leave": on_leave,
        "late_arrivals": late_arrivals,
        "overtime_pending": overtime_pending,
        "reports_this_week": reports_this_week,
        "absent_today": total_employees - present_today - on_leave,
    }


# =============================================================================
# Attendance Analytics
# =============================================================================

@router.get("/attendance/summary")
async def attendance_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Attendance summary with breakdown by status."""
    from sqlalchemy import cast, Date
    from datetime import datetime as dt
    
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=30)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(
        Attendance.status,
        func.count(Attendance.attendance_id).label("count")
    ).where(
        and_(
            cast(Attendance.check_in_time, Date) >= sd,
            cast(Attendance.check_in_time, Date) <= ed
        )
    ).group_by(Attendance.status)

    result = await db.execute(query)
    rows = result.all()

    summary = {row.status: row.count for row in rows}

    total = sum(summary.values())
    return {
        "period": {"start": sd.isoformat(), "end": ed.isoformat()},
        "total_records": total,
        "breakdown": summary,
        "attendance_rate": round(
            (summary.get("present", 0) + summary.get("late", 0)) / total * 100, 1
        ) if total > 0 else 0,
    }


# =============================================================================
# Leave Analytics
# =============================================================================

@router.get("/leave/summary")
async def leave_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Leave requests summary with breakdown by status and type."""
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=90)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(
        LeaveRequest.leave_type,
        LeaveRequest.status,
        func.count(LeaveRequest.request_id).label("count")
    ).where(
        and_(
            LeaveRequest.start_date >= sd,
            LeaveRequest.start_date <= ed
        )
    ).group_by(LeaveRequest.leave_type, LeaveRequest.status)

    result = await db.execute(query)
    rows = result.all()

    by_type = {}
    by_status = {"pending": 0, "approved": 0, "rejected": 0}
    for row in rows:
        if row.leave_type not in by_type:
            by_type[row.leave_type] = {}
        by_type[row.leave_type][row.status] = row.count
        if row.status in by_status:
            by_status[row.status] += row.count

    return {
        "period": {"start": sd.isoformat(), "end": ed.isoformat()},
        "total_requests": sum(by_status.values()),
        "by_status": by_status,
        "by_type": by_type,
    }


# =============================================================================
# Overtime Analytics
# =============================================================================

@router.get("/overtime/summary")
async def overtime_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Overtime work summary."""
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=90)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(
        OvertimeWorkRequest.status,
        func.count(OvertimeWorkRequest.request_id).label("count")
    ).where(
        and_(
            OvertimeWorkRequest.created_at >= sd.isoformat(),
            OvertimeWorkRequest.created_at <= ed.isoformat() + "T23:59:59"
        )
    ).group_by(OvertimeWorkRequest.status)

    result = await db.execute(query)
    rows = result.all()

    summary = {row.status: row.count for row in rows}

    return {
        "period": {"start": sd.isoformat(), "end": ed.isoformat()},
        "total_requests": sum(summary.values()),
        "breakdown": summary,
    }


# =============================================================================
# Employee Reports
# =============================================================================

@router.get("/employees/directory")
async def employee_directory(
    org_unit_id: Optional[int] = None,
    is_active: Optional[bool] = True,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Employee directory with org unit info."""
    query = select(Employee).where(Employee.is_active == is_active)

    if org_unit_id:
        query = query.where(Employee.org_unit_id == org_unit_id)

    result = await db.execute(query.order_by(Employee.full_name))
    employees = result.scalars().all()

    return {
        "total": len(employees),
        "items": [
            {
                "employee_id": e.employee_id,
                "employee_number": e.employee_number,
                "full_name": e.full_name,
                "job_title": e.job_title,
                "phone": e.phone,
                "email": e.email,
                "org_unit_id": e.org_unit_id,
                "is_active": e.is_active,
            }
            for e in employees
        ],
    }


# =============================================================================
# Audit Log
# =============================================================================

@router.get("/audit")
async def audit_log(
    limit: int = Query(default=50, le=200),
    action: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Audit log with filters."""
    query = select(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit)

    if action:
        query = query.where(AuditLog.action == action)

    result = await db.execute(query)
    logs = result.scalars().all()

    return {
        "items": [
            {
                "log_id": log.log_id,
                "employee_id": log.employee_id,
                "action": log.action,
                "entity_type": log.entity_type,
                "entity_id": log.entity_id,
                "old_values": log.old_values,
                "new_values": log.new_values,
                "created_at": log.created_at.isoformat() if log.created_at else None,
            }
            for log in logs
        ]
    }


# =============================================================================
# Export Endpoints (CSV)
# =============================================================================

@router.get("/export/attendance")
async def export_attendance_csv(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Export attendance as CSV."""
    from sqlalchemy import cast, Date
    
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=30)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(Attendance).where(
        and_(
            cast(Attendance.check_in_time, Date) >= sd,
            cast(Attendance.check_in_time, Date) <= ed
        )
    ).order_by(Attendance.check_in_time.desc())

    result = await db.execute(query)
    records = result.scalars().all()

    csv_lines = ["date,employee_id,status,check_in,check_out"]
    for r in records:
        check_in_date = r.check_in_time.strftime('%Y-%m-%d') if r.check_in_time else ''
        check_in = r.check_in_time.strftime('%H:%M:%S') if r.check_in_time else ''
        check_out = r.check_out_time.strftime('%H:%M:%S') if r.check_out_time else ''
        csv_lines.append(
            f"{check_in_date},{r.employee_id},{r.status},{check_in},{check_out}"
        )

    csv_content = "\n".join(csv_lines)

    return StreamingResponse(
        iter([csv_content]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=attendance_{sd}_{ed}.csv"}
    )


# =============================================================================
# Enhanced Administrative Reports
# =============================================================================

@router.get("/admin/attendance")
async def admin_attendance_report(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    employee_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Enhanced attendance report with employee details."""
    from sqlalchemy import cast, Date
    
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=30)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(Attendance).where(
        and_(
            cast(Attendance.check_in_time, Date) >= sd,
            cast(Attendance.check_in_time, Date) <= ed
        )
    )
    if employee_id:
        query = query.where(Attendance.employee_id == employee_id)

    result = await db.execute(query.order_by(Attendance.check_in_time.desc()))
    records = result.scalars().all()

    emp_stats = {}
    for r in records:
        eid = r.employee_id
        if eid not in emp_stats:
            emp_res = await db.execute(select(Employee).where(Employee.employee_id == eid))
            emp = emp_res.scalar_one_or_none()
            emp_stats[eid] = {
                "employee_id": eid,
                "employee_name": emp.full_name if emp else "غير معروف",
                "employee_number": emp.employee_number if emp else "",
                "total_days": 0,
                "present": 0,
                "late": 0,
                "absent": 0,
                "total_hours": 0.0,
            }
        emp_stats[eid]["total_days"] += 1
        if r.status == "present" or r.status == "active":
            emp_stats[eid]["present"] += 1
        elif r.status == "late":
            emp_stats[eid]["late"] += 1
        elif r.status == "absent":
            emp_stats[eid]["absent"] += 1
        if r.work_duration_hours:
            emp_stats[eid]["total_hours"] += r.work_duration_hours

    items = list(emp_stats.values())
    for item in items:
        working_days = item["present"] + item["late"]
        item["attendance_rate"] = round(working_days / item["total_days"] * 100, 1) if item["total_days"] > 0 else 0
        item["total_hours"] = round(item["total_hours"], 1)

    total_present = sum(i["present"] for i in items)
    total_late = sum(i["late"] for i in items)
    total_days = sum(i["total_days"] for i in items)

    return {
        "period": {"start": sd.isoformat(), "end": ed.isoformat()},
        "summary": {
            "total_employees": len(items),
            "total_records": total_days,
            "total_present": total_present,
            "total_late": total_late,
            "attendance_rate": round((total_present + total_late) / total_days * 100, 1) if total_days > 0 else 0,
        },
        "items": items,
    }


@router.get("/admin/leave")
async def admin_leave_report(
    year: Optional[int] = None,
    employee_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Enhanced leave report with employee details."""
    today = date.today()
    yr = year or today.year
    sd = date(yr, 1, 1)
    ed = date(yr, 12, 31)

    query = select(LeaveRequest).where(
        and_(
            LeaveRequest.start_date >= sd,
            LeaveRequest.start_date <= ed
        )
    )
    if employee_id:
        query = query.where(LeaveRequest.employee_id == employee_id)

    result = await db.execute(query.order_by(LeaveRequest.created_at.desc()))
    records = result.scalars().all()

    emp_stats = {}
    for r in records:
        eid = r.employee_id
        if eid not in emp_stats:
            emp_res = await db.execute(select(Employee).where(Employee.employee_id == eid))
            emp = emp_res.scalar_one_or_none()
            emp_stats[eid] = {
                "employee_id": eid,
                "employee_name": emp.full_name if emp else "غير معروف",
                "employee_number": emp.employee_number if emp else "",
                "total_requests": 0,
                "approved": 0,
                "rejected": 0,
                "pending": 0,
                "by_type": {},
            }
        emp_stats[eid]["total_requests"] += 1
        if r.status == "approved":
            emp_stats[eid]["approved"] += 1
        elif r.status == "rejected":
            emp_stats[eid]["rejected"] += 1
        elif r.status == "pending":
            emp_stats[eid]["pending"] += 1
        
        lt = r.leave_type or "other"
        if lt not in emp_stats[eid]["by_type"]:
            emp_stats[eid]["by_type"][lt] = 0
        emp_stats[eid]["by_type"][lt] += 1

    items = list(emp_stats.values())
    total_requests = sum(i["total_requests"] for i in items)
    total_approved = sum(i["approved"] for i in items)
    total_rejected = sum(i["rejected"] for i in items)
    total_pending = sum(i["pending"] for i in items)

    return {
        "year": yr,
        "summary": {
            "total_employees": len(items),
            "total_requests": total_requests,
            "approved": total_approved,
            "rejected": total_rejected,
            "pending": total_pending,
        },
        "items": items,
    }


@router.get("/admin/overtime")
async def admin_overtime_report(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    employee_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Enhanced overtime report with employee details."""
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=90)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(OvertimeWorkRequest).where(
        and_(
            OvertimeWorkRequest.work_date >= sd,
            OvertimeWorkRequest.work_date <= ed
        )
    )
    if employee_id:
        query = query.where(OvertimeWorkRequest.employee_id == employee_id)

    result = await db.execute(query.order_by(OvertimeWorkRequest.created_at.desc()))
    records = result.scalars().all()

    emp_stats = {}
    for r in records:
        eid = r.employee_id
        if eid not in emp_stats:
            emp_res = await db.execute(select(Employee).where(Employee.employee_id == eid))
            emp = emp_res.scalar_one_or_none()
            emp_stats[eid] = {
                "employee_id": eid,
                "employee_name": emp.full_name if emp else "غير معروف",
                "employee_number": emp.employee_number if emp else "",
                "total_requests": 0,
                "completed": 0,
                "approved": 0,
                "pending": 0,
                "rejected": 0,
                "requested_hours": 0.0,
                "actual_hours": 0.0,
            }
        emp_stats[eid]["total_requests"] += 1
        if r.status == "completed":
            emp_stats[eid]["completed"] += 1
        elif r.status == "approved":
            emp_stats[eid]["approved"] += 1
        elif r.status == "pending":
            emp_stats[eid]["pending"] += 1
        elif r.status == "rejected":
            emp_stats[eid]["rejected"] += 1
        emp_stats[eid]["requested_hours"] += r.requested_hours or 0
        emp_stats[eid]["actual_hours"] += r.actual_hours or 0

    items = list(emp_stats.values())
    for item in items:
        item["requested_hours"] = round(item["requested_hours"], 1)
        item["actual_hours"] = round(item["actual_hours"], 1)

    total_requested = sum(i["requested_hours"] for i in items)
    total_actual = sum(i["actual_hours"] for i in items)

    return {
        "period": {"start": sd.isoformat(), "end": ed.isoformat()},
        "summary": {
            "total_employees": len(items),
            "total_requests": sum(i["total_requests"] for i in items),
            "completed": sum(i["completed"] for i in items),
            "total_requested_hours": total_requested,
            "total_actual_hours": total_actual,
        },
        "items": items,
    }


@router.get("/admin/violations")
async def admin_violations_report(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    employee_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Violations report with employee details."""
    from app.models.violation import ViolationNotice
    
    today = date.today()
    sd = date.fromisoformat(start_date) if start_date else today - timedelta(days=90)
    ed = date.fromisoformat(end_date) if end_date else today

    query = select(ViolationNotice).where(
        and_(
            ViolationNotice.created_at >= sd.isoformat(),
            ViolationNotice.created_at <= ed.isoformat() + "T23:59:59"
        )
    )
    if employee_id:
        query = query.where(ViolationNotice.employee_id == employee_id)

    result = await db.execute(query.order_by(ViolationNotice.created_at.desc()))
    records = result.scalars().all()

    emp_stats = {}
    for r in records:
        eid = r.employee_id
        if eid not in emp_stats:
            emp_res = await db.execute(select(Employee).where(Employee.employee_id == eid))
            emp = emp_res.scalar_one_or_none()
            emp_stats[eid] = {
                "employee_id": eid,
                "employee_name": emp.full_name if emp else "غير معروف",
                "employee_number": emp.employee_number if emp else "",
                "total_violations": 0,
                "acknowledged": 0,
                "pending": 0,
            }
        emp_stats[eid]["total_violations"] += 1
        if getattr(r, 'acknowledged', False):
            emp_stats[eid]["acknowledged"] += 1
        else:
            emp_stats[eid]["pending"] += 1

    items = list(emp_stats.values())
    return {
        "period": {"start": sd.isoformat(), "end": ed.isoformat()},
        "summary": {
            "total_employees": len(items),
            "total_violations": sum(i["total_violations"] for i in items),
            "acknowledged": sum(i["acknowledged"] for i in items),
            "pending": sum(i["pending"] for i in items),
        },
        "items": items,
    }

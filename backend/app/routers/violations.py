from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, and_, func
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.models.violation import ViolationNotice
from app.middleware.auth import get_current_user
from app.models.organization import Employee
from app.services.notifications import notify_employee, notify_direct_manager, notify_hr_managers

router = APIRouter(prefix="/violations", tags=["violations"])


class ViolationCreate(BaseModel):
    employee_id: int
    violation_type: str
    violation_date: str
    violation_time: str
    penalty: str = "alert1"
    notes: Optional[str] = None


class ViolationResponse(BaseModel):
    response: str


class HrReview(BaseModel):
    hr_notes: str
    status: str = "reviewed"


def _violation_dict(v: ViolationNotice, issuer_name: str = None, employee_name: str = None) -> dict:
    penalty_labels = {
        'alert1': 'تنبيه',
        'alert2': 'تنبيه ثاني',
        'warning': 'انذار',
        'interrogation': 'استجواب',
    }
    status_labels = {
        'pending': 'قيد الانتظار',
        'acknowledged': 'مستلمة',
        'disputed': 'معلقة',
        'reviewed': 'تمت المراجعة',
        'closed': 'مغلقة',
    }
    return {
        "violation_id": v.violation_id,
        "issuer_id": v.issuer_id,
        "issuer_name": issuer_name,
        "employee_id": v.employee_id,
        "employee_name": employee_name,
        "violation_type": v.violation_type,
        "violation_date": v.violation_date.isoformat() if v.violation_date else None,
        "violation_time": str(v.violation_time) if v.violation_time else None,
        "penalty": v.penalty,
        "penalty_label": penalty_labels.get(v.penalty, v.penalty),
        "notes": v.notes,
        "status": v.status,
        "status_label": status_labels.get(v.status, v.status),
        "acknowledged": v.acknowledged,
        "acknowledged_at": v.acknowledged_at.isoformat() if v.acknowledged_at else None,
        "employee_response": v.employee_response,
        "employee_response_at": v.employee_response_at.isoformat() if v.employee_response_at else None,
        "hr_reviewed": v.hr_reviewed,
        "hr_reviewed_at": v.hr_reviewed_at.isoformat() if v.hr_reviewed_at else None,
        "hr_reviewer_id": v.hr_reviewer_id,
        "hr_notes": v.hr_notes,
        "created_at": v.created_at.isoformat() if v.created_at else None,
    }


async def _enrich_violation(db: AsyncSession, v: ViolationNotice) -> dict:
    issuer_name = None
    employee_name = None
    if v.issuer_id:
        issuer_res = await db.execute(select(Employee.full_name).where(Employee.employee_id == v.issuer_id))
        row = issuer_res.first()
        if row:
            issuer_name = row[0]
    if v.employee_id:
        emp_res = await db.execute(select(Employee.full_name).where(Employee.employee_id == v.employee_id))
        row = emp_res.first()
        if row:
            employee_name = row[0]
    return _violation_dict(v, issuer_name, employee_name)


@router.post("/")
async def create_violation(
    body: ViolationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    from datetime import date as d_date, time as t_time
    try:
        v_date = d_date.fromisoformat(body.violation_date)
    except:
        raise HTTPException(400, "صيغة التاريخ غير صحيحة")
    try:
        parts = body.violation_time.split(":")
        v_time = t_time(int(parts[0]), int(parts[1]))
    except:
        raise HTTPException(400, "صيغة الوقت غير صحيحة")

    violation = ViolationNotice(
        issuer_id=current_user.employee_id,
        employee_id=body.employee_id,
        violation_type=body.violation_type,
        violation_date=v_date,
        violation_time=v_time,
        penalty=body.penalty,
        notes=body.notes,
        status="pending",
    )
    db.add(violation)
    await db.commit()
    await db.refresh(violation)

    emp_name = None
    emp_res = await db.execute(select(Employee.full_name).where(Employee.employee_id == body.employee_id))
    row = emp_res.first()
    if row:
        emp_name = row[0]

    await notify_employee(db, body.employee_id, "مخالفة جديدة", f"تم إصدار مخالفة من {current_user.full_name}: {body.violation_type}")
    await notify_direct_manager(db, current_user.employee_id, "مخالفة جديدة", f"تم إصدار مخالفة لـ {emp_name}")

    return await _enrich_violation(db, violation)


@router.get("/")
async def list_violations(
    status: Optional[str] = None,
    employee_id: Optional[int] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = select(ViolationNotice).order_by(desc(ViolationNotice.created_at))
    
    if status:
        query = query.where(ViolationNotice.status == status)
    if employee_id:
        query = query.where(ViolationNotice.employee_id == employee_id)
    if start_date:
        query = query.where(ViolationNotice.violation_date >= date.fromisoformat(start_date))
    if end_date:
        query = query.where(ViolationNotice.violation_date <= date.fromisoformat(end_date))
    
    query = query.limit(limit)
    result = await db.execute(query)
    violations = result.scalars().all()

    items = []
    for v in violations:
        items.append(await _enrich_violation(db, v))

    return {"items": items, "total": len(items)}


@router.get("/me")
async def my_violations(
    limit: int = Query(default=30, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice)
        .where(ViolationNotice.employee_id == current_user.employee_id)
        .order_by(desc(ViolationNotice.created_at))
        .limit(limit)
    )
    violations = result.scalars().all()
    items = []
    for v in violations:
        items.append(await _enrich_violation(db, v))
    return {"items": items, "total": len(items)}


@router.get("/team")
async def team_violations(
    status: Optional[str] = None,
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    subordinates = await db.execute(
        select(Employee.employee_id).where(Employee.direct_manager_id == current_user.employee_id)
    )
    sub_ids = [r[0] for r in subordinates.all()]
    
    query = select(ViolationNotice).where(ViolationNotice.issuer_id == current_user.employee_id)
    if status:
        query = query.where(ViolationNotice.status == status)
    query = query.order_by(desc(ViolationNotice.created_at)).limit(limit)
    
    result = await db.execute(query)
    violations = result.scalars().all()
    
    items = []
    for v in violations:
        items.append(await _enrich_violation(db, v))
    
    return {"items": items, "total": len(items)}


@router.get("/pending-review")
async def pending_review(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice)
        .where(ViolationNotice.hr_reviewed == False)
        .order_by(desc(ViolationNotice.created_at))
        .limit(limit)
    )
    violations = result.scalars().all()
    
    items = []
    for v in violations:
        items.append(await _enrich_violation(db, v))
    
    return {"items": items, "total": len(items)}


@router.get("/stats")
async def violation_stats(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = select(ViolationNotice)
    if start_date:
        query = query.where(ViolationNotice.violation_date >= date.fromisoformat(start_date))
    if end_date:
        query = query.where(ViolationNotice.violation_date <= date.fromisoformat(end_date))
    
    result = await db.execute(query)
    violations = result.scalars().all()
    
    total = len(violations)
    by_penalty = {}
    by_status = {}
    by_employee = {}
    
    for v in violations:
        by_penalty[v.penalty] = by_penalty.get(v.penalty, 0) + 1
        by_status[v.status] = by_status.get(v.status, 0) + 1
        if v.employee_id not in by_employee:
            by_employee[v.employee_id] = 0
        by_employee[v.employee_id] += 1
    
    emp_names = {}
    for eid in by_employee.keys():
        emp_res = await db.execute(select(Employee.full_name).where(Employee.employee_id == eid))
        row = emp_res.first()
        if row:
            emp_names[eid] = row[0]
    
    by_employee_named = {emp_names.get(k, f"موظف #{k}"): v for k, v in by_employee.items()}
    
    return {
        "total": total,
        "by_penalty": by_penalty,
        "by_status": by_status,
        "by_employee": by_employee_named,
    }


@router.get("/{violation_id}")
async def get_violation(
    violation_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice).where(ViolationNotice.violation_id == violation_id)
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Violation not found")
    return await _enrich_violation(db, v)


@router.post("/{violation_id}/acknowledge")
async def acknowledge_violation(
    violation_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice).where(ViolationNotice.violation_id == violation_id)
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Violation not found")
    
    if v.employee_id != current_user.employee_id:
        raise HTTPException(status_code=403, detail="غير مصرح لك باستلام هذه المخالفة")
    
    v.acknowledged = True
    v.acknowledged_at = datetime.utcnow()
    v.status = "acknowledged"
    await db.commit()
    
    await notify_direct_manager(db, current_user.employee_id, "استلام مخالفة", f"قام {current_user.full_name} باستلام المخالفة #{violation_id}")
    
    return await _enrich_violation(db, v)


@router.post("/{violation_id}/respond")
async def respond_violation(
    violation_id: int,
    body: ViolationResponse,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice).where(ViolationNotice.violation_id == violation_id)
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Violation not found")
    
    if v.employee_id != current_user.employee_id:
        raise HTTPException(status_code=403, detail="غير مصرح لك بالرد على هذه المخالفة")
    
    v.employee_response = body.response
    v.employee_response_at = datetime.utcnow()
    v.status = "disputed"
    await db.commit()
    
    await notify_direct_manager(db, current_user.employee_id, "رد على مخالفة", f"قام {current_user.full_name} بالرد على المخالفة #{violation_id}")
    await notify_hr_managers(db, "رد على مخالفة", f"قام {current_user.full_name} بالرد على المخالفة #{violation_id}")
    
    return await _enrich_violation(db, v)


@router.post("/{violation_id}/hr-review")
async def hr_review_violation(
    violation_id: int,
    body: HrReview,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice).where(ViolationNotice.violation_id == violation_id)
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Violation not found")
    
    v.hr_reviewed = True
    v.hr_reviewed_at = datetime.utcnow()
    v.hr_reviewer_id = current_user.employee_id
    v.hr_notes = body.hr_notes
    v.status = body.status
    await db.commit()
    
    await notify_employee(db, v.employee_id, "تمت مراجعة المخالفة", f"تمت مراجعة المخالفة #{violation_id} من قبل شؤون الموظفين")
    await notify_direct_manager(db, v.issuer_id, "تمت مراجعة مخالفة", f"تمت مراجعة المخالفة #{violation_id} من قبل شؤون الموظفين")
    
    return await _enrich_violation(db, v)


@router.get("/{violation_id}/print")
async def print_violation(
    violation_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(ViolationNotice).where(ViolationNotice.violation_id == violation_id)
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Violation not found")
    
    return await _enrich_violation(db, v)

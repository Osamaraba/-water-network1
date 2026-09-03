from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, and_, func
from datetime import datetime, date, time as t_time
from typing import Optional, List
from pydantic import BaseModel
from app.database import get_db
from app.models.maintenance import MaintenanceTeam, TeamMember, MaintenanceComplaint
from app.middleware.auth import get_current_user
from app.models.organization import Employee
from app.services.notifications import notify_employee, notify_direct_manager

router = APIRouter(prefix="/maintenance-teams", tags=["maintenance-teams"])


# ============== Pydantic Models ==============

class TeamCreate(BaseModel):
    team_name: str
    team_type: str
    governorate: str
    team_leader_id: Optional[int] = None
    max_active_tasks: int = 5


class TeamUpdate(BaseModel):
    team_name: Optional[str] = None
    team_type: Optional[str] = None
    governorate: Optional[str] = None
    team_leader_id: Optional[int] = None
    max_active_tasks: Optional[int] = None
    is_active: Optional[bool] = None


class TeamMemberAdd(BaseModel):
    employee_id: int
    role: str = "technician"


class ComplaintCreate(BaseModel):
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    description: str
    category: str
    priority: str = "medium"
    governorate: str
    district: Optional[str] = None
    neighborhood: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class ComplaintAssign(BaseModel):
    team_id: int
    assigned_to: Optional[int] = None


class ComplaintUpdate(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    resolution_notes: Optional[str] = None
    customer_satisfaction: Optional[int] = None


# ============== Helper Functions ==============

TEAM_TYPE_LABELS = {
    'water_maintenance': 'صيانة خطوط المياه',
    'water_distribution': 'توزيع المياه',
    'sewage': 'الصرف الصحي',
    'theft_detection': 'تتبع سرقة المياه',
}

CATEGORY_LABELS = {
    'water_leak_main': 'تسريب رئيسي',
    'water_leak_neighborhood': 'تسريب في الحي',
    'sewage_blockage': 'انسداد صرف',
    'meter_leak': 'تسريب من العداد',
    'water_outage': 'انقطاع مياه',
    'sewage_overflow': 'رفع منسوب صرف',
    'water_theft': 'شبهة سرقة مياه',
    'pump_failure': 'عطل مضخة',
    'low_pressure': 'ضغط مياه منخفض',
    'other': 'أخرى',
}

PRIORITY_LABELS = {
    'emergency': 'طارئ',
    'high': 'مرتفع',
    'medium': 'متوسط',
    'low': 'منخفض',
}

STATUS_LABELS = {
    'new': 'جديد',
    'assigned': 'معيّن',
    'in_progress': 'قيد التنفيذ',
    'resolved': 'تم الحل',
    'closed': 'مغلق',
}

CATEGORY_TEAM_MAP = {
    'water_leak_main': 'water_maintenance',
    'water_leak_neighborhood': 'water_distribution',
    'meter_leak': 'water_maintenance',
    'water_outage': 'water_distribution',
    'sewage_blockage': 'sewage',
    'sewage_overflow': 'sewage',
    'water_theft': 'theft_detection',
    'pump_failure': 'water_maintenance',
    'low_pressure': 'water_distribution',
}


def _team_dict(team: MaintenanceTeam, leader_name: str = None, member_count: int = 0) -> dict:
    return {
        "team_id": team.team_id,
        "team_name": team.team_name,
        "team_type": team.team_type,
        "team_type_label": TEAM_TYPE_LABELS.get(team.team_type, team.team_type),
        "governorate": team.governorate,
        "team_leader_id": team.team_leader_id,
        "leader_name": leader_name,
        "member_count": member_count,
        "max_active_tasks": team.max_active_tasks,
        "is_active": team.is_active,
        "created_at": team.created_at.isoformat() if team.created_at else None,
    }


def _complaint_dict(c: MaintenanceComplaint, team_name: str = None, assigned_name: str = None) -> dict:
    return {
        "complaint_id": c.complaint_id,
        "customer_name": c.customer_name,
        "customer_phone": c.customer_phone,
        "description": c.description,
        "category": c.category,
        "category_label": CATEGORY_LABELS.get(c.category, c.category),
        "priority": c.priority,
        "priority_label": PRIORITY_LABELS.get(c.priority, c.priority),
        "status": c.status,
        "status_label": STATUS_LABELS.get(c.status, c.status),
        "governorate": c.governorate,
        "district": c.district,
        "neighborhood": c.neighborhood,
        "team_id": c.team_id,
        "team_name": team_name,
        "assigned_to": c.assigned_to,
        "assigned_name": assigned_name,
        "latitude": c.latitude,
        "longitude": c.longitude,
        "photo_url": c.photo_url,
        "created_at": c.created_at.isoformat() if c.created_at else None,
        "assigned_at": c.assigned_at.isoformat() if c.assigned_at else None,
        "started_at": c.started_at.isoformat() if c.started_at else None,
        "resolved_at": c.resolved_at.isoformat() if c.resolved_at else None,
        "resolution_notes": c.resolution_notes,
        "customer_satisfaction": c.customer_satisfaction,
    }


async def _enrich_team(db: AsyncSession, team: MaintenanceTeam) -> dict:
    leader_name = None
    if team.team_leader_id:
        res = await db.execute(select(Employee.full_name).where(Employee.employee_id == team.team_leader_id))
        row = res.first()
        if row:
            leader_name = row[0]
    
    member_count_res = await db.execute(
        select(func.count(TeamMember.id)).where(TeamMember.team_id == team.team_id)
    )
    member_count = member_count_res.scalar() or 0
    
    return _team_dict(team, leader_name, member_count)


async def _enrich_complaint(db: AsyncSession, c: MaintenanceComplaint) -> dict:
    team_name = None
    assigned_name = None
    if c.team_id:
        res = await db.execute(select(MaintenanceTeam.team_name).where(MaintenanceTeam.team_id == c.team_id))
        row = res.first()
        if row:
            team_name = row[0]
    if c.assigned_to:
        res = await db.execute(select(Employee.full_name).where(Employee.employee_id == c.assigned_to))
        row = res.first()
        if row:
            assigned_name = row[0]
    return _complaint_dict(c, team_name, assigned_name)


# ============== Teams Endpoints ==============

@router.post("/teams")
async def create_team(
    body: TeamCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    team = MaintenanceTeam(
        team_name=body.team_name,
        team_type=body.team_type,
        governorate=body.governorate,
        team_leader_id=body.team_leader_id,
        max_active_tasks=body.max_active_tasks,
    )
    db.add(team)
    await db.commit()
    await db.refresh(team)
    return await _enrich_team(db, team)


@router.get("/teams")
async def list_teams(
    team_type: Optional[str] = None,
    governorate: Optional[str] = None,
    is_active: Optional[bool] = True,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = select(MaintenanceTeam).where(MaintenanceTeam.is_active == is_active)
    if team_type:
        query = query.where(MaintenanceTeam.team_type == team_type)
    if governorate:
        query = query.where(MaintenanceTeam.governorate == governorate)
    
    result = await db.execute(query.order_by(MaintenanceTeam.team_name))
    teams = result.scalars().all()
    
    items = []
    for team in teams:
        items.append(await _enrich_team(db, team))
    
    return {"items": items, "total": len(items)}


@router.get("/teams/{team_id}")
async def get_team(
    team_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(select(MaintenanceTeam).where(MaintenanceTeam.team_id == team_id))
    team = result.scalar_one_or_none()
    if not team:
        raise HTTPException(404, "Team not found")
    
    team_dict = await _enrich_team(db, team)
    
    members_res = await db.execute(
        select(TeamMember, Employee.full_name, Employee.employee_number)
        .join(Employee, TeamMember.employee_id == Employee.employee_id)
        .where(TeamMember.team_id == team_id)
    )
    members = []
    for member, name, number in members_res.all():
        members.append({
            "id": member.id,
            "employee_id": member.employee_id,
            "employee_name": name,
            "employee_number": number,
            "role": member.role,
        })
    
    team_dict["members"] = members
    return team_dict


@router.put("/teams/{team_id}")
async def update_team(
    team_id: int,
    body: TeamUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(select(MaintenanceTeam).where(MaintenanceTeam.team_id == team_id))
    team = result.scalar_one_or_none()
    if not team:
        raise HTTPException(404, "Team not found")
    
    if body.team_name is not None:
        team.team_name = body.team_name
    if body.team_type is not None:
        team.team_type = body.team_type
    if body.governorate is not None:
        team.governorate = body.governorate
    if body.team_leader_id is not None:
        team.team_leader_id = body.team_leader_id
    if body.max_active_tasks is not None:
        team.max_active_tasks = body.max_active_tasks
    if body.is_active is not None:
        team.is_active = body.is_active
    
    await db.commit()
    return await _enrich_team(db, team)


@router.post("/teams/{team_id}/members")
async def add_team_member(
    team_id: int,
    body: TeamMemberAdd,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    existing = await db.execute(
        select(TeamMember).where(
            and_(TeamMember.team_id == team_id, TeamMember.employee_id == body.employee_id)
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, "Employee already in team")
    
    member = TeamMember(
        team_id=team_id,
        employee_id=body.employee_id,
        role=body.role,
    )
    db.add(member)
    await db.commit()
    return {"message": "Member added"}


@router.delete("/teams/{team_id}/members/{member_id}")
async def remove_team_member(
    team_id: int,
    member_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(TeamMember).where(
            and_(TeamMember.team_id == team_id, TeamMember.id == member_id)
        )
    )
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(404, "Member not found")
    
    await db.delete(member)
    await db.commit()
    return {"message": "Member removed"}


# ============== Complaints Endpoints ==============

@router.post("/complaints")
async def create_complaint(
    body: ComplaintCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    complaint = MaintenanceComplaint(
        customer_name=body.customer_name,
        customer_phone=body.customer_phone,
        description=body.description,
        category=body.category,
        priority=body.priority,
        governorate=body.governorate,
        district=body.district,
        neighborhood=body.neighborhood,
        latitude=body.latitude,
        longitude=body.longitude,
        status="new",
        created_by=current_user.employee_id,
    )
    db.add(complaint)
    await db.commit()
    await db.refresh(complaint)
    
    await notify_direct_manager(db, current_user.employee_id, "شكوى صيانة جديدة", f"شكوى جديدة: {body.category}")
    
    return await _enrich_complaint(db, complaint)


@router.get("/complaints")
async def list_complaints(
    status: Optional[str] = None,
    category: Optional[str] = None,
    priority: Optional[str] = None,
    team_id: Optional[int] = None,
    governorate: Optional[str] = None,
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = select(MaintenanceComplaint).order_by(desc(MaintenanceComplaint.created_at))
    
    if status:
        query = query.where(MaintenanceComplaint.status == status)
    if category:
        query = query.where(MaintenanceComplaint.category == category)
    if priority:
        query = query.where(MaintenanceComplaint.priority == priority)
    if team_id:
        query = query.where(MaintenanceComplaint.team_id == team_id)
    if governorate:
        query = query.where(MaintenanceComplaint.governorate == governorate)
    
    query = query.limit(limit)
    result = await db.execute(query)
    complaints = result.scalars().all()
    
    items = []
    for c in complaints:
        items.append(await _enrich_complaint(db, c))
    
    return {"items": items, "total": len(items)}


@router.get("/complaints/my-team")
async def my_team_complaints(
    status: Optional[str] = None,
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    member_of = await db.execute(
        select(TeamMember.team_id).where(TeamMember.employee_id == current_user.employee_id)
    )
    team_ids = [r[0] for r in member_of.all()]
    
    query = select(MaintenanceComplaint).where(MaintenanceComplaint.team_id.in_(team_ids))
    if status:
        query = query.where(MaintenanceComplaint.status == status)
    query = query.order_by(desc(MaintenanceComplaint.created_at)).limit(limit)
    
    result = await db.execute(query)
    complaints = result.scalars().all()
    
    items = []
    for c in complaints:
        items.append(await _enrich_complaint(db, c))
    
    return {"items": items, "total": len(items)}


@router.get("/complaints/{complaint_id}")
async def get_complaint(
    complaint_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(MaintenanceComplaint).where(MaintenanceComplaint.complaint_id == complaint_id)
    )
    c = result.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Complaint not found")
    return await _enrich_complaint(db, c)


@router.post("/complaints/{complaint_id}/assign")
async def assign_complaint(
    complaint_id: int,
    body: ComplaintAssign,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(MaintenanceComplaint).where(MaintenanceComplaint.complaint_id == complaint_id)
    )
    c = result.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Complaint not found")
    
    c.team_id = body.team_id
    c.assigned_to = body.assigned_to
    c.status = "assigned"
    c.assigned_at = datetime.utcnow()
    
    await db.commit()
    
    if body.assigned_to:
        await notify_employee(db, body.assigned_to, "تكليف بــ", f"تم تكليفك بالشكوى #{complaint_id}")
    
    return await _enrich_complaint(db, c)


@router.post("/complaints/{complaint_id}/update")
async def update_complaint(
    complaint_id: int,
    body: ComplaintUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(MaintenanceComplaint).where(MaintenanceComplaint.complaint_id == complaint_id)
    )
    c = result.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Complaint not found")
    
    if body.status is not None:
        c.status = body.status
        if body.status == "in_progress":
            c.started_at = datetime.utcnow()
        elif body.status in ("resolved", "closed"):
            c.resolved_at = datetime.utcnow()
    if body.priority is not None:
        c.priority = body.priority
    if body.resolution_notes is not None:
        c.resolution_notes = body.resolution_notes
    if body.customer_satisfaction is not None:
        c.customer_satisfaction = body.customer_satisfaction
    
    await db.commit()
    return await _enrich_complaint(db, c)


@router.get("/stats")
async def maintenance_stats(
    governorate: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = select(MaintenanceComplaint)
    if governorate:
        query = query.where(MaintenanceComplaint.governorate == governorate)
    
    result = await db.execute(query)
    complaints = result.scalars().all()
    
    total = len(complaints)
    by_status = {}
    by_priority = {}
    by_category = {}
    by_team = {}
    
    for c in complaints:
        by_status[c.status] = by_status.get(c.status, 0) + 1
        by_priority[c.priority] = by_priority.get(c.priority, 0) + 1
        by_category[c.category] = by_category.get(c.category, 0) + 1
        if c.team_id:
            by_team[c.team_id] = by_team.get(c.team_id, 0) + 1
    
    team_names = {}
    for tid in by_team.keys():
        res = await db.execute(select(MaintenanceTeam.team_name).where(MaintenanceTeam.team_id == tid))
        row = res.first()
        if row:
            team_names[tid] = row[0]
    
    return {
        "total": total,
        "by_status": {STATUS_LABELS.get(k, k): v for k, v in by_status.items()},
        "by_priority": {PRIORITY_LABELS.get(k, k): v for k, v in by_priority.items()},
        "by_category": {CATEGORY_LABELS.get(k, k): v for k, v in by_category.items()},
        "by_team": {team_names.get(k, f"فريق #{k}"): v for k, v in by_team.items()},
    }

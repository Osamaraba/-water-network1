from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, and_
from datetime import datetime, date, time as t_time, timedelta
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.models.maintenance import PeriodicMaintenanceTask, PeriodicTaskCompletion, MaintenanceTeam, TeamMember
from app.middleware.auth import get_current_user
from app.models.organization import Employee
from app.services.notifications import notify_employee

router = APIRouter(prefix="/periodic-maintenance", tags=["periodic-maintenance"])


class TaskCreate(BaseModel):
    team_id: int
    task_name: str
    description: Optional[str] = None
    frequency: str
    day_of_week: Optional[int] = None
    day_of_month: Optional[int] = None
    time_of_day: str = "08:00"


class TaskUpdate(BaseModel):
    task_name: Optional[str] = None
    description: Optional[str] = None
    frequency: Optional[str] = None
    day_of_week: Optional[int] = None
    day_of_month: Optional[int] = None
    time_of_day: Optional[str] = None
    is_active: Optional[bool] = None


class TaskComplete(BaseModel):
    notes: Optional[str] = None


FREQUENCY_LABELS = {
    'daily': 'يومي',
    'weekly': 'أسبوعي',
    'biweekly': 'كل أسبوعين',
    'monthly': 'شهري',
    'quarterly': 'كل 3 أشهر',
}

DAY_NAMES = {
    0: 'الاثنين',
    1: 'الثلاثاء',
    2: 'الأربعاء',
    3: 'الخميس',
    4: 'الجمعة',
    5: 'السبت',
    6: 'الأحد',
}


def _task_dict(task: PeriodicMaintenanceTask, team_name: str = None) -> dict:
    hour, minute = task.time_of_day.hour, task.time_of_day.minute
    return {
        "task_id": task.task_id,
        "team_id": task.team_id,
        "team_name": team_name,
        "task_name": task.task_name,
        "description": task.description,
        "frequency": task.frequency,
        "frequency_label": FREQUENCY_LABELS.get(task.frequency, task.frequency),
        "day_of_week": task.day_of_week,
        "day_of_week_label": DAY_NAMES.get(task.day_of_week) if task.day_of_week is not None else None,
        "day_of_month": task.day_of_month,
        "time_of_day": f"{hour:02d}:{minute:02d}",
        "is_active": task.is_active,
        "last_completed": task.last_completed.isoformat() if task.last_completed else None,
        "next_due": task.next_due.isoformat() if task.next_due else None,
        "created_at": task.created_at.isoformat() if task.created_at else None,
    }


def _completion_dict(c: PeriodicTaskCompletion, task_name: str = None, employee_name: str = None) -> dict:
    return {
        "completion_id": c.completion_id,
        "task_id": c.task_id,
        "task_name": task_name,
        "employee_id": c.employee_id,
        "employee_name": employee_name,
        "completed_date": c.completed_date.isoformat(),
        "notes": c.notes,
        "photo_url": c.photo_url,
        "created_at": c.created_at.isoformat() if c.created_at else None,
    }


def _calculate_next_due(frequency: str, last_completed: date = None, day_of_week: int = None, day_of_month: int = None) -> date:
    today = date.today()
    
    if frequency == 'daily':
        return today + timedelta(days=1)
    elif frequency == 'weekly':
        if day_of_week is not None:
            days_ahead = day_of_week - today.weekday()
            if days_ahead <= 0:
                days_ahead += 7
            return today + timedelta(days=days_ahead)
        return today + timedelta(weeks=1)
    elif frequency == 'biweekly':
        return today + timedelta(weeks=2)
    elif frequency == 'monthly':
        if day_of_month is not None:
            next_month = today.month + 1
            next_year = today.year
            if next_month > 12:
                next_month = 1
                next_year += 1
            try:
                return date(next_year, next_month, min(day_of_month, 28))
            except:
                return date(next_year, next_month, 28)
        return today + timedelta(days=30)
    elif frequency == 'quarterly':
        return today + timedelta(days=90)
    
    return today + timedelta(days=7)


async def _enrich_task(db: AsyncSession, task: PeriodicMaintenanceTask) -> dict:
    team_name = None
    if task.team_id:
        res = await db.execute(select(MaintenanceTeam.team_name).where(MaintenanceTeam.team_id == task.team_id))
        row = res.first()
        if row:
            team_name = row[0]
    return _task_dict(task, team_name)


async def _enrich_completion(db: AsyncSession, c: PeriodicTaskCompletion) -> dict:
    task_name = None
    employee_name = None
    if c.task_id:
        res = await db.execute(select(PeriodicMaintenanceTask.task_name).where(PeriodicMaintenanceTask.task_id == c.task_id))
        row = res.first()
        if row:
            task_name = row[0]
    if c.employee_id:
        res = await db.execute(select(Employee.full_name).where(Employee.employee_id == c.employee_id))
        row = res.first()
        if row:
            employee_name = row[0]
    return _completion_dict(c, task_name, employee_name)


@router.post("/tasks")
async def create_task(
    body: TaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    parts = body.time_of_day.split(":")
    t = t_time(int(parts[0]), int(parts[1]))
    
    task = PeriodicMaintenanceTask(
        team_id=body.team_id,
        task_name=body.task_name,
        description=body.description,
        frequency=body.frequency,
        day_of_week=body.day_of_week,
        day_of_month=body.day_of_month,
        time_of_day=t,
        next_due=_calculate_next_due(body.frequency, day_of_week=body.day_of_week, day_of_month=body.day_of_month),
    )
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return await _enrich_task(db, task)


@router.get("/tasks")
async def list_tasks(
    team_id: Optional[int] = None,
    is_active: Optional[bool] = True,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = select(PeriodicMaintenanceTask).where(PeriodicMaintenanceTask.is_active == is_active)
    if team_id:
        query = query.where(PeriodicMaintenanceTask.team_id == team_id)
    query = query.order_by(PeriodicMaintenanceTask.next_due)
    
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    items = []
    for task in tasks:
        items.append(await _enrich_task(db, task))
    
    return {"items": items, "total": len(items)}


@router.get("/tasks/my-team")
async def my_team_tasks(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    member_of = await db.execute(
        select(TeamMember.team_id).where(TeamMember.employee_id == current_user.employee_id)
    )
    team_ids = [r[0] for r in member_of.all()]
    
    query = select(PeriodicMaintenanceTask).where(
        and_(
            PeriodicMaintenanceTask.team_id.in_(team_ids),
            PeriodicMaintenanceTask.is_active == True
        )
    ).order_by(PeriodicMaintenanceTask.next_due)
    
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    items = []
    for task in tasks:
        items.append(await _enrich_task(db, task))
    
    return {"items": items, "total": len(items)}


@router.get("/tasks/upcoming")
async def upcoming_tasks(
    days: int = Query(default=7, le=30),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    today = date.today()
    deadline = today + timedelta(days=days)
    
    query = select(PeriodicMaintenanceTask).where(
        and_(
            PeriodicMaintenanceTask.is_active == True,
            PeriodicMaintenanceTask.next_due <= deadline
        )
    ).order_by(PeriodicMaintenanceTask.next_due)
    
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    items = []
    for task in tasks:
        items.append(await _enrich_task(db, task))
    
    return {"items": items, "total": len(items)}


@router.get("/tasks/{task_id}")
async def get_task(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(PeriodicMaintenanceTask).where(PeriodicMaintenanceTask.task_id == task_id)
    )
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(404, "Task not found")
    return await _enrich_task(db, task)


@router.put("/tasks/{task_id}")
async def update_task(
    task_id: int,
    body: TaskUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(PeriodicMaintenanceTask).where(PeriodicMaintenanceTask.task_id == task_id)
    )
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(404, "Task not found")
    
    if body.task_name is not None:
        task.task_name = body.task_name
    if body.description is not None:
        task.description = body.description
    if body.frequency is not None:
        task.frequency = body.frequency
        task.next_due = _calculate_next_due(body.frequency, task.last_completed, task.day_of_week, task.day_of_month)
    if body.day_of_week is not None:
        task.day_of_week = body.day_of_week
    if body.day_of_month is not None:
        task.day_of_month = body.day_of_month
    if body.time_of_day is not None:
        parts = body.time_of_day.split(":")
        task.time_of_day = t_time(int(parts[0]), int(parts[1]))
    if body.is_active is not None:
        task.is_active = body.is_active
    
    await db.commit()
    return await _enrich_task(db, task)


@router.post("/tasks/{task_id}/complete")
async def complete_task(
    task_id: int,
    body: TaskComplete,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    result = await db.execute(
        select(PeriodicMaintenanceTask).where(PeriodicMaintenanceTask.task_id == task_id)
    )
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(404, "Task not found")
    
    completion = PeriodicTaskCompletion(
        task_id=task_id,
        employee_id=current_user.employee_id,
        completed_date=date.today(),
        notes=body.notes,
    )
    db.add(completion)
    
    task.last_completed = date.today()
    task.next_due = _calculate_next_due(task.frequency, date.today(), task.day_of_week, task.day_of_month)
    
    await db.commit()
    return await _enrich_completion(db, completion)


@router.get("/tasks/{task_id}/completions")
async def task_completions(
    task_id: int,
    limit: int = Query(default=20, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    query = (
        select(PeriodicTaskCompletion)
        .where(PeriodicTaskCompletion.task_id == task_id)
        .order_by(desc(PeriodicTaskCompletion.completed_date))
        .limit(limit)
    )
    result = await db.execute(query)
    completions = result.scalars().all()
    
    items = []
    for c in completions:
        items.append(await _enrich_completion(db, c))
    
    return {"items": items, "total": len(items)}

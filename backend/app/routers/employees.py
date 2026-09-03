from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.database import get_db
from app.models.organization import Employee, OrganizationUnit, WorkType
from app.models.auth import User, Role, UserRole
from app.middleware.auth import get_current_user
from typing import List, Dict, Any

router = APIRouter(prefix="/employees", tags=["employees"])


async def _serialize_emp(emp, db):
    org_name = None
    if emp.org_unit_id:
        org_res = await db.execute(select(OrganizationUnit).where(OrganizationUnit.org_unit_id == emp.org_unit_id))
        org = org_res.scalar_one_or_none()
        org_name = org.unit_name if org else None

    wt_name = None
    if emp.work_type_id:
        wt_res = await db.execute(select(WorkType).where(WorkType.work_type_id == emp.work_type_id))
        wt = wt_res.scalar_one_or_none()
        wt_name = wt.type_name_ar if wt else None

    role_id = None
    role_name = None
    role_names = []
    user_res = await db.execute(select(User).where(User.employee_id == emp.employee_id))
    user = user_res.scalar_one_or_none()
    if user:
        ur_res = await db.execute(select(UserRole).where(UserRole.user_id == user.user_id))
        urs = ur_res.scalars().all()
        for ur in urs:
            r_res = await db.execute(select(Role).where(Role.role_id == ur.role_id))
            r = r_res.scalar_one_or_none()
            if r:
                role_names.append(r.role_name)
                if role_id is None:
                    role_id = r.role_id
                    role_name = r.role_label

    manager_name = None
    if emp.direct_manager_id:
        mgr_res = await db.execute(select(Employee).where(Employee.employee_id == emp.direct_manager_id))
        mgr = mgr_res.scalar_one_or_none()
        manager_name = mgr.full_name if mgr else None

    return {
        "employee_id": emp.employee_id,
        "employee_number": emp.employee_number,
        "full_name": emp.full_name,
        "full_name_en": emp.full_name_en,
        "job_title": emp.job_title,
        "phone": emp.phone,
        "email": emp.email,
        "org_unit_id": emp.org_unit_id,
        "org_unit_name": org_name,
        "work_type_id": emp.work_type_id,
        "work_type_name": wt_name,
        "direct_manager_id": emp.direct_manager_id,
        "direct_manager_name": manager_name,
        "role_id": role_id,
        "role_name": role_name,
        "roles": role_names,
        "hire_date": emp.hire_date.isoformat() if emp.hire_date else None,
        "is_active": emp.is_active,
        "allow_field_tracking": emp.allow_field_tracking,
    }


@router.get("/all")
async def get_all_employees(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get all employees with role, org unit name, work type name."""
    result = await db.execute(select(Employee).order_by(Employee.employee_id))
    employees = result.scalars().all()
    items = [await _serialize_emp(emp, db) for emp in employees]
    return {"items": items}


@router.get("/me", response_model=Dict[str, Any])
async def get_my_profile(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
) -> Dict[str, Any]:
    """Get current user's profile."""
    result = await db.execute(
        select(Employee).where(Employee.employee_id == current_user.employee_id)
    )
    emp = result.scalar_one_or_none()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    return await _serialize_emp(emp, db)


@router.get("/roles")
async def get_roles(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get all roles."""
    result = await db.execute(select(Role).order_by(Role.role_id))
    roles = result.scalars().all()
    return {
        "items": [
            {"role_id": r.role_id, "role_name": r.role_name, "role_label": r.role_label or r.role_name} for r in roles
        ]
    }


@router.get("/work-types")
async def get_work_types(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get all work types."""
    result = await db.execute(select(WorkType).order_by(WorkType.work_type_id))
    types = result.scalars().all()
    return {
        "items": [
            {"work_type_id": t.work_type_id, "type_name": t.type_name, "type_name_ar": t.type_name_ar, "is_field": t.is_field} for t in types
        ]
    }


@router.get("/{employee_id}", response_model=Dict[str, Any])
async def get_employee_by_id(
    employee_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
) -> Dict[str, Any]:
    """Get employee by ID."""
    result = await db.execute(
        select(Employee).where(Employee.employee_id == employee_id)
    )
    emp = result.scalar_one_or_none()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    return await _serialize_emp(emp, db)


@router.get("/")
async def list_employees_root():
    """Redirect to /employees/all."""
    return {"message": "Use /employees/all to get all employees"}

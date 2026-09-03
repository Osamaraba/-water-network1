from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from app.database import get_db
from app.models import OrganizationUnit, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/organization", tags=["organization"])


@router.get("/")
async def list_org_units(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List all organization units - requires authentication."""
    result = await db.execute(select(OrganizationUnit))
    units = result.scalars().all()
    return [
        {
            "org_unit_id": u.org_unit_id,
            "parent_id": u.parent_id,
            "unit_name": u.unit_name,
            "unit_code": u.unit_code,
            "unit_type": u.unit_type,
            "is_active": u.is_active,
        }
        for u in units
    ]


@router.get("/units")
async def get_org_units(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get organization units (compatibility endpoint)."""
    result = await db.execute(select(OrganizationUnit).limit(200))
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


@router.get("/tree")
async def get_org_tree(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get organization tree (compatibility endpoint)."""
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


@router.get("/{org_unit_id}")
async def get_org_unit(
    org_unit_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get organization unit by ID - requires authentication."""
    result = await db.execute(
        select(OrganizationUnit).where(OrganizationUnit.org_unit_id == org_unit_id)
    )
    u = result.scalar_one_or_none()
    if not u:
        raise HTTPException(status_code=404, detail="Organization unit not found")
    return {
        "org_unit_id": u.org_unit_id,
        "parent_id": u.parent_id,
        "unit_name": u.unit_name,
        "unit_code": u.unit_code,
        "unit_type": u.unit_type,
        "is_active": u.is_active,
    }

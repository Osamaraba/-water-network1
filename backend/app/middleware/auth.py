from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.auth import User, UserRole, Role, RolePermission, Permission
from app.models.organization import Employee
from app.utils.security import decode_token
from app.services.notifications import (
    can_approve_for,
    is_hr_manager,
    is_any_manager,
    get_user_role_names,
)

security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> Employee:
    if not credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    payload = decode_token(credentials.credentials)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

    res = await db.execute(select(User).where(User.user_id == int(user_id)))
    user = res.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    emp_res = await db.execute(select(Employee).where(Employee.employee_id == user.employee_id))
    employee = emp_res.scalar_one_or_none()
    if not employee or not employee.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Employee not found or inactive")

    return employee


async def get_user_roles(employee: Employee = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await get_user_role_names(db, employee.employee_id)


async def get_user_permissions(employee: Employee = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    user_res = await db.execute(select(User).where(User.employee_id == employee.employee_id))
    user = user_res.scalar_one_or_none()
    if not user:
        return []

    perm_res = await db.execute(
        select(Permission.permission_code, RolePermission.scope_level)
        .join(RolePermission, RolePermission.permission_id == Permission.permission_id)
        .join(UserRole, UserRole.role_id == RolePermission.role_id)
        .where(UserRole.user_id == user.user_id)
    )
    return perm_res.all()


class RequirePermission:
    def __init__(self, permission_code: str):
        self.permission_code = permission_code

    async def __call__(
        self,
        employee: Employee = Depends(get_current_user),
        user_permissions=Depends(get_user_permissions),
    ):
        for code, scope in user_permissions:
            if code == self.permission_code:
                return employee
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Permission denied: {self.permission_code}")


class RequireManager:
    """Allow any employee with a manager role (HR or operational supervisor)."""
    MANAGER_ROLES = {
        "general_manager",
        "hr_manager",
        "field_supervisor",
        "office_supervisor",
    }

    async def __call__(
        self,
        employee: Employee = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        if await is_any_manager(db, employee.employee_id):
            return employee
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager access required")


class RequireHRManager:
    """Only HR-level managers (general_manager, hr_manager)."""
    HR_ROLES = {"general_manager", "hr_manager"}

    async def __call__(
        self,
        employee: Employee = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        if await is_hr_manager(db, employee.employee_id):
            return employee
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="HR manager access required")


class RequireApprover:
    """Allows HR managers and direct managers to approve.
    Used for routes like approve leave/short-leave/overtime.
    """

    async def can_approve(
        self, approver_id: int, target_employee_id: int, db: AsyncSession
    ) -> bool:
        return await can_approve_for(db, approver_id, target_employee_id)

    async def __call__(
        self,
        employee: Employee = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        # Return self; the actual check happens in the route using can_approve_for()
        return employee


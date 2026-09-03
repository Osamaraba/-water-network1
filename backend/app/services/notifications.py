from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional

from app.models.notification import Notification
from app.realtime.connection_manager import manager
from app.models.auth import Role, UserRole, User
from app.models.organization import Employee


# Role categorization
HR_ROLES = ["general_manager", "hr_manager"]
MANAGER_ROLES = HR_ROLES + ["field_supervisor", "office_supervisor"]


async def notify_employee(
    db: AsyncSession,
    employee_id: int,
    title: str,
    message: str,
    severity: str = "info",
) -> Notification:
    """Send notification to a specific employee."""
    notification = Notification(
        employee_id=employee_id,
        title=title,
        message=message,
        severity=severity,
    )
    db.add(notification)
    await db.commit()
    await db.refresh(notification)

    await manager.send_to_employee(
        employee_id,
        {
            "notification_id": notification.notification_id,
            "title": notification.title,
            "message": notification.message,
            "severity": notification.severity,
            "created_at": str(notification.created_at),
        },
    )

    return notification


async def _employees_with_role(db: AsyncSession, role_names: list) -> list:
    """Return list of employee_ids that have at least one of the given roles."""
    result = await db.execute(
        select(Employee.employee_id)
        .join(User, User.employee_id == Employee.employee_id)
        .join(UserRole, UserRole.user_id == User.user_id)
        .join(Role, Role.role_id == UserRole.role_id)
        .where(Role.role_name.in_(role_names), Employee.is_active == True)  # noqa: E712
        .distinct()
    )
    return [row[0] for row in result.all()]


async def notify_direct_manager(
    db: AsyncSession,
    employee_id: int,
    title: str,
    message: str,
    severity: str = "info",
    fallback_to_hr: bool = True,
):
    """Notify the direct manager of an employee. Falls back to HR if no manager or fallback enabled."""
    emp_res = await db.execute(
        select(Employee).where(Employee.employee_id == employee_id)
    )
    emp = emp_res.scalar_one_or_none()
    if not emp:
        return

    notified = False
    if emp.direct_manager_id and emp.direct_manager_id != emp.employee_id:
        # Send to direct manager
        await notify_employee(db, emp.direct_manager_id, title, message, severity)
        notified = True

    if (not notified or fallback_to_hr) and fallback_to_hr:
        # Always CC HR managers
        hr_ids = await _employees_with_role(db, HR_ROLES)
        for hr_id in hr_ids:
            if hr_id == employee_id:
                continue
            if hr_id == emp.direct_manager_id:
                # Skip if direct manager is also HR (already notified)
                continue
            await notify_employee(db, hr_id, f"[HR] {title}", message, severity)


async def notify_hr_managers(
    db: AsyncSession,
    title: str,
    message: str,
    severity: str = "info",
    exclude_employee_id: Optional[int] = None,
):
    """Notify only HR managers (general_manager, hr_manager)."""
    hr_ids = await _employees_with_role(db, HR_ROLES)
    for eid in hr_ids:
        if eid == exclude_employee_id:
            continue
        await notify_employee(db, eid, title, message, severity)


async def notify_managers(
    db: AsyncSession,
    title: str,
    message: str,
    severity: str = "info",
    exclude_employee_id: Optional[int] = None,
):
    """Legacy function - notify all manager roles."""
    mgr_ids = await _employees_with_role(db, MANAGER_ROLES)
    for eid in mgr_ids:
        if eid == exclude_employee_id:
            continue
        await notify_employee(db, eid, title, message, severity)


async def get_user_role_names(db: AsyncSession, employee_id: int) -> list:
    """Return all role names for an employee."""
    res = await db.execute(
        select(Role.role_name)
        .join(UserRole, UserRole.role_id == Role.role_id)
        .join(User, User.user_id == UserRole.user_id)
        .where(User.employee_id == employee_id)
    )
    return [r[0] for r in res.all()]


async def is_hr_manager(db: AsyncSession, employee_id: int) -> bool:
    """Check if employee has HR-level role."""
    roles = await get_user_role_names(db, employee_id)
    return any(r in HR_ROLES for r in roles)


async def is_any_manager(db: AsyncSession, employee_id: int) -> bool:
    """Check if employee has any manager role."""
    roles = await get_user_role_names(db, employee_id)
    return any(r in MANAGER_ROLES for r in roles)


async def can_approve_for(
    db: AsyncSession, approver_id: int, target_employee_id: int
) -> bool:
    """Check if approver can approve requests for the target employee.
    Rules:
    - HR managers (general_manager, hr_manager) can approve for everyone
    - Direct manager can approve for their direct reports
    - Other supervisors cannot approve
    """
    if approver_id == target_employee_id:
        return False

    if await is_hr_manager(db, approver_id):
        return True

    target_res = await db.execute(
        select(Employee).where(Employee.employee_id == target_employee_id)
    )
    target = target_res.scalar_one_or_none()
    if not target:
        return False

    # Direct manager can approve for their report
    if target.direct_manager_id == approver_id:
        return True

    return False

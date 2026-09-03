"""Add a field supervisor account for testing role-based approval."""
import asyncio
from sqlalchemy import select
from app.database import AsyncSessionLocal
from app.models.auth import User, UserRole, Role
from app.models.organization import Employee
from app.utils.security import hash_password


async def add_field_supervisor():
    async with AsyncSessionLocal() as db:
        # Find or create a field supervisor employee (EMP003 is field engineer)
        emp = (await db.execute(
            select(Employee).where(Employee.employee_number == "EMP003")
        )).scalars().first()
        if not emp:
            print("EMP003 not found")
            return

        # Ensure user exists for EMP003
        user = (await db.execute(
            select(User).where(User.username == "EMP003")
        )).scalars().first()
        if not user:
            user = User(
                employee_id=emp.employee_id,
                username="EMP003",
                password_hash=hash_password("Yarmouk@2025"),
                is_active=True,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            print(f"Created user for {emp.employee_number}")

        # Find field_supervisor role
        role = (await db.execute(
            select(Role).where(Role.role_name == "field_supervisor")
        )).scalars().first()
        if not role:
            print("field_supervisor role not found")
            return

        # Check if already has it
        has_role = (await db.execute(
            select(UserRole).where(
                UserRole.user_id == user.user_id,
                UserRole.role_id == role.role_id,
            )
        )).scalars().first()
        if not has_role:
            db.add(UserRole(user_id=user.user_id, role_id=role.role_id))
            await db.commit()
            print(f"Added field_supervisor role to {emp.employee_number}")
        else:
            print(f"{emp.employee_number} already has field_supervisor role")

        print(f"Done. EMP003 password: Yarmouk@2025")


asyncio.run(add_field_supervisor())

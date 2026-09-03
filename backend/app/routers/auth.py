from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import User, Employee
from app.models.auth import Role, UserRole, RolePermission, Permission
from app.utils.security import verify_password, create_access_token, create_refresh_token, decode_token
from app.config import settings
from app.middleware.auth import get_current_user
from datetime import timedelta

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=dict)
async def login(
    payload: dict = Body(...),
    db: AsyncSession = Depends(get_db)
):
    """Employee login with JWT token generation - PRODUCTION VERSION."""
    employee_number = payload.get("employee_number")
    password = payload.get("password")
    
    if not employee_number or not password:
        raise HTTPException(
            status_code=400,
            detail="employee_number and password are required",
        )
    
    # Query users table by username
    result = await db.execute(select(User).where(User.username == employee_number))
    user = result.scalar_one_or_none()
    
    if not user or not user.is_active:
        raise HTTPException(
            status_code=401,
            detail="Invalid employee number or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password using proper bcrypt verification
    if not verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid employee number or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get employee info
    emp_result = await db.execute(
        select(Employee).where(Employee.employee_id == user.employee_id)
    )
    emp = emp_result.scalar_one_or_none()
    
    if not emp or not emp.is_active:
        raise HTTPException(status_code=401, detail="Employee account is inactive")
    
    # Generate access token + refresh token
    token_data = {
        "sub": str(user.user_id),
        "employee_id": user.employee_id,
        "employee_number": user.username,
    }
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user_id": user.user_id,
        "employee_id": user.employee_id,
        "username": user.username,
        "full_name": emp.full_name,
        "expires_in_minutes": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES,
    }


@router.post("/refresh", response_model=dict)
async def refresh_token(
    payload: dict = Body(...),
    db: AsyncSession = Depends(get_db)
):
    """Refresh access token using a valid refresh token."""
    refresh_token_str = payload.get("refresh_token")
    
    if not refresh_token_str:
        raise HTTPException(status_code=400, detail="refresh_token is required")
    
    payload_data = decode_token(refresh_token_str)
    if not payload_data or payload_data.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    
    user_id = payload_data.get("sub")
    user_res = await db.execute(select(User).where(User.user_id == int(user_id)))
    user = user_res.scalar_one_or_none()
    
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    
    # Generate new access token
    new_token_data = {
        "sub": str(user.user_id),
        "employee_id": user.employee_id,
        "employee_number": user.username,
    }
    new_access_token = create_access_token(new_token_data)
    
    return {
        "access_token": new_access_token,
        "token_type": "bearer",
        "expires_in_minutes": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES,
    }


@router.post("/logout", response_model=dict)
async def logout():
    """Logout endpoint - client should discard the token."""
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=dict)
async def get_me(
    db: AsyncSession = Depends(get_db),
    employee: Employee = Depends(get_current_user)
):
    """Get current user info - requires authentication."""
    # Get user_id from users table
    user_res = await db.execute(
        select(User).where(User.employee_id == employee.employee_id)
    )
    user = user_res.scalar_one_or_none()
    
    # Get user roles
    roles_res = await db.execute(
        select(Role.role_name)
        .join(UserRole, UserRole.role_id == Role.role_id)
        .join(User, User.user_id == UserRole.user_id)
        .where(User.employee_id == employee.employee_id)
    )
    roles = [r[0] for r in roles_res.all()]
    
    # Get user permissions
    perms_res = await db.execute(
        select(Permission.permission_code)
        .join(RolePermission, RolePermission.permission_id == Permission.permission_id)
        .join(Role, Role.role_id == RolePermission.role_id)
        .join(UserRole, UserRole.role_id == Role.role_id)
        .join(User, User.user_id == UserRole.user_id)
        .where(User.employee_id == employee.employee_id)
    )
    permissions = [p[0] for p in perms_res.all()]
    
    return {
        "user_id": user.user_id if user else None,
        "employee_id": employee.employee_id,
        "username": user.username if user else employee.employee_number,
        "full_name": employee.full_name,
        "employee_number": employee.employee_number,
        "is_active": employee.is_active,
        "roles": roles,
        "permissions": permissions,
    }

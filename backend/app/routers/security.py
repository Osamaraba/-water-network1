"""
Session Management API - Security Enhancement
Yarmouk Water Management Pro

Provides endpoints for:
- Listing active sessions
- Revoking specific sessions
- Password change
- Device management
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.models import User, Employee
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/security", tags=["security"])


# =============================================================================
# Request/Response Models
# =============================================================================

class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str


class AdminResetPasswordRequest(BaseModel):
    employee_id: int
    new_password: str


# =============================================================================
# Password Management
# =============================================================================

@router.post("/change-password")
async def change_password(
    request: PasswordChangeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Change current user's password."""
    from passlib.hash import bcrypt
    
    # Get user record
    result = await db.execute(
        select(User).where(User.employee_id == current_user.employee_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify current password
    if not bcrypt.verify(request.current_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    # Validate new password strength
    if len(request.new_password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
    
    if request.new_password == request.current_password:
        raise HTTPException(status_code=400, detail="New password must be different")
    
    # Hash and update
    new_hash = bcrypt.hash(request.new_password)
    user.password_hash = new_hash
    user.updated_at = datetime.utcnow()
    
    await db.commit()
    
    return {"message": "Password changed successfully"}


@router.post("/admin/reset-password")
async def admin_reset_password(
    request: AdminResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Admin (General Manager only) can reset any employee's password."""
    from passlib.hash import bcrypt
    from app.services.notifications import get_user_role_names

    # Check if current user is General Manager
    roles = await get_user_role_names(db, current_user.employee_id)
    if "general_manager" not in roles:
        raise HTTPException(status_code=403, detail="فقط المدير العام يمكنه إعادة تعيين كلمة المرور")

    # Validate new password
    if len(request.new_password) < 8:
        raise HTTPException(status_code=400, detail="كلمة المرور يجب أن تكون 8 أحرف على الأقل")

    # Find the target user
    result = await db.execute(
        select(User).where(User.employee_id == request.employee_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")

    if not user.is_active:
        raise HTTPException(status_code=400, detail="حساب المستخدم معطّل")

    # Hash and update password
    new_hash = bcrypt.hash(request.new_password)
    user.password_hash = new_hash
    user.failed_login_attempts = 0
    user.locked_until = None
    user.updated_at = datetime.utcnow()

    await db.commit()

    # Get employee name for response
    emp_result = await db.execute(
        select(Employee).where(Employee.employee_id == request.employee_id)
    )
    emp = emp_result.scalar_one_or_none()
    emp_name = emp.full_name if emp else str(request.employee_id)

    return {
        "message": f"تم إعادة تعيين كلمة المرور للموظف {emp_name} بنجاح",
        "employee_id": request.employee_id,
        "employee_name": emp_name,
    }


# =============================================================================
# Session Management
# =============================================================================

@router.get("/sessions")
async def list_sessions(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """List all active sessions for the current user."""
    result = await db.execute(
        select(User).where(User.employee_id == current_user.employee_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "sessions": [
            {
                "user_id": user.user_id,
                "device_uuid": user.device_uuid,
                "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
                "is_active": user.is_active,
            }
        ]
    }


@router.post("/revoke-all-sessions")
async def revoke_all_sessions(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Revoke all sessions for the current user (except current)."""
    result = await db.execute(
        select(User).where(User.employee_id == current_user.employee_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Clear refresh token to invalidate other sessions
    user.refresh_token = None
    user.updated_at = datetime.utcnow()
    
    await db.commit()
    
    return {"message": "All other sessions have been revoked"}


# =============================================================================
# Account Security
# =============================================================================

@router.get("/security-status")
async def security_status(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Get security status for the current user."""
    result = await db.execute(
        select(User).where(User.employee_id == current_user.employee_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "is_active": user.is_active,
        "failed_login_attempts": user.failed_login_attempts,
        "is_locked": user.locked_until is not None and user.locked_until > datetime.utcnow(),
        "locked_until": user.locked_until.isoformat() if user.locked_until else None,
        "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
        "has_device_uuid": user.device_uuid is not None,
    }


@router.post("/logout")
async def logout(
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user),
):
    """Logout current user and invalidate tokens."""
    result = await db.execute(
        select(User).where(User.employee_id == current_user.employee_id)
    )
    user = result.scalar_one_or_none()
    
    if user:
        user.refresh_token = None
        user.updated_at = datetime.utcnow()
        await db.commit()
    
    return {"message": "Logged out successfully"}

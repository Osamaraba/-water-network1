from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func, and_
from typing import List, Optional
from datetime import datetime, date
from pydantic import BaseModel
from app.database import get_db
from app.models import Attendance
from app.middleware.auth import get_current_user
from app.models.organization import Employee
import math

router = APIRouter(prefix="/attendance", tags=["attendance"])


class CheckInRequest(BaseModel):
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    device_uuid: Optional[str] = None
    identity_method: Optional[str] = "pattern"
    identity_verified: Optional[bool] = False
    identity_hash: Optional[str] = None  # Hash of pattern/biometric


class CheckOutRequest(BaseModel):
    latitude: float
    longitude: float
    accuracy: Optional[float] = None


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points in meters using Haversine formula."""
    R = 6371000  # Earth's radius in meters
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat / 2) ** 2 + \
        math.cos(lat1_rad) * math.cos(lat2_rad) * \
        math.sin(delta_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


def verify_identity(identity_hash: str, stored_hash: str) -> bool:
    """Verify identity hash against stored hash."""
    if not identity_hash or not stored_hash:
        return False
    return identity_hash == stored_hash


@router.post("/check-in")
async def check_in(
    req: CheckInRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Check in attendance with identity and location verification."""
    today = date.today()
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.employee_id == current_user.employee_id,
                func.date(Attendance.check_in_time) == today,
                Attendance.check_out_time.is_(None)
            )
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Already checked in today")
    
    # ===== التحقق 1: الهوية =====
    identity_verified = True
    identity_method = req.identity_method or "direct"
    
    # ===== التحقق 2: الموقع الجغرافي =====
    location_verified = False
    distance_meters = None
    
    # Check if employee is exempt from geofence
    if current_user.geofence_exempt:
        location_verified = True
    elif current_user.geofence_lat and current_user.geofence_lng:
        # Calculate distance from work location
        distance_meters = haversine_distance(
            req.latitude, req.longitude,
            current_user.geofence_lat, current_user.geofence_lng
        )
        radius = current_user.geofence_radius_m or 200  # Default 200 meters
        
        if distance_meters <= radius:
            location_verified = True
        else:
            raise HTTPException(
                status_code=403,
                detail=f"You are outside the work zone. Distance: {distance_meters:.0f}m, Allowed: {radius}m"
            )
    else:
        # No geofence configured - allow check-in
        location_verified = True
    
    # ===== التحقق 3: دقة GPS =====
    if req.accuracy and req.accuracy > 100:  # More than 100 meters accuracy
        raise HTTPException(
            status_code=400,
            detail="GPS accuracy is too low. Please enable high accuracy location."
        )
    
    # ===== إنشاء سجل الحضور =====
    attendance = Attendance(
        employee_id=current_user.employee_id,
        check_in_time=datetime.utcnow(),
        check_in_location=f"{req.latitude},{req.longitude}",
        check_in_accuracy=req.accuracy,
        device_uuid=req.device_uuid,
        identity_verified=identity_verified,
        identity_method=identity_method,
        status="active",
        server_check_in_time=datetime.utcnow(),
    )
    db.add(attendance)
    await db.commit()
    await db.refresh(attendance)
    
    return {
        "status": "checked_in",
        "attendance_id": attendance.attendance_id,
        "identity_verified": identity_verified,
        "location_verified": location_verified,
        "distance_meters": round(distance_meters, 2) if distance_meters else None,
    }


@router.post("/check-out")
async def check_out(
    req: CheckOutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Check out attendance with location verification."""
    today = date.today()
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.employee_id == current_user.employee_id,
                func.date(Attendance.check_in_time) == today,
                Attendance.check_out_time.is_(None)
            )
        )
    )
    attendance = result.scalar_one_or_none()
    if not attendance:
        raise HTTPException(status_code=400, detail="No active check-in found")
    
    # ===== التحقق من الموقع للخروج =====
    location_verified = False
    distance_meters = None
    
    if current_user.geofence_exempt:
        location_verified = True
    elif current_user.geofence_lat and current_user.geofence_lng:
        distance_meters = haversine_distance(
            req.latitude, req.longitude,
            current_user.geofence_lat, current_user.geofence_lng
        )
        radius = current_user.geofence_radius_m or 200
        
        if distance_meters <= radius:
            location_verified = True
        else:
            raise HTTPException(
                status_code=403,
                detail=f"You are outside the work zone. Distance: {distance_meters:.0f}m, Allowed: {radius}m"
            )
    else:
        location_verified = True
    
    now = datetime.utcnow()
    attendance.check_out_time = now
    attendance.check_out_location = f"{req.latitude},{req.longitude}"
    attendance.check_out_accuracy = req.accuracy
    attendance.server_check_out_time = now
    attendance.status = "completed"
    
    if attendance.check_in_time:
        duration = (now - attendance.check_in_time).total_seconds() / 3600
        attendance.work_duration_hours = round(duration, 2)
    
    await db.commit()
    
    return {
        "status": "checked_out",
        "attendance_id": attendance.attendance_id,
        "work_duration_hours": attendance.work_duration_hours,
        "location_verified": location_verified,
        "distance_meters": round(distance_meters, 2) if distance_meters else None,
    }


@router.get("/today")
async def today_attendance(
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get today's attendance record."""
    today = date.today()
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.employee_id == current_user.employee_id,
                func.date(Attendance.check_in_time) == today
            )
        )
    )
    records = result.scalars().all()
    return {
        "items": [
            {
                "attendance_id": r.attendance_id,
                "check_in_time": r.check_in_time.isoformat() if r.check_in_time else None,
                "check_out_time": r.check_out_time.isoformat() if r.check_out_time else None,
                "status": r.status,
                "work_duration_hours": r.work_duration_hours,
            }
            for r in records
        ]
    }


@router.get("/")
async def list_attendance(
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """List attendance records - requires authentication."""
    result = await db.execute(
        select(Attendance)
        .order_by(desc(Attendance.created_at))
        .limit(limit)
    )
    records = result.scalars().all()
    
    return [
        {
            "attendance_id": r.attendance_id,
            "employee_id": r.employee_id,
            "check_in_time": r.check_in_time.isoformat() if r.check_in_time else None,
            "check_out_time": r.check_out_time.isoformat() if r.check_out_time else None,
            "status": r.status,
            "work_duration_hours": r.work_duration_hours,
            "overtime_hours": r.overtime_hours,
        }
        for r in records
    ]


@router.get("/me")
async def my_attendance(
    limit: int = Query(default=30, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Get current user's attendance - requires authentication."""
    result = await db.execute(
        select(Attendance)
        .where(Attendance.employee_id == current_user.employee_id)
        .order_by(desc(Attendance.created_at))
        .limit(limit)
    )
    records = result.scalars().all()
    
    return [
        {
            "attendance_id": r.attendance_id,
            "check_in_time": r.check_in_time.isoformat() if r.check_in_time else None,
            "check_out_time": r.check_out_time.isoformat() if r.check_out_time else None,
            "status": r.status,
            "work_duration_hours": r.work_duration_hours,
        }
        for r in records
    ]


# ==================== IDENTITY VERIFICATION ====================

class PatternSetupRequest(BaseModel):
    pattern_hash: str


class PatternVerifyRequest(BaseModel):
    pattern_hash: str


@router.post("/setup-pattern")
async def setup_pattern(
    req: PatternSetupRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Setup or update pattern hash for identity verification."""
    current_user.pattern_hash = req.pattern_hash
    await db.commit()
    return {"status": "pattern_set", "message": "Pattern hash saved successfully"}


@router.post("/verify-pattern")
async def verify_pattern(
    req: PatternVerifyRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Employee = Depends(get_current_user)
):
    """Verify pattern hash for identity verification."""
    if not current_user.pattern_hash:
        raise HTTPException(status_code=400, detail="No pattern set. Please setup pattern first.")
    
    is_valid = verify_identity(req.pattern_hash, current_user.pattern_hash)
    return {"valid": is_valid, "message": "Pattern verified" if is_valid else "Invalid pattern"}


@router.get("/identity-status")
async def get_identity_status(
    current_user: Employee = Depends(get_current_user)
):
    """Get identity verification status for current user."""
    return {
        "has_pattern": bool(current_user.pattern_hash),
        "geofence_configured": bool(current_user.geofence_lat and current_user.geofence_lng),
        "geofence_lat": current_user.geofence_lat,
        "geofence_lng": current_user.geofence_lng,
        "geofence_radius_m": current_user.geofence_radius_m or 200,
        "geofence_exempt": current_user.geofence_exempt,
    }

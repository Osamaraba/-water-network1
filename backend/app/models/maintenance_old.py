from datetime import datetime
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.database import Base


class MaintenanceComplaintOld(Base):
    __tablename__ = "complaints"

    complaint_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    complaint_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="NORMAL")
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    reported_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class MaintenanceAssignment(Base):
    __tablename__ = "maintenance_assignments"

    assignment_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    complaint_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("complaints.complaint_id", ondelete="CASCADE"), nullable=False
    )
    technician_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="assigned")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class MaintenanceEvent(Base):
    __tablename__ = "maintenance_events"

    event_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    complaint_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("complaints.complaint_id", ondelete="CASCADE"), nullable=False
    )
    event_type: Mapped[str] = mapped_column(String(30), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class MaintenancePhoto(Base):
    __tablename__ = "maintenance_photos"

    photo_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    complaint_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("complaints.complaint_id", ondelete="CASCADE"), nullable=False
    )
    photo_url: Mapped[str] = mapped_column(String(500), nullable=False)
    caption: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

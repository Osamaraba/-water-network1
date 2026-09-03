from datetime import datetime, date
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float, Boolean, Index, Date, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class OvertimeWorkRequest(Base):
    __tablename__ = "overtime_work_requests"

    request_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    work_date: Mapped[date] = mapped_column(Date, nullable=False)
    work_type: Mapped[str] = mapped_column(String(50), nullable=False, default="field")
    task_description: Mapped[str] = mapped_column(Text, nullable=False)
    area_name: Mapped[str] = mapped_column(String(200), nullable=False)
    area_lat: Mapped[float] = mapped_column(Float, nullable=False)
    area_lng: Mapped[float] = mapped_column(Float, nullable=False)
    area_radius_m: Mapped[float] = mapped_column(Float, default=100.0, nullable=False)
    requested_hours: Mapped[float] = mapped_column(Float, nullable=False)
    extended_hours: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    total_approved_hours: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    actual_hours: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    reviewed_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id"), nullable=True
    )
    review_note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    tracking_session_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("field_tracking_sessions.session_id", ondelete="SET NULL"), nullable=True
    )
    tracking_starts_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    tracking_ends_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_lat: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    completed_lng: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    completed_photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    extended_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id"), nullable=True
    )
    extended_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    reviewer = relationship("Employee", foreign_keys=[reviewed_by])
    extender = relationship("Employee", foreign_keys=[extended_by])
    reports = relationship("OvertimeWorkReport", back_populates="request", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_overtime_employee", "employee_id"),
        Index("idx_overtime_status", "status"),
    )


class OvertimeWorkReport(Base):
    __tablename__ = "overtime_work_reports"

    report_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    request_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("overtime_work_requests.request_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    work_done: Mapped[str] = mapped_column(Text, nullable=False)
    actual_hours: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    actual_lat: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    actual_lng: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    request = relationship("OvertimeWorkRequest", back_populates="reports")

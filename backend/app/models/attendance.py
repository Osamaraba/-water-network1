from datetime import datetime
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float, Boolean, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class Attendance(Base):
    __tablename__ = "attendance"

    attendance_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    check_in_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    check_out_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    check_in_location: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    check_out_location: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    check_in_accuracy: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    check_out_accuracy: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    server_check_in_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    server_check_out_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    identity_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    identity_method: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    is_mock_location: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    device_uuid: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    trust_score: Mapped[int] = mapped_column(Integer, default=100, nullable=False)
    trust_status: Mapped[str] = mapped_column(String(20), default="valid", nullable=False)
    work_duration_hours: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    overtime_hours: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    overtime_status: Mapped[str] = mapped_column(String(20), default="none", nullable=False)
    overtime_approved_by: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    overtime_approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    is_mock_location_detected: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    client_transaction_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])

    __table_args__ = (
        Index("idx_attendance_employee", "employee_id"),
        Index("idx_attendance_date", "check_in_time"),
        Index("idx_attendance_status", "status"),
        Index("idx_attendance_active", "employee_id", "status"),
    )

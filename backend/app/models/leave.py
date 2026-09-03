from datetime import datetime, date, time
from typing import Optional
from sqlalchemy import Integer, String, DateTime, Date, Time, ForeignKey, Text, Boolean, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class LeaveRequest(Base):
    __tablename__ = "leave_requests"

    request_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    leave_type: Mapped[str] = mapped_column(String(20), nullable=False)
    leave_type_custom: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)

    reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    approved_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id"), nullable=True
    )
    approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id"), nullable=True
    )
    review_note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    reviewer = relationship("Employee", foreign_keys=[reviewed_by])

    __table_args__ = (
        Index("idx_leave_employee", "employee_id"),
        Index("idx_leave_status", "status"),
        Index("idx_leave_type", "leave_type"),
    )


class ShortLeave(Base):
    __tablename__ = "short_leaves"

    short_leave_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    leave_kind: Mapped[str] = mapped_column(String(20), nullable=False)
    outing_date: Mapped[date] = mapped_column(Date, nullable=False)
    departure_time: Mapped[time] = mapped_column(Time, nullable=False)
    return_time: Mapped[time] = mapped_column(Time, nullable=False)
    destination: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    tracking_required: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    tracking_session_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("field_tracking_sessions.session_id", ondelete="SET NULL"), nullable=True
    )
    tracking_acknowledged: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    approved_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id"), nullable=True
    )
    approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id"), nullable=True
    )
    review_note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    reviewer = relationship("Employee", foreign_keys=[reviewed_by])

    __table_args__ = (
        Index("idx_short_leave_employee", "employee_id"),
        Index("idx_short_leave_status", "status"),
        Index("idx_short_leave_kind", "leave_kind"),
        Index("idx_short_leave_date", "outing_date"),
    )

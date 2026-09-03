from datetime import datetime, date, time
from typing import Optional
from sqlalchemy import Integer, String, DateTime, Date, Time, ForeignKey, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class ViolationNotice(Base):
    __tablename__ = "violation_notices"

    violation_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    issuer_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False, index=True
    )
    violation_type: Mapped[str] = mapped_column(String(100), nullable=False)
    violation_date: Mapped[date] = mapped_column(Date, nullable=False)
    violation_time: Mapped[time] = mapped_column(Time, nullable=False)
    penalty: Mapped[str] = mapped_column(String(20), nullable=False, default="alert1")
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    acknowledged: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    acknowledged_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    employee_response: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    employee_response_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    hr_reviewed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    hr_reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    hr_reviewer_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    hr_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    issuer = relationship("Employee", foreign_keys=[issuer_id])
    hr_reviewer = relationship("Employee", foreign_keys=[hr_reviewer_id])

from datetime import datetime, time
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float, Boolean, Time, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class WorkSchedule(Base):
    __tablename__ = "work_schedules"

    schedule_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    schedule_type: Mapped[str] = mapped_column(String(20), default="FIXED", nullable=False)
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)
    grace_minutes: Mapped[int] = mapped_column(Integer, default=15, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])

    __table_args__ = (
        Index("idx_schedule_employee", "employee_id"),
        Index("idx_schedule_active", "is_active"),
    )

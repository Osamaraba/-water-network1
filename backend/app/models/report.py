from datetime import datetime, date
from typing import Optional
from sqlalchemy import Integer, String, DateTime, Date, ForeignKey, Text, JSON, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class Report(Base):
    __tablename__ = "reports"

    report_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    recipient_employee_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True, index=True
    )
    report_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    org_unit_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("organization_units.org_unit_id", ondelete="SET NULL"), nullable=True
    )
    attendance_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("attendance.attendance_id", ondelete="SET NULL"), nullable=True
    )
    complaint_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("maintenance_complaints.complaint_id", ondelete="SET NULL"), nullable=True
    )
    report_type: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    work_items: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="submitted", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    recipient = relationship("Employee", foreign_keys=[recipient_employee_id])
    org_unit = relationship("OrganizationUnit", foreign_keys=[org_unit_id])

    __table_args__ = (
        Index("idx_report_employee", "employee_id"),
        Index("idx_report_type", "report_type"),
        Index("idx_report_status", "status"),
    )

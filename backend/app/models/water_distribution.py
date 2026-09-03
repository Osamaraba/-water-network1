from datetime import datetime, date
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float, Boolean, Date, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class WaterDistributionPlan(Base):
    __tablename__ = "water_distribution_plans"

    plan_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    plan_name: Mapped[str] = mapped_column(String(200), nullable=False)
    plan_date: Mapped[date] = mapped_column(Date, nullable=False)
    org_unit_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("organization_units.org_unit_id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), default="draft", nullable=False)
    created_by: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False
    )
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    creator = relationship("Employee", foreign_keys=[created_by])
    assignments = relationship("WaterDistributionAssignment", back_populates="plan", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_wd_plan_date", "plan_date"),
        Index("idx_wd_plan_status", "status"),
    )


class WaterDistributionAssignment(Base):
    __tablename__ = "water_distribution_assignments"

    assignment_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    plan_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("water_distribution_plans.plan_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    distributor_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    route_name: Mapped[str] = mapped_column(String(200), nullable=False)
    area_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    scheduled_start: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    scheduled_end: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="assigned", nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    plan = relationship("WaterDistributionPlan", back_populates="assignments")
    distributor = relationship("Employee", foreign_keys=[distributor_id])
    events = relationship("WaterDistributionEvent", back_populates="assignment", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_wd_assignment_distributor", "distributor_id"),
        Index("idx_wd_assignment_status", "status"),
    )


class WaterDistributionEvent(Base):
    __tablename__ = "water_distribution_events"

    event_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    assignment_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("water_distribution_assignments.assignment_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    distributor_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False
    )
    event_type: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    volume_liters: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quality_status: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    assignment = relationship("WaterDistributionAssignment", back_populates="events")
    distributor = relationship("Employee", foreign_keys=[distributor_id])

    __table_args__ = (
        Index("idx_wd_event_assignment", "assignment_id"),
        Index("idx_wd_event_type", "event_type"),
    )

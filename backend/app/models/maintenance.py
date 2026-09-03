from datetime import datetime, date, time
from typing import Optional
from sqlalchemy import Integer, String, DateTime, Date, Time, ForeignKey, Text, Boolean, Float
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class MaintenanceTeam(Base):
    __tablename__ = "maintenance_teams"

    team_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    team_name: Mapped[str] = mapped_column(String(100), nullable=False)
    team_type: Mapped[str] = mapped_column(String(30), nullable=False)
    governorate: Mapped[str] = mapped_column(String(50), nullable=False)
    team_leader_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    max_active_tasks: Mapped[int] = mapped_column(Integer, default=5)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    leader = relationship("Employee", foreign_keys=[team_leader_id])
    members = relationship("TeamMember", back_populates="team", cascade="all, delete-orphan")
    complaints = relationship("MaintenanceComplaint", back_populates="team")
    periodic_tasks = relationship("PeriodicMaintenanceTask", back_populates="team")


class TeamMember(Base):
    __tablename__ = "team_members"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    team_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("maintenance_teams.team_id", ondelete="CASCADE"), nullable=False
    )
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False
    )
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="technician")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    team = relationship("MaintenanceTeam", back_populates="members")
    employee = relationship("Employee", foreign_keys=[employee_id])


class MaintenanceComplaint(Base):
    __tablename__ = "maintenance_complaints"

    complaint_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    customer_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    customer_phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(30), nullable=False)
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="medium")
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="new")
    governorate: Mapped[str] = mapped_column(String(50), nullable=False)
    district: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    neighborhood: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    team_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("maintenance_teams.team_id", ondelete="SET NULL"), nullable=True
    )
    assigned_to: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    assigned_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    resolution_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    customer_satisfaction: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    created_by: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )

    team = relationship("MaintenanceTeam", back_populates="complaints")
    assigned_employee = relationship("Employee", foreign_keys=[assigned_to])
    creator = relationship("Employee", foreign_keys=[created_by])


class PeriodicMaintenanceTask(Base):
    __tablename__ = "periodic_maintenance_tasks"

    task_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    team_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("maintenance_teams.team_id", ondelete="CASCADE"), nullable=False
    )
    task_name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    frequency: Mapped[str] = mapped_column(String(20), nullable=False)
    day_of_week: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    day_of_month: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    time_of_day: Mapped[time] = mapped_column(Time, nullable=False, default=time(8, 0))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_completed: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    next_due: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    team = relationship("MaintenanceTeam", back_populates="periodic_tasks")
    completions = relationship("PeriodicTaskCompletion", back_populates="task")


class PeriodicTaskCompletion(Base):
    __tablename__ = "periodic_task_completions"

    completion_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    task_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("periodic_maintenance_tasks.task_id", ondelete="CASCADE"), nullable=False
    )
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    completed_date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    task = relationship("PeriodicMaintenanceTask", back_populates="completions")
    employee = relationship("Employee", foreign_keys=[employee_id])

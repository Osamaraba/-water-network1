from datetime import datetime, date
from typing import Optional, List
from sqlalchemy import (
    Integer, String, Boolean, DateTime, ForeignKey, Text, Date, Float, Index, UniqueConstraint
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class OrganizationUnit(Base):
    __tablename__ = "organization_units"

    org_unit_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    parent_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("organization_units.org_unit_id", ondelete="SET NULL"),
        nullable=True, index=True
    )
    unit_name: Mapped[str] = mapped_column(String(200), nullable=False)
    unit_name_en: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    unit_code: Mapped[Optional[str]] = mapped_column(String(50), unique=True, nullable=True)
    unit_type: Mapped[str] = mapped_column(String(50), nullable=False, default="SECTION")
    manager_employee_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    parent = relationship("OrganizationUnit", remote_side="OrganizationUnit.org_unit_id", back_populates="children")
    children = relationship("OrganizationUnit", back_populates="parent")
    employees = relationship("Employee", back_populates="org_unit", foreign_keys="[Employee.org_unit_id]")

    __table_args__ = (
        Index("idx_org_unit_parent", "parent_id"),
        Index("idx_org_unit_type", "unit_type"),
    )


class WorkType(Base):
    __tablename__ = "work_types"

    work_type_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    type_name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    type_name_ar: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_field: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employees = relationship("Employee", back_populates="work_type")


class Employee(Base):
    __tablename__ = "employees"

    employee_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_number: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    full_name_en: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    job_title: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    org_unit_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("organization_units.org_unit_id", ondelete="SET NULL"), nullable=True
    )
    work_type_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("work_types.work_type_id", ondelete="SET NULL"), nullable=True
    )
    direct_manager_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    hire_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    password_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    pattern_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    allow_field_tracking: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    geofence_lat: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    geofence_lng: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    geofence_radius_m: Mapped[int] = mapped_column(Integer, default=200, nullable=False)
    geofence_exempt: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    org_unit = relationship("OrganizationUnit", back_populates="employees", foreign_keys=[org_unit_id])
    work_type = relationship("WorkType", back_populates="employees")
    direct_manager = relationship("Employee", remote_side="Employee.employee_id", back_populates="direct_reports")
    direct_reports = relationship("Employee", back_populates="direct_manager")
    user = relationship("User", back_populates="employee", uselist=False)
    devices = relationship("EmployeeDevice", back_populates="employee", cascade="all, delete-orphan")
    assignments = relationship("EmployeeAssignment", back_populates="employee", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_employee_org", "org_unit_id"),
        Index("idx_employee_manager", "direct_manager_id"),
        Index("idx_employee_work_type", "work_type_id"),
    )


class EmployeeDevice(Base):
    __tablename__ = "employee_devices"

    device_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False
    )
    device_uuid: Mapped[str] = mapped_column(String(256), nullable=False)
    device_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", back_populates="devices")

    __table_args__ = (
        Index("idx_device_employee", "employee_id"),
        Index("idx_device_uuid", "device_uuid"),
    )


class EmployeeAssignment(Base):
    __tablename__ = "employee_assignments"

    assignment_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False
    )
    org_unit_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("organization_units.org_unit_id", ondelete="CASCADE"), nullable=False
    )
    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    effective_to: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", back_populates="assignments")
    org_unit = relationship("OrganizationUnit")

    __table_args__ = (
        Index("idx_assignment_employee", "employee_id"),
        Index("idx_assignment_org", "org_unit_id"),
        Index("idx_assignment_active", "is_active"),
    )

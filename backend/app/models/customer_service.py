from datetime import datetime
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float, Boolean, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class CustomerServiceRequest(Base):
    __tablename__ = "customer_service_requests"

    request_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    request_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    customer_name: Mapped[str] = mapped_column(String(200), nullable=False)
    customer_phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    service_type: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    priority: Mapped[str] = mapped_column(String(20), default="NORMAL", nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="NEW", nullable=False)
    reported_by: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    assigned_to: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"), nullable=True
    )
    org_unit_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("organization_units.org_unit_id", ondelete="SET NULL"), nullable=True
    )
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    reporter = relationship("Employee", foreign_keys=[reported_by])
    assignee = relationship("Employee", foreign_keys=[assigned_to])
    events = relationship("CustomerServiceEvent", back_populates="request", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_cs_request_reporter", "reported_by"),
        Index("idx_cs_request_status", "status"),
        Index("idx_cs_request_type", "service_type"),
    )


class CustomerServiceEvent(Base):
    __tablename__ = "customer_service_events"

    event_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    request_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("customer_service_requests.request_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    worker_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False
    )
    event_type: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    request = relationship("CustomerServiceRequest", back_populates="events")
    worker = relationship("Employee", foreign_keys=[worker_id])


class MeterReading(Base):
    __tablename__ = "meter_readings"

    reading_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    meter_number: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    customer_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    customer_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    previous_reading: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    current_reading: Mapped[float] = mapped_column(Float, nullable=False)
    consumption: Mapped[float] = mapped_column(Float, nullable=False)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    reading_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])

    __table_args__ = (
        Index("idx_meter_employee", "employee_id"),
        Index("idx_meter_number", "meter_number"),
    )

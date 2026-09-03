from datetime import datetime
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Float, Boolean, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class FieldTrackingSession(Base):
    __tablename__ = "field_tracking_sessions"

    session_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    viewer_employee_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"),
        nullable=True, index=True
    )
    started_by_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="SET NULL"),
        nullable=True, index=True
    )
    tracking_type: Mapped[str] = mapped_column(String(50), nullable=False)
    track_mode: Mapped[str] = mapped_column(String(20), default="distance", nullable=False)
    track_interval: Mapped[int] = mapped_column(Integer, default=50, nullable=False)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    is_outside: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    outside_started_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    outside_distance_m: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    last_lat: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    last_lng: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    last_point_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    track_color: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    viewer = relationship("Employee", foreign_keys=[viewer_employee_id])
    started_by = relationship("Employee", foreign_keys=[started_by_id])
    points = relationship("FieldTrackingPoint", back_populates="session", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_tracking_session_employee", "employee_id"),
        Index("idx_tracking_session_viewer", "viewer_employee_id"),
        Index("idx_tracking_session_status", "status"),
    )


class FieldTrackingPoint(Base):
    __tablename__ = "field_tracking_points"

    point_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    session_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("field_tracking_sessions.session_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    accuracy: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    speed: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    altitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    battery_level: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    session = relationship("FieldTrackingSession", back_populates="points")
    employee = relationship("Employee", foreign_keys=[employee_id])

    __table_args__ = (
        Index("idx_tracking_point_session", "session_id"),
        Index("idx_tracking_point_employee", "employee_id"),
        Index("idx_tracking_point_time", "recorded_at"),
    )


class GeofenceBreach(Base):
    __tablename__ = "geofence_breaches"

    breach_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    session_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("field_tracking_sessions.session_id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    duration_seconds: Mapped[float] = mapped_column(Float, nullable=False)
    distance_m: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    start_latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    start_longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    end_latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    end_longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    session = relationship("FieldTrackingSession")
    employee = relationship("Employee", foreign_keys=[employee_id])

    __table_args__ = (
        Index("idx_breach_employee", "employee_id"),
        Index("idx_breach_session", "session_id"),
    )

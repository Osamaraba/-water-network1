from datetime import datetime, date
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text, Date, Boolean, Index, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database import Base


class WorkScopeType(Base):
    __tablename__ = "work_scope_types"

    scope_type_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    type_name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    type_name_ar: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    scopes = relationship("WorkScope", back_populates="scope_type")


class WorkScope(Base):
    __tablename__ = "work_scopes"

    scope_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    employee_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    scope_type_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("work_scope_types.scope_type_id", ondelete="CASCADE"),
        nullable=False
    )
    scope_name: Mapped[str] = mapped_column(String(200), nullable=False)
    scope_name_en: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    parent_scope_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("work_scopes.scope_id", ondelete="SET NULL"), nullable=True
    )
    latitude: Mapped[Optional[float]] = mapped_column(Text, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Text, nullable=True)
    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    effective_to: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    employee = relationship("Employee", foreign_keys=[employee_id])
    scope_type = relationship("WorkScopeType", back_populates="scopes")
    parent_scope = relationship("WorkScope", remote_side="WorkScope.scope_id")

    __table_args__ = (
        Index("idx_work_scope_employee", "employee_id"),
        Index("idx_work_scope_type", "scope_type_id"),
        Index("idx_work_scope_active", "is_active"),
    )

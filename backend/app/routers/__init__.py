from app.routers.auth import router as auth_router
from app.routers.organization import router as organization_router
from app.routers.employees import router as employees_router
from app.routers.attendance import router as attendance_router
from app.routers.leave_requests import router as leave_requests_router
from app.routers.maintenance import router as maintenance_router
from app.routers.gps import router as gps_router
from app.routers.notifications import router as notifications_router
from app.routers.overtime_work import router as overtime_work_router
from app.routers.reports import router as reports_router
from app.routers.reports_extended import router as reports_extended_router
from app.routers.security import router as security_router
from app.routers.work_scopes import router as work_scopes_router
from app.routers.customer_service import router as customer_service_router
from app.routers.water_distribution import router as water_distribution_router
from app.routers.audit import router as audit_router
from app.routers.violations import router as violations_router
from app.routers.bulk_actions import router as bulk_actions_router
from app.routers.tasks import router as tasks_router
from app.routers.api_keys import router as api_keys_router

__all__ = [
    "auth_router",
    "organization_router",
    "employees_router",
    "attendance_router",
    "leave_requests_router",
    "maintenance_router",
    "gps_router",
    "notifications_router",
    "overtime_work_router",
    "reports_router",
    "reports_extended_router",
    "security_router",
    "work_scopes_router",
    "customer_service_router",
    "water_distribution_router",
    "audit_router",
    "violations_router",
    "bulk_actions_router",
    "tasks_router",
    "api_keys_router",
]

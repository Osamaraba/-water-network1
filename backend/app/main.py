from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import time
import uuid
import logging
from app.config import settings
from app.database import init_db
from app.models import *  # noqa: F401, F403
from app.logging_config import setup_logging

# Setup logging
setup_logging()
logger = logging.getLogger("app.main")


class RequestMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())[:8]
        start = time.time()
        request.state.request_id = request_id
        
        # Add request_id to logging context
        old_factory = logging.getLogRecordFactory()
        
        def record_factory(*args, **kwargs):
            record = old_factory(*args, **kwargs)
            record.request_id = request_id
            return record
        
        logging.setLogRecordFactory(record_factory)
        
        logger.info(f"Request started: {request.method} {request.url.path}")
        
        response = await call_next(request)
        
        duration = round(time.time() - start, 3)
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time"] = str(duration)
        
        logger.info(f"Request completed: {request.method} {request.url.path} - {response.status_code} ({duration}s)")
        
        return response


rate_limit_store = {}


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "unknown"
        now = time.time()
        window_key = f"{client_ip}:{int(now // 60)}"
        count = rate_limit_store.get(window_key, 0)
        if count >= settings.RATE_LIMIT_PER_MINUTE:
            from fastapi.responses import JSONResponse
            return JSONResponse(
                status_code=429,
                content={"detail": "Rate limit exceeded"},
            )
        rate_limit_store[window_key] = count + 1
        keys_to_remove = [k for k in rate_limit_store if int(k.split(":")[1]) < int(now // 60) - 1]
        for k in keys_to_remove:
            del rate_limit_store[k]
        response = await call_next(request)
        return response


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting Yarmouk Water Management Pro...")
    await init_db()
    logger.info("Database initialized")
    
    from app.database import AsyncSessionLocal
    async with AsyncSessionLocal() as db:
        from app.seeds.seed_data import seed_data
        await seed_data(db)
    logger.info("Seed data loaded")
    
    # Start background tasks
    from app.tasks import task_manager, register_default_tasks
    register_default_tasks()
    await task_manager.start()
    logger.info("Background tasks started")
    
    logger.info("Application ready")
    yield
    
    # Stop background tasks
    await task_manager.stop()
    logger.info("Shutting down application")


app = FastAPI(
    title="Yarmouk Water Management Pro",
    version="1.0.0",
    description="Enterprise Employee Management System for Yarmouk Water Company",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RequestMiddleware)
app.add_middleware(RateLimitMiddleware)

from app.middleware.audit import audit_middleware

app.middleware("http")(audit_middleware)


@app.get("/health")
async def health_check():
    """Basic health check endpoint."""
    logger.debug("Health check requested")
    return {"status": "healthy", "version": "1.0.0"}


@app.get("/health/detailed")
async def detailed_health_check():
    """Detailed health check with database connectivity."""
    from sqlalchemy import text
    from app.database import AsyncSessionLocal
    
    checks = {
        "status": "healthy",
        "version": "1.0.0",
        "environment": settings.ENVIRONMENT,
        "database": "unknown",
        "timestamp": datetime.now().isoformat(),
    }
    
    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
        checks["database"] = "connected"
    except Exception as e:
        checks["database"] = f"error: {str(e)[:100]}"
        checks["status"] = "degraded"
        logger.error(f"Database health check failed: {e}")
    
    return checks


@app.get("/")
async def root():
    return {
        "name": "Yarmouk Water Management Pro",
        "version": "1.0.0",
        "status": "running",
    }


from app.routers import (  # noqa: E402
    auth, organization, employees, attendance, leave_requests,
    maintenance, gps, notifications, overtime_work, reports,
    reports_extended, security,
    work_scopes, customer_service, water_distribution, audit, violations,
    compatibility, flutter_compat, bulk_actions, tasks, api_keys,
    maintenance_teams, periodic_maintenance,
)
from app.realtime import ws as ws_router  # noqa: E402

app.include_router(auth.router)
app.include_router(compatibility.router)
app.include_router(flutter_compat.router)
app.include_router(organization.router)
app.include_router(employees.router)
app.include_router(attendance.router)
app.include_router(leave_requests.router)
app.include_router(maintenance.router)
app.include_router(maintenance_teams.router)
app.include_router(periodic_maintenance.router)
app.include_router(gps.router)
app.include_router(notifications.router)
app.include_router(overtime_work.router)
app.include_router(reports.router)
app.include_router(reports_extended.router)
app.include_router(security.router)
app.include_router(violations.router)
app.include_router(work_scopes.router)
app.include_router(customer_service.router)
app.include_router(water_distribution.router)
app.include_router(audit.router)
app.include_router(bulk_actions.router)
app.include_router(tasks.router)
app.include_router(api_keys.router)
app.include_router(ws_router.router)

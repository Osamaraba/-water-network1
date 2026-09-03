import json
from typing import Callable, Optional

from fastapi import Request, Response

from app.database import AsyncSessionLocal
from app.models.notification import AuditLog
from app.utils.security import decode_token

SKIP_EXACT = {"/", "/health", "/docs", "/redoc", "/openapi.json"}
SKIP_PREFIX = ("/docs", "/redoc", "/openapi", "/static")


def _extract_employee_id(token: Optional[str]) -> Optional[int]:
    if not token:
        return None
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        return None
    emp = payload.get("emp")
    if emp is None:
        return None
    try:
        return int(emp)
    except (TypeError, ValueError):
        return None


def _client_ip(request: Request) -> Optional[str]:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None


async def audit_middleware(request: Request, call_next: Callable) -> Response:
    response = await call_next(request)

    path = request.url.path
    if path in SKIP_EXACT or path.startswith(SKIP_PREFIX):
        return response

    auth_header = request.headers.get("authorization", "")
    token = auth_header[7:] if auth_header.lower().startswith("bearer ") else None
    employee_id = _extract_employee_id(token)

    segments = [s for s in path.split("/") if s]
    entity_type = segments[0] if segments else "root"
    entity_id = segments[1] if len(segments) > 1 else None

    try:
        async with AsyncSessionLocal() as db:
            db.add(
                AuditLog(
                    employee_id=employee_id,
                    action=request.method,
                    entity_type=entity_type,
                    entity_id=str(entity_id) if entity_id else None,
                    ip_address=_client_ip(request),
                    user_agent=request.headers.get("user-agent"),
                )
            )
            await db.commit()
    except Exception:
        pass

    return response

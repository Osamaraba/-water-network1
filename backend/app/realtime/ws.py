from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

from app.realtime.connection_manager import manager
from app.utils.security import decode_token

router = APIRouter(tags=["Realtime"])


@router.websocket("/ws/notifications")
async def ws_notifications(websocket: WebSocket, token: str = Query(...)):
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        await websocket.close(code=1008)
        return

    emp = payload.get("emp") or payload.get("employee_id")
    if emp is None:
        await websocket.close(code=1008)
        return

    try:
        employee_id = int(emp)
    except (TypeError, ValueError):
        await websocket.close(code=1008)
        return

    await manager.connect(employee_id, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(employee_id, websocket)
    except Exception:
        manager.disconnect(employee_id, websocket)

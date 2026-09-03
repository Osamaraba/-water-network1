from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self.active: dict[int, list[WebSocket]] = {}

    async def connect(self, employee_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self.active.setdefault(employee_id, []).append(websocket)

    def disconnect(self, employee_id: int, websocket: WebSocket) -> None:
        sockets = self.active.get(employee_id)
        if not sockets:
            return
        if websocket in sockets:
            sockets.remove(websocket)
        if not sockets:
            self.active.pop(employee_id, None)

    async def send_to_employee(self, employee_id: int, message: dict) -> None:
        for websocket in list(self.active.get(employee_id, [])):
            try:
                await websocket.send_json(message)
            except Exception:
                pass

    async def broadcast(self, message: dict) -> None:
        for sockets in self.active.values():
            for websocket in list(sockets):
                try:
                    await websocket.send_json(message)
                except Exception:
                    pass


manager = ConnectionManager()

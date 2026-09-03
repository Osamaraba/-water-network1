"""
Background Tasks API
Yarmouk Water Management Pro
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.middleware.auth import get_current_user
from app.models import Employee
from app.tasks import task_manager

router = APIRouter(prefix="/tasks", tags=["background-tasks"])


# =============================================================================
# Response Models
# =============================================================================

class TaskResponse(BaseModel):
    task_id: str
    status: str
    created_at: datetime
    completed_at: Optional[datetime] = None
    error: Optional[str] = None


class TaskListResponse(BaseModel):
    tasks: List[TaskResponse]
    total: int


# =============================================================================
# Endpoints
# =============================================================================

@router.get("/", response_model=TaskListResponse)
async def list_tasks(current_user: Employee = Depends(get_current_user)):
    """List all background tasks."""
    tasks = task_manager.get_all_tasks()
    return TaskListResponse(
        tasks=[
            TaskResponse(
                task_id=t.task_id,
                status=t.status,
                created_at=t.created_at,
                completed_at=t.completed_at,
                error=t.error,
            )
            for t in tasks
        ],
        total=len(tasks),
    )


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str, current_user: Employee = Depends(get_current_user)):
    """Get a specific task."""
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    return TaskResponse(
        task_id=task.task_id,
        status=task.status,
        created_at=task.created_at,
        completed_at=task.completed_at,
        error=task.error,
    )


@router.post("/{task_id}/cancel")
async def cancel_task(task_id: str, current_user: Employee = Depends(get_current_user)):
    """Cancel a background task."""
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status not in ("pending", "running"):
        raise HTTPException(status_code=400, detail="Task cannot be cancelled")
    
    task_manager.remove_task(task_id)
    return {"message": f"Task {task_id} cancelled"}


@router.post("/trigger/{task_name}")
async def trigger_task(task_name: str, current_user: Employee = Depends(get_current_user)):
    """Trigger a predefined task."""
    from app.tasks import cleanup_old_sessions, send_daily_reports
    
    tasks_map = {
        "cleanup_sessions": cleanup_old_sessions,
        "daily_reports": send_daily_reports,
    }
    
    if task_name not in tasks_map:
        raise HTTPException(status_code=404, detail=f"Task '{task_name}' not found")
    
    task_id = f"{task_name}_manual_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    task_manager.add_task(
        task_id=task_id,
        func=tasks_map[task_name],
    )
    
    return {"message": f"Task '{task_name}' triggered", "task_id": task_id}

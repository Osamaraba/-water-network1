"""
Background Tasks System
Yarmouk Water Management Pro
"""
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Optional, Callable, Any, Dict, List
from collections import defaultdict
import json

logger = logging.getLogger("app.background_tasks")


class BackgroundTask:
    """Represents a background task."""
    
    def __init__(
        self,
        task_id: str,
        func: Callable,
        args: tuple = (),
        kwargs: dict = None,
        scheduled_at: Optional[datetime] = None,
        interval_seconds: Optional[int] = None,
    ):
        self.task_id = task_id
        self.func = func
        self.args = args
        self.kwargs = kwargs or {}
        self.scheduled_at = scheduled_at or datetime.utcnow()
        self.interval_seconds = interval_seconds
        self.status = "pending"
        self.result: Any = None
        self.error: Optional[str] = None
        self.created_at = datetime.utcnow()
        self.completed_at: Optional[datetime] = None


class BackgroundTaskManager:
    """Manages background tasks."""
    
    def __init__(self):
        self._tasks: Dict[str, BackgroundTask] = {}
        self._running = False
        self._task_loop: Optional[asyncio.Task] = None
        self._recurring_tasks: Dict[str, dict] = {}
    
    def add_task(
        self,
        task_id: str,
        func: Callable,
        args: tuple = (),
        kwargs: dict = None,
        scheduled_at: Optional[datetime] = None,
        interval_seconds: Optional[int] = None,
    ) -> BackgroundTask:
        """Add a background task."""
        task = BackgroundTask(
            task_id=task_id,
            func=func,
            args=args,
            kwargs=kwargs,
            scheduled_at=scheduled_at,
            interval_seconds=interval_seconds,
        )
        self._tasks[task_id] = task
        
        if interval_seconds:
            self._recurring_tasks[task_id] = {
                "func": func,
                "args": args,
                "kwargs": kwargs or {},
                "interval": interval_seconds,
                "last_run": None,
            }
        
        logger.info(f"Task added: {task_id}")
        return task
    
    def get_task(self, task_id: str) -> Optional[BackgroundTask]:
        """Get a task by ID."""
        return self._tasks.get(task_id)
    
    def get_all_tasks(self) -> List[BackgroundTask]:
        """Get all tasks."""
        return list(self._tasks.values())
    
    def get_pending_tasks(self) -> List[BackgroundTask]:
        """Get pending tasks."""
        return [t for t in self._tasks.values() if t.status == "pending"]
    
    async def start(self):
        """Start the task manager."""
        if self._running:
            return
        
        self._running = True
        self._task_loop = asyncio.create_task(self._process_tasks())
        logger.info("Background task manager started")
    
    async def stop(self):
        """Stop the task manager."""
        self._running = False
        if self._task_loop:
            self._task_loop.cancel()
            try:
                await self._task_loop
            except asyncio.CancelledError:
                pass
        logger.info("Background task manager stopped")
    
    async def _process_tasks(self):
        """Process tasks in the background."""
        while self._running:
            try:
                now = datetime.utcnow()
                
                # Process one-time tasks
                for task_id, task in list(self._tasks.items()):
                    if task.status == "pending" and task.scheduled_at <= now:
                        await self._execute_task(task)
                
                # Process recurring tasks
                for task_id, task_info in list(self._recurring_tasks.items()):
                    last_run = task_info["last_run"]
                    interval = task_info["interval"]
                    
                    if last_run is None or (now - last_run).total_seconds() >= interval:
                        try:
                            if asyncio.iscoroutinefunction(task_info["func"]):
                                await task_info["func"](*task_info["args"], **task_info["kwargs"])
                            else:
                                task_info["func"](*task_info["args"], **task_info["kwargs"])
                            
                            task_info["last_run"] = now
                            logger.debug(f"Recurring task executed: {task_id}")
                        except Exception as e:
                            logger.error(f"Recurring task failed: {task_id} - {e}")
                
                await asyncio.sleep(1)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Task manager error: {e}")
                await asyncio.sleep(5)
    
    async def _execute_task(self, task: BackgroundTask):
        """Execute a single task."""
        task.status = "running"
        try:
            if asyncio.iscoroutinefunction(task.func):
                task.result = await task.func(*task.args, **task.kwargs)
            else:
                task.result = task.func(*task.args, **task.kwargs)
            
            task.status = "completed"
            task.completed_at = datetime.utcnow()
            logger.info(f"Task completed: {task.task_id}")
            
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            task.completed_at = datetime.utcnow()
            logger.error(f"Task failed: {task.task_id} - {e}")
    
    def remove_task(self, task_id: str) -> bool:
        """Remove a task."""
        if task_id in self._tasks:
            del self._tasks[task_id]
            self._recurring_tasks.pop(task_id, None)
            logger.info(f"Task removed: {task_id}")
            return True
        return False


# Global task manager instance
task_manager = BackgroundTaskManager()


# =============================================================================
# Common Background Tasks
# =============================================================================

async def cleanup_old_sessions():
    """Clean up expired sessions periodically."""
    from app.models import AuditLog
    from app.database import AsyncSessionLocal
    
    try:
        async with AsyncSessionLocal() as db:
            cutoff = datetime.utcnow() - timedelta(days=30)
            # Clean old audit logs (keep last 30 days)
            from sqlalchemy import delete
            await db.execute(
                delete(AuditLog).where(AuditLog.created_at < cutoff)
            )
            await db.commit()
            logger.info("Old sessions cleaned up")
    except Exception as e:
        logger.error(f"Session cleanup failed: {e}")


async def send_daily_reports():
    """Send daily attendance reports."""
    logger.info("Daily report task triggered")
    # Implementation for sending daily reports would go here


def register_default_tasks():
    """Register default background tasks."""
    task_manager.add_task(
        task_id="cleanup_sessions",
        func=cleanup_old_sessions,
        interval_seconds=3600,  # Every hour
    )
    
    task_manager.add_task(
        task_id="daily_reports",
        func=send_daily_reports,
        interval_seconds=86400,  # Every day
    )
    
    logger.info("Default tasks registered")

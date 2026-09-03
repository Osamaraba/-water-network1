"""
Tests for Tasks Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_tasks(client: AsyncClient, auth_headers: dict):
    """Test list background tasks."""
    response = await client.get("/tasks/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "tasks" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_trigger_task(client: AsyncClient, auth_headers: dict):
    """Test trigger a background task."""
    response = await client.post(
        "/tasks/trigger/cleanup_sessions",
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "task_id" in data


@pytest.mark.asyncio
async def test_trigger_invalid_task(client: AsyncClient, auth_headers: dict):
    """Test trigger invalid task."""
    response = await client.post(
        "/tasks/trigger/nonexistent_task",
        headers=auth_headers
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_task(client: AsyncClient, auth_headers: dict):
    """Test get task by ID."""
    # First trigger a task
    trigger_response = await client.post(
        "/tasks/trigger/cleanup_sessions",
        headers=auth_headers
    )
    task_id = trigger_response.json()["task_id"]
    
    # Then get it
    response = await client.get(f"/tasks/{task_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["task_id"] == task_id

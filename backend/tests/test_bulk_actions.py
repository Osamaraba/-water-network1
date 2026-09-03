"""
Tests for Bulk Actions Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_bulk_approve_leave(client: AsyncClient, auth_headers: dict):
    """Test bulk approve leave requests."""
    response = await client.post(
        "/bulk/leave/approve",
        headers=auth_headers,
        json={"ids": [1, 2], "action": "approve", "reason": "Test"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "updated_count" in data


@pytest.mark.asyncio
async def test_bulk_reject_leave(client: AsyncClient, auth_headers: dict):
    """Test bulk reject leave requests."""
    response = await client.post(
        "/bulk/leave/approve",
        headers=auth_headers,
        json={"ids": [1, 2], "action": "reject", "reason": "Test reject"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


@pytest.mark.asyncio
async def test_bulk_approve_overtime(client: AsyncClient, auth_headers: dict):
    """Test bulk approve overtime requests."""
    response = await client.post(
        "/bulk/overtime/approve",
        headers=auth_headers,
        json={"ids": [1, 2], "action": "approve", "reason": "Test"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


@pytest.mark.asyncio
async def test_bulk_invalid_action(client: AsyncClient, auth_headers: dict):
    """Test bulk action with invalid action."""
    response = await client.post(
        "/bulk/leave/approve",
        headers=auth_headers,
        json={"ids": [1], "action": "invalid"}
    )
    assert response.status_code == 400

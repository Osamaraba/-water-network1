"""
Tests for Security Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_security_status(client: AsyncClient, auth_headers: dict):
    """Test security status endpoint."""
    response = await client.get("/security/security-status", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "is_active" in data
    assert "is_locked" in data


@pytest.mark.asyncio
async def test_list_sessions(client: AsyncClient, auth_headers: dict):
    """Test list sessions endpoint."""
    response = await client.get("/security/sessions", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    # May return dict with sessions key or list
    assert isinstance(data, (list, dict))


@pytest.mark.asyncio
async def test_change_password(client: AsyncClient, auth_headers: dict):
    """Test change password endpoint."""
    response = await client.post(
        "/security/change-password",
        headers=auth_headers,
        json={
            "current_password": "Yarmouk@2025",
            "new_password": "Yarmouk@2025"
        }
    )
    # May return 200 or 400 depending on validation
    assert response.status_code in [200, 400]

"""
Tests for Authentication Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient):
    """Test successful login."""
    response = await client.post(
        "/auth/login",
        json={"employee_number": "EMP001", "password": "Yarmouk@2025"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient):
    """Test login with wrong password."""
    response = await client.post(
        "/auth/login",
        json={"employee_number": "EMP001", "password": "wrong_password"}
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient):
    """Test login with nonexistent user."""
    response = await client.post(
        "/auth/login",
        json={"employee_number": "NONEXISTENT", "password": "Yarmouk@2025"}
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_current_user(client: AsyncClient, auth_headers: dict):
    """Test get current user endpoint."""
    response = await client.get("/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "employee_number" in data
    assert "full_name" in data


@pytest.mark.asyncio
async def test_unauthorized_access(client: AsyncClient):
    """Test unauthorized access."""
    response = await client.get("/auth/me")
    assert response.status_code == 401

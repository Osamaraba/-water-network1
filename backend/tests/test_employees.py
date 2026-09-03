"""
Tests for Employee Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_employees(client: AsyncClient, auth_headers: dict):
    """Test list employees endpoint."""
    response = await client.get("/employees/all", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0


@pytest.mark.asyncio
async def test_get_employee(client: AsyncClient, auth_headers: dict):
    """Test get employee by ID."""
    response = await client.get("/employees/1", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["employee_id"] == 1
    assert "full_name" in data


@pytest.mark.asyncio
async def test_get_nonexistent_employee(client: AsyncClient, auth_headers: dict):
    """Test get nonexistent employee."""
    response = await client.get("/employees/99999", headers=auth_headers)
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_search_employees(client: AsyncClient, auth_headers: dict):
    """Test search employees."""
    response = await client.get("/employees/all?search=manager", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

"""
Tests for Reports Extended Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_dashboard_kpis(client: AsyncClient, auth_headers: dict):
    """Test dashboard KPIs endpoint."""
    response = await client.get("/reports-extended/dashboard", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_employees" in data
    assert isinstance(data["total_employees"], int)


@pytest.mark.asyncio
async def test_attendance_summary(client: AsyncClient, auth_headers: dict):
    """Test attendance summary endpoint."""
    response = await client.get("/reports-extended/attendance/summary", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_records" in data


@pytest.mark.asyncio
async def test_leave_summary(client: AsyncClient, auth_headers: dict):
    """Test leave summary endpoint."""
    response = await client.get("/reports-extended/leave/summary", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_requests" in data


@pytest.mark.asyncio
async def test_overtime_summary(client: AsyncClient, auth_headers: dict):
    """Test overtime summary endpoint."""
    response = await client.get("/reports-extended/overtime/summary", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_requests" in data


@pytest.mark.asyncio
async def test_employee_directory(client: AsyncClient, auth_headers: dict):
    """Test employee directory endpoint."""
    response = await client.get("/reports-extended/employees/directory", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    # May return dict with employees key or list
    assert isinstance(data, (list, dict))


@pytest.mark.asyncio
async def test_audit_log(client: AsyncClient, auth_headers: dict):
    """Test audit log endpoint."""
    response = await client.get("/reports-extended/audit", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    # May return dict with logs key or list
    assert isinstance(data, (list, dict))

"""
Test Configuration
Yarmouk Water Management Pro
"""
import pytest
import asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def client():
    """Create test HTTP client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def auth_headers(client):
    """Get authentication headers."""
    response = await client.post(
        "/auth/login",
        json={"employee_number": "EMP001", "password": "Yarmouk@2025"}
    )
    token = response.json()["access_token"]
    return {"Authorization": "Bearer " + token}

"""
Tests for API Keys Endpoints
Yarmouk Water Management Pro
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_api_key(client: AsyncClient, auth_headers: dict):
    """Test create API key."""
    response = await client.post(
        "/api-keys/",
        headers=auth_headers,
        json={
            "name": "Test Key",
            "description": "Test API key",
            "expires_in_days": 30
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "key_id" in data
    assert "full_key" in data
    assert "key_prefix" in data


@pytest.mark.asyncio
async def test_list_api_keys(client: AsyncClient, auth_headers: dict):
    """Test list API keys."""
    response = await client.get("/api-keys/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.asyncio
async def test_get_api_key(client: AsyncClient, auth_headers: dict):
    """Test get API key by ID."""
    # First create a key
    create_response = await client.post(
        "/api-keys/",
        headers=auth_headers,
        json={"name": "Test Key"}
    )
    key_id = create_response.json()["key_id"]
    
    # Then get it
    response = await client.get(f"/api-keys/{key_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["key_id"] == key_id


@pytest.mark.asyncio
async def test_revoke_api_key(client: AsyncClient, auth_headers: dict):
    """Test revoke API key."""
    # First create a key
    create_response = await client.post(
        "/api-keys/",
        headers=auth_headers,
        json={"name": "Test Key to Revoke"}
    )
    key_id = create_response.json()["key_id"]
    
    # Then revoke it
    response = await client.delete(f"/api-keys/{key_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


@pytest.mark.asyncio
async def test_revoke_nonexistent_key(client: AsyncClient, auth_headers: dict):
    """Test revoke nonexistent API key."""
    response = await client.delete("/api-keys/99999", headers=auth_headers)
    assert response.status_code == 404

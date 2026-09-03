# -*- coding: utf-8 -*-
import httpx
import json
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE = "http://localhost:8000"

# Test health
r = httpx.get(f"{BASE}/health", timeout=10)
print(f"Health: {r.status_code} - {r.text}")

# Login
resp = httpx.post(f"{BASE}/auth/login", json={
    "employee_number": "EMP001",
    "password": "Yarmouk@2025"
}, timeout=30)
print(f"Login: {resp.status_code}")
token = resp.json()["access_token"]

# Test employees/all
r = httpx.get(f"{BASE}/employees/all", headers={"Authorization": f"Bearer {token}"}, timeout=30)
print(f"GET /employees/all: {r.status_code}")
if r.status_code == 200:
    data = r.json()
    items = data.get("items", [])
    print(f"Total employees: {len(items)}")
    for e in items[:20]:
        print(f"  {e['employee_number']} - {e['full_name']}")
else:
    print(f"Error: {r.text[:300]}")

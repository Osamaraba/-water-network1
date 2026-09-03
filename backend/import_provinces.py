# -*- coding: utf-8 -*-
import httpx
import json
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE = "http://localhost:8000"

def login():
    resp = httpx.post(f"{BASE}/auth/login", json={
        "employee_number": "EMP001",
        "password": "Yarmouk@2025"
    }, timeout=30)
    return resp.json()["access_token"]

def import_file(token, filepath):
    files = {"file": open(filepath, "rb")}
    headers = {"Authorization": f"Bearer {token}"}
    r = httpx.post(f"{BASE}/employees/bulk-import", files=files, headers=headers, timeout=120)
    result = r.json()
    return r.status_code, result

def main():
    token = login()
    print("Token: OK")

    files = [
        (r"D:\yarmouk_water_management_pro\backend\output\provinces\province_ajloun_AJL.xlsx", "عجلون"),
        (r"D:\yarmouk_water_management_pro\backend\output\provinces\province_jerash_JER.xlsx", "جرش"),
    ]

    for path, name in files:
        try:
            status, result = import_file(token, path)
            print(f"[{name}] HTTP {status} -> {json.dumps(result, ensure_ascii=False)}")
        except Exception as e:
            print(f"[{name}] FAILED: {e}")

if __name__ == "__main__":
    main()

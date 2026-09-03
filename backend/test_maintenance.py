import sqlite3
import requests
import json

BASE = "http://127.0.0.1:8000"
TOKEN = None

def login():
    global TOKEN
    r = requests.post(f"{BASE}/auth/login", json={"employee_number": "EMP001", "password": "Yarmouk@2025"})
    if r.status_code == 200:
        TOKEN = r.json().get("access_token")
        print(f"LOGIN: OK (token={TOKEN[:20]}...)")
    else:
        print(f"LOGIN FAIL: {r.status_code} {r.text[:200]}")

def headers():
    return {"Authorization": f"Bearer {TOKEN}"} if TOKEN else {}

def test_get(path, label):
    try:
        r = requests.get(f"{BASE}{path}", headers=headers())
        if r.status_code == 200:
            data = r.json()
            if isinstance(data, dict) and "items" in data:
                print(f"OK {label}: {len(data['items'])} items")
            elif isinstance(data, dict):
                print(f"OK {label}: keys={list(data.keys())[:5]}")
            else:
                print(f"OK {label}: {len(data)} items")
        else:
            print(f"FAIL {label}: {r.status_code} {r.text[:150]}")
    except Exception as e:
        print(f"ERROR {label}: {e}")

def test_post(path, label, body):
    try:
        r = requests.post(f"{BASE}{path}", headers=headers(), json=body)
        if r.status_code in (200, 201):
            data = r.json()
            print(f"OK {label}: {str(data)[:150]}")
            return data
        else:
            print(f"FAIL {label}: {r.status_code} {r.text[:200]}")
    except Exception as e:
        print(f"ERROR {label}: {e}")
    return None

print("=" * 60)
print("1. CHECK DATABASE TABLES")
print("=" * 60)
conn = sqlite3.connect('yarmouk_water.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cursor.fetchall()]
print(f"Tables: {tables}")

required = ['maintenance_teams', 'team_members', 'maintenance_complaints', 'periodic_maintenance_tasks', 'periodic_task_completions']
for t in required:
    status = "EXISTS" if t in tables else "MISSING"
    print(f"  {t}: {status}")

cursor.execute("PRAGMA table_info(maintenance_teams)")
cols = [c[1] for c in cursor.fetchall()]
print(f"  maintenance_teams columns: {cols}")

cursor.execute("PRAGMA table_info(periodic_maintenance_tasks)")
cols2 = [c[1] for c in cursor.fetchall()]
print(f"  periodic_maintenance_tasks columns: {cols2}")
conn.close()

print()
print("=" * 60)
print("2. LOGIN")
print("=" * 60)
login()

if not TOKEN:
    print("Cannot continue without token")
    exit(1)

print()
print("=" * 60)
print("3. TEST TEAMS ENDPOINTS")
print("=" * 60)
test_get("/maintenance/teams", "GET /teams")

team = test_post("/maintenance/teams", "POST /teams (create)", {
    "team_name": "فريق صيانة عمان",
    "team_type": "water_maintenance",
    "governorate": "عمّان",
    "max_active_tasks": 5,
})

if team and "team_id" in team:
    tid = team["team_id"]
    test_get(f"/maintenance/teams/{tid}", f"GET /teams/{tid}")
    
    test_post(f"/maintenance/teams/{tid}/members", f"POST /teams/{tid}/members", {
        "employee_id": 1,
        "role": "technician",
    })
    
    test_get(f"/maintenance/teams/{tid}", f"GET /teams/{tid} (after add member)")

print()
print("=" * 60)
print("4. TEST COMPLAINTS ENDPOINTS")
print("=" * 60)
complaint = test_post("/maintenance/complaints", "POST /complaints", {
    "description": "تسريب مياه في شارع الملك عبدالله",
    "category": "water_leak_main",
    "priority": "high",
    "governorate": "عمّان",
    "district": "الرابية",
    "neighborhood": "حي الزيتون",
})

test_get("/maintenance/complaints", "GET /complaints")
test_get("/maintenance/complaints/my-team", "GET /complaints/my-team")
test_get("/maintenance/stats", "GET /stats")

if complaint and "complaint_id" in complaint:
    cid = complaint["complaint_id"]
    if team and "team_id" in team:
        test_post(f"/maintenance/complaints/{cid}/assign", f"POST /complaints/{cid}/assign", {
            "team_id": team["team_id"],
            "assigned_to": 1,
        })
    test_post(f"/maintenance/complaints/{cid}/update", f"POST /complaints/{cid}/update", {
        "status": "in_progress",
        "resolution_notes": "جاري العمل",
    })

print()
print("=" * 60)
print("5. TEST PERIODIC MAINTENANCE ENDPOINTS")
print("=" * 60)
task = None
if team and "team_id" in team:
    task = test_post("/periodic-maintenance/tasks", "POST /tasks", {
        "team_id": team["team_id"],
        "task_name": "فحص خطوط المياه الرئيسي",
        "description": "فحص دوري لตรวจ التسريبات",
        "frequency": "weekly",
        "day_of_week": 0,
        "time_of_day": "08:00",
    })

test_get("/periodic-maintenance/tasks", "GET /tasks")
test_get("/periodic-maintenance/tasks/my-team", "GET /tasks/my-team")
test_get("/periodic-maintenance/tasks/upcoming?days=7", "GET /tasks/upcoming")

if task and "task_id" in task:
    tid2 = task["task_id"]
    test_get(f"/periodic-maintenance/tasks/{tid2}", f"GET /tasks/{tid2}")
    test_post(f"/periodic-maintenance/tasks/{tid2}/complete", f"POST /tasks/{tid2}/complete", {
        "notes": "تم الفحص - لا توجد تسريبات",
    })
    test_get(f"/periodic-maintenance/tasks/{tid2}/completions", f"GET /tasks/{tid2}/completions")

print()
print("=" * 60)
print("ALL TESTS DONE")
print("=" * 60)

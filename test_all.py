import requests, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

r = requests.post('http://127.0.0.1:8000/auth/login', json={'employee_number': 'EMP001', 'password': 'Yarmouk@2025'})
if r.status_code != 200:
    print('Login failed:', r.status_code)
    exit()
token = r.json()['access_token']
h = {'Authorization': 'Bearer ' + token}

print('=== Employee List ===')
r1 = requests.get('http://127.0.0.1:8000/employees/all', headers=h)
if r1.status_code == 200:
    data = r1.json()
    emps = data.get('items', data) if isinstance(data, dict) else data
    print(f'Total: {len(emps)}')
    for e in emps[:3]:
        print(f"  {e['employee_number']}: {e['full_name']}")
        print(f"    role={e.get('role_name')} roles={e.get('roles')}")
        print(f"    org={e.get('org_unit_name')} wt={e.get('work_type_name')}")
else:
    print('Error:', r1.status_code, r1.text[:200])

print('\n=== Roles ===')
r2 = requests.get('http://127.0.0.1:8000/employees/roles', headers=h)
if r2.status_code == 200:
    for item in r2.json().get('items', []):
        print(f"  {item}")
else:
    print('Error:', r2.status_code, r2.text[:200])

print('\n=== Work Types ===')
r3 = requests.get('http://127.0.0.1:8000/employees/work-types', headers=h)
if r3.status_code == 200:
    for item in r3.json().get('items', []):
        print(f"  {item}")
else:
    print('Error:', r3.status_code, r3.text[:200])

print('\n=== Org Units ===')
r4 = requests.get('http://127.0.0.1:8000/organization/units', headers=h)
if r4.status_code == 200:
    units = r4.json().get('items', [])
    print(f'Total: {len(units)}')
    for u in units[:5]:
        print(f"  {u.get('org_unit_id')}: {u.get('unit_name')} [{u.get('unit_type')}]")
else:
    print('Error:', r4.status_code, r4.text[:200])

print('\n=== Security Endpoints ===')
r5 = requests.get('http://127.0.0.1:8000/security/security-status', headers=h)
print(f'Security status: {r5.status_code}')
r6 = requests.get('http://127.0.0.1:8000/security/sessions', headers=h)
print(f'Sessions: {r6.status_code}')

print('\n=== Notifications ===')
r7 = requests.get('http://127.0.0.1:8000/notifications/', headers=h)
print(f'Notifications: {r7.status_code}')

print('\n=== Attendance ===')
r8 = requests.get('http://127.0.0.1:8000/attendance/today', headers=h)
print(f'Today attendance: {r8.status_code}')

print('\n=== Leave ===')
r9 = requests.get('http://127.0.0.1:8000/leave_requests/my', headers=h)
print(f'My leaves: {r9.status_code}')

print('\n=== Violations ===')
r10 = requests.get('http://127.0.0.1:8000/violations/me', headers=h)
print(f'My violations: {r10.status_code}')

print('\nAll done!')

import requests, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

r = requests.post('http://127.0.0.1:8000/auth/login', json={'employee_number': 'EMP001', 'password': 'Yarmouk@2025'})
if r.status_code != 200:
    print('Login failed:', r.status_code, r.text[:200])
    exit()
token = r.json()['access_token']
h = {'Authorization': 'Bearer ' + token}

print('=== Test Employee List ===')
r1 = requests.get('http://127.0.0.1:8000/employees/all', headers=h)
print('Status:', r1.status_code)
if r1.status_code == 200:
    emps = r1.json()
    print('Total employees:', len(emps))
    for e in emps[:5]:
        print(f"  {e['employee_number']}: {e['full_name']} role={e.get('role_name')} org={e.get('org_unit_name')} wt={e.get('work_type_name')}")
else:
    print('Error:', r1.text[:300])

print()
print('=== Test Bulk Import ===')
with open(r'D:\yarmouk_water_management_pro\employees_import.xlsx', 'rb') as f:
    files = {'file': ('employees.xlsx', f, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')}
    r2 = requests.post('http://127.0.0.1:8000/employees/bulk-import', headers=h, files=files)
print('Import status:', r2.status_code)
if r2.status_code == 200:
    print('Result:', r2.json())
else:
    print('Error:', r2.text[:300])

print()
print('=== Test Roles ===')
r3 = requests.get('http://127.0.0.1:8000/employees/roles', headers=h)
print('Roles:', r3.json())

print()
print('=== Test Work Types ===')
r4 = requests.get('http://127.0.0.1:8000/employees/work-types', headers=h)
print('Work Types:', r4.json())

import sqlite3, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
conn = sqlite3.connect('D:/yarmouk_water_management_pro/backend/yarmouk_water_pro.db')
c = conn.cursor()
c.execute("SELECT employee_number, full_name, job_title FROM employees WHERE employee_number LIKE 'GM%' OR employee_number LIKE 'HR%' OR employee_number LIKE 'DIR%' OR employee_number LIKE 'SEC%' OR employee_number LIKE 'WRK%' OR employee_number LIKE 'MTR%'")
for r in c.fetchall():
    print(f"  {r[0]}: {r[1]} - {r[2]}")
c.execute("SELECT COUNT(*) FROM employees")
print(f"\nTotal: {c.fetchone()[0]}")
c.execute("SELECT COUNT(*) FROM users")
print(f"Users: {c.fetchone()[0]}")
conn.close()

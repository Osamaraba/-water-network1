import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'yarmouk_water_pro.db')
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute('PRAGMA table_info(leave_requests)')
cols = [r[1] for r in cur.fetchall()]
print('Current leave_requests columns:', cols)

if 'approved_by' not in cols:
    cur.execute('ALTER TABLE leave_requests ADD COLUMN approved_by INTEGER REFERENCES employees(employee_id)')
    print('Added approved_by')

if 'approved_at' not in cols:
    cur.execute('ALTER TABLE leave_requests ADD COLUMN approved_at DATETIME')
    print('Added approved_at')

cur.execute('PRAGMA table_info(short_leaves)')
cols_s = [r[1] for r in cur.fetchall()]
print('Current short_leaves columns:', cols_s)

if 'approved_by' not in cols_s:
    cur.execute('ALTER TABLE short_leaves ADD COLUMN approved_by INTEGER REFERENCES employees(employee_id)')
    print('Added approved_by to short_leaves')

if 'approved_at' not in cols_s:
    cur.execute('ALTER TABLE short_leaves ADD COLUMN approved_at DATETIME')
    print('Added approved_at to short_leaves')

conn.commit()
print('Migration complete')
conn.close()

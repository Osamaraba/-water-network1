import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'yarmouk_water_pro.db')
if not os.path.exists(db_path):
    print(f'DB not found at {db_path}')
    exit(1)

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Drop and recreate leave_requests with new schema
cur.execute("PRAGMA foreign_keys = OFF")
cur.execute("DROP TABLE IF EXISTS leave_requests_new")
cur.execute('''
CREATE TABLE leave_requests_new (
    request_id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    leave_type VARCHAR(20) NOT NULL,
    leave_type_custom VARCHAR(100),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reviewed_by INTEGER,
    review_note TEXT,
    reviewed_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
)
''')

# Try to copy old data
try:
    cur.execute('''
    INSERT INTO leave_requests_new (request_id, employee_id, leave_type, start_date, end_date, reason, status, reviewed_by, review_note, reviewed_at, created_at)
    SELECT request_id, employee_id, leave_type, date(start_time), date(end_time), reason, status, reviewed_by, review_note, reviewed_at, created_at
    FROM leave_requests
    ''')
    print('Migrated existing leave_requests data')
except Exception as e:
    print(f'No data to migrate: {e}')

# Replace old table
cur.execute("DROP TABLE IF EXISTS leave_requests")
cur.execute("ALTER TABLE leave_requests_new RENAME TO leave_requests")

# Create short_leaves table
cur.execute("DROP TABLE IF EXISTS short_leaves")
cur.execute('''
CREATE TABLE short_leaves (
    short_leave_id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    leave_kind VARCHAR(20) NOT NULL,
    outing_date DATE NOT NULL,
    departure_time TIME NOT NULL,
    return_time TIME NOT NULL,
    destination VARCHAR(200),
    reason TEXT,
    tracking_required BOOLEAN NOT NULL DEFAULT 0,
    tracking_session_id INTEGER,
    tracking_acknowledged BOOLEAN NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reviewed_by INTEGER,
    review_note TEXT,
    reviewed_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
)
''')
print('Created short_leaves table')

cur.execute("PRAGMA foreign_keys = ON")
conn.commit()
print('Migration complete')
conn.close()

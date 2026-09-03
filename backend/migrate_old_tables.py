import sqlite3
conn = sqlite3.connect('yarmouk_water.db')
cursor = conn.cursor()

cursor.execute('''CREATE TABLE IF NOT EXISTS complaints (
    complaint_id INTEGER PRIMARY KEY AUTOINCREMENT,
    complaint_number VARCHAR(50),
    description TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reported_by INTEGER REFERENCES employees(employee_id),
    latitude REAL,
    longitude REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)''')

cursor.execute('''CREATE TABLE IF NOT EXISTS maintenance_assignments (
    assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    complaint_id INTEGER NOT NULL REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    technician_id INTEGER REFERENCES employees(employee_id),
    status VARCHAR(20) NOT NULL DEFAULT 'assigned',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)''')

cursor.execute('''CREATE TABLE IF NOT EXISTS maintenance_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    complaint_id INTEGER NOT NULL REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)''')

cursor.execute('''CREATE TABLE IF NOT EXISTS maintenance_photos (
    photo_id INTEGER PRIMARY KEY AUTOINCREMENT,
    complaint_id INTEGER NOT NULL REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    photo_url VARCHAR(500) NOT NULL,
    caption VARCHAR(200),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)''')

conn.commit()
conn.close()
print('Old tables created successfully')

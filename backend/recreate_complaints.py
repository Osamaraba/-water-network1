import sqlite3
conn = sqlite3.connect('yarmouk_water.db')
cursor = conn.cursor()

# Drop and recreate
cursor.execute("DROP TABLE IF EXISTS maintenance_complaints")
cursor.execute('''CREATE TABLE maintenance_complaints (
    complaint_id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_name VARCHAR(100),
    customer_phone VARCHAR(20),
    description TEXT NOT NULL,
    category VARCHAR(30) NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    governorate VARCHAR(50) NOT NULL,
    district VARCHAR(50),
    neighborhood VARCHAR(50),
    team_id INTEGER REFERENCES maintenance_teams(team_id),
    assigned_to INTEGER REFERENCES employees(employee_id),
    latitude REAL,
    longitude REAL,
    photo_url VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    assigned_at DATETIME,
    started_at DATETIME,
    resolved_at DATETIME,
    resolution_notes TEXT,
    customer_satisfaction INTEGER,
    created_by INTEGER REFERENCES employees(employee_id)
)''')

# Verify
cursor.execute("PRAGMA table_info(maintenance_complaints)")
cols = [c[1] for c in cursor.fetchall()]
print("Columns:", cols)
print("Count:", len(cols))

conn.commit()
conn.close()
print("Table recreated successfully")

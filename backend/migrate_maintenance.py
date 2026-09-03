import sqlite3

conn = sqlite3.connect('yarmouk_water.db')
cursor = conn.cursor()

# Create maintenance_teams table
cursor.execute('''
CREATE TABLE IF NOT EXISTS maintenance_teams (
    team_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_name VARCHAR(100) NOT NULL,
    team_type VARCHAR(30) NOT NULL,
    governorate VARCHAR(50) NOT NULL,
    team_leader_id INTEGER REFERENCES employees(employee_id),
    max_active_tasks INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''')

# Create team_members table
cursor.execute('''
CREATE TABLE IF NOT EXISTS team_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id INTEGER NOT NULL REFERENCES maintenance_teams(team_id) ON DELETE CASCADE,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'technician',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''')

# Create maintenance_complaints table
cursor.execute('''
CREATE TABLE IF NOT EXISTS maintenance_complaints (
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
)
''')

# Create periodic_maintenance_tasks table
cursor.execute('''
CREATE TABLE IF NOT EXISTS periodic_maintenance_tasks (
    task_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id INTEGER NOT NULL REFERENCES maintenance_teams(team_id) ON DELETE CASCADE,
    task_name VARCHAR(200) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) NOT NULL,
    day_of_week INTEGER,
    day_of_month INTEGER,
    time_of_day TIME DEFAULT '08:00:00',
    is_active BOOLEAN DEFAULT 1,
    last_completed DATE,
    next_due DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''')

# Create periodic_task_completions table
cursor.execute('''
CREATE TABLE IF NOT EXISTS periodic_task_completions (
    completion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL REFERENCES periodic_maintenance_tasks(task_id) ON DELETE CASCADE,
    employee_id INTEGER REFERENCES employees(employee_id),
    completed_date DATE NOT NULL,
    notes TEXT,
    photo_url VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''')

conn.commit()
conn.close()
print('Migration completed successfully!')

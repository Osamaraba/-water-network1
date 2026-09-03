import sqlite3

conn = sqlite3.connect('yarmouk_water.db')
cursor = conn.cursor()

cursor.execute('PRAGMA table_info(violation_notices)')
existing = [col[1] for col in cursor.fetchall()]
print('Existing columns:', existing)

columns_to_add = [
    ('status', "VARCHAR(20) DEFAULT 'pending'"),
    ('acknowledged', 'BOOLEAN DEFAULT 0'),
    ('acknowledged_at', 'DATETIME'),
    ('employee_response', 'TEXT'),
    ('employee_response_at', 'DATETIME'),
    ('hr_reviewed', 'BOOLEAN DEFAULT 0'),
    ('hr_reviewed_at', 'DATETIME'),
    ('hr_reviewer_id', 'INTEGER'),
    ('hr_notes', 'TEXT'),
]

for col_name, col_def in columns_to_add:
    if col_name not in existing:
        try:
            cursor.execute(f'ALTER TABLE violation_notices ADD COLUMN {col_name} {col_def}')
            print(f'Added: {col_name}')
        except Exception as e:
            print(f'Error adding {col_name}: {e}')
    else:
        print(f'Already exists: {col_name}')

conn.commit()
conn.close()
print('Migration completed!')

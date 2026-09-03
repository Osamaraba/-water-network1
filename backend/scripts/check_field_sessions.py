import sqlite3
conn = sqlite3.connect('yarmouk_water_pro.db')
cursor = conn.execute("PRAGMA table_info(field_tracking_sessions)")
for row in cursor.fetchall():
    print(row)
conn.close()

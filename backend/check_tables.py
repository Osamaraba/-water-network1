import sqlite3
conn = sqlite3.connect('yarmouk_water.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cursor.fetchall()]
print("All tables:", tables)

for t in tables:
    if 'complaint' in t.lower() or 'maintenance' in t.lower():
        cursor.execute(f"PRAGMA table_info({t})")
        cols = [c[1] for c in cursor.fetchall()]
        print(f"\n{t}: {cols}")
        cursor.execute(f"SELECT COUNT(*) FROM {t}")
        count = cursor.fetchone()[0]
        print(f"  rows: {count}")
conn.close()

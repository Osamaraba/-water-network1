import sqlite3

for db_name in ['yarmouk.db', 'yarmouk_water_pro.db']:
    try:
        conn = sqlite3.connect(db_name)
        cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"{db_name}: {len(tables)} tables -> {tables[:5]}...")
        conn.close()
    except Exception as e:
        print(f"{db_name}: error - {e}")

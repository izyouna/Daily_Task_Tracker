import sqlite3

conn = sqlite3.connect("daily_task.db")
cursor = conn.cursor()

# List all tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = cursor.fetchall()
print("=" * 50)
print("  DATABASE: daily_task.db (SQLite)")
print("=" * 50)

for (table_name,) in tables:
    print(f"\n--- Table: {table_name} ---")
    cols = cursor.execute(f"PRAGMA table_info({table_name})").fetchall()
    for col in cols:
        pk = " [PK]" if col[5] else ""
        nullable = "" if col[3] else " (nullable)"
        print(f"  {col[1]:20s} {col[2]:15s}{pk}{nullable}")

    # Show row count
    count = cursor.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
    print(f"  >> Rows: {count}")

conn.close()

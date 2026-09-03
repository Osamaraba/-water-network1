"""
Database Backup Script for Yarmouk Water Management Pro
Supports SQLite and PostgreSQL backups.

Usage:
    python scripts/backup_database.py
    python scripts/backup_database.py --type postgresql
    python scripts/backup_database.py --output /custom/backup/path
"""
import os
import sys
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings


def backup_sqlite(output_dir: str = "backups") -> str:
    """Backup SQLite database."""
    db_path = settings.DATABASE_URL.replace("sqlite+aiosqlite:///", "")
    
    if not os.path.exists(db_path):
        print(f"Error: SQLite database not found at {db_path}")
        return None

    os.makedirs(output_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_filename = f"yarmouk_backup_{timestamp}.db"
    backup_path = os.path.join(output_dir, backup_filename)
    
    shutil.copy2(db_path, backup_path)
    print(f"SQLite backup created: {backup_path}")
    return backup_path


def backup_postgresql(output_dir: str = "backups") -> str:
    """Backup PostgreSQL database using pg_dump."""
    db_url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "")
    
    # Parse connection details
    if "@" in db_url:
        user_pass, host_db = db_url.split("@", 1)
        if ":" in user_pass:
            user, password = user_pass.split(":", 1)
        else:
            user = user_pass
            password = ""
        
        if "/" in host_db:
            host_port, database = host_db.split("/", 1)
            if ":" in host_port:
                host, port = host_port.split(":", 1)
            else:
                host = host_port
                port = "5432"
        else:
            host = host_db
            port = "5432"
            database = "yarmouk_pro"
    else:
        print("Error: Could not parse PostgreSQL connection string")
        return None

    os.makedirs(output_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_filename = f"yarmouk_backup_{timestamp}.sql"
    backup_path = os.path.join(output_dir, backup_filename)
    
    env = os.environ.copy()
    if password:
        env["PGPASSWORD"] = password
    
    try:
        cmd = [
            "pg_dump",
            "-h", host,
            "-p", port,
            "-U", user,
            "-d", database,
            "-F", "c",  # Custom format
            "-f", backup_path
        ]
        subprocess.run(cmd, env=env, check=True)
        print(f"PostgreSQL backup created: {backup_path}")
        return backup_path
    except FileNotFoundError:
        print("Error: pg_dump not found. Install PostgreSQL client tools.")
        return None
    except subprocess.CalledProcessError as e:
        print(f"Error during backup: {e}")
        return None


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Backup Yarmouk database")
    parser.add_argument("--type", choices=["sqlite", "postgresql"], default=None,
                        help="Database type (auto-detected from config if not specified)")
    parser.add_argument("--output", default="backups", help="Output directory")
    args = parser.parse_args()
    
    db_type = args.type
    if db_type is None:
        if settings.is_sqlite:
            db_type = "sqlite"
        else:
            db_type = "postgresql"
    
    print(f"Database type: {db_type}")
    print(f"Database URL: {settings.DATABASE_URL[:50]}...")
    
    if db_type == "sqlite":
        result = backup_sqlite(args.output)
    else:
        result = backup_postgresql(args.output)
    
    if result:
        print(f"\nBackup completed successfully!")
        print(f"File: {result}")
        file_size = os.path.getsize(result) / 1024
        print(f"Size: {file_size:.1f} KB")
    else:
        print("\nBackup failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()

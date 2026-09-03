"""
Database Indexes for SQLite (Development)
Yarmouk Water Management Pro
Run: python scripts/create_sqlite_indexes.py
"""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "yarmouk_water_pro.db")

INDEXES = [
    # Employee indexes
    "CREATE INDEX IF NOT EXISTS idx_employee_org_active ON employees(org_unit_id, is_active)",
    "CREATE INDEX IF NOT EXISTS idx_employee_name ON employees(full_name)",
    "CREATE INDEX IF NOT EXISTS idx_employee_number ON employees(employee_number)",
    
    # Attendance indexes
    "CREATE INDEX IF NOT EXISTS idx_attendance_date_status ON attendance(check_in_time, status)",
    "CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance(employee_id, check_in_time DESC)",
    "CREATE INDEX IF NOT EXISTS idx_attendance_late ON attendance(status, check_in_time) WHERE status = 'late'",
    
    # Leave request indexes
    "CREATE INDEX IF NOT EXISTS idx_leave_employee_dates ON leave_requests(employee_id, start_date, end_date)",
    "CREATE INDEX IF NOT EXISTS idx_leave_pending ON leave_requests(status, created_at DESC) WHERE status = 'pending'",
    "CREATE INDEX IF NOT EXISTS idx_leave_type_dates ON leave_requests(leave_type, start_date)",
    
    # Overtime indexes
    "CREATE INDEX IF NOT EXISTS idx_overtime_pending ON overtime_work_requests(status, created_at DESC) WHERE status = 'pending'",
    "CREATE INDEX IF NOT EXISTS idx_overtime_employee_date ON overtime_work_requests(employee_id, created_at DESC)",
    
    # Notification indexes
    "CREATE INDEX IF NOT EXISTS idx_notification_unread ON notifications(employee_id, is_read) WHERE is_read = 0",
    "CREATE INDEX IF NOT EXISTS idx_notification_date ON notifications(created_at DESC)",
    
    # Audit log indexes
    "CREATE INDEX IF NOT EXISTS idx_audit_date ON audit_logs(created_at DESC)",
    "CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs(action, created_at DESC)",
    
    # Maintenance indexes
    "CREATE INDEX IF NOT EXISTS idx_maintenance_pending ON maintenance_complaints(status, created_at DESC) WHERE status = 'pending'",
    
    # GPS tracking indexes
    "CREATE INDEX IF NOT EXISTS idx_field_session_active ON field_tracking_sessions(employee_id, ended_at) WHERE ended_at IS NULL",
    "CREATE INDEX IF NOT EXISTS idx_field_point_session ON field_tracking_points(session_id, recorded_at)",
]


def create_indexes():
    if not os.path.exists(DB_PATH):
        print(f"Database not found: {DB_PATH}")
        return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    created = 0
    for sql in INDEXES:
        try:
            cursor.execute(sql)
            created += 1
        except Exception as e:
            print(f"Error: {e}")
    
    conn.commit()
    conn.close()
    print(f"Created {created}/{len(INDEXES)} indexes")


if __name__ == "__main__":
    create_indexes()

-- =============================================================================
-- Database Indexes for Performance Optimization
-- Yarmouk Water Management Pro
-- =============================================================================
-- Run this script after initial migration for production PostgreSQL databases
-- These indexes optimize common query patterns
-- =============================================================================

-- =============================================================================
-- EMPLOYEE INDEXES
-- =============================================================================
-- Composite index for employee lookups by org unit and active status
CREATE INDEX IF NOT EXISTS idx_employee_org_active 
    ON employees(org_unit_id, is_active);

-- Index for employee search by name
CREATE INDEX IF NOT EXISTS idx_employee_name 
    ON employees(full_name);

-- =============================================================================
-- ATTENDANCE INDEXES
-- =============================================================================
-- Composite index for daily attendance queries
CREATE INDEX IF NOT EXISTS idx_attendance_date_status 
    ON attendance(check_in_time, status);

-- Composite index for employee attendance history
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date 
    ON attendance(employee_id, check_in_time DESC);

-- Index for late attendance reports
CREATE INDEX IF NOT EXISTS idx_attendance_late 
    ON attendance(status, check_in_time) 
    WHERE status = 'late';

-- =============================================================================
-- LEAVE REQUEST INDEXES
-- =============================================================================
-- Composite index for leave balance calculations
CREATE INDEX IF NOT EXISTS idx_leave_employee_dates 
    ON leave_requests(employee_id, start_date, end_date);

-- Index for pending leave approvals
CREATE INDEX IF NOT EXISTS idx_leave_pending 
    ON leave_requests(status, created_at DESC) 
    WHERE status = 'pending';

-- Index for leave type reporting
CREATE INDEX IF NOT EXISTS idx_leave_type_dates 
    ON leave_requests(leave_type, start_date);

-- =============================================================================
-- OVERTIME WORK INDEXES
-- =============================================================================
-- Index for pending overtime approvals
CREATE INDEX IF NOT EXISTS idx_overtime_pending 
    ON overtime_work_requests(status, created_at DESC) 
    WHERE status = 'pending';

-- Composite index for overtime reporting
CREATE INDEX IF NOT EXISTS idx_overtime_employee_date 
    ON overtime_work_requests(employee_id, created_at DESC);

-- =============================================================================
-- REPORT INDEXES
-- =============================================================================
-- Index for report date range queries
CREATE INDEX IF NOT EXISTS idx_report_date 
    ON reports(created_at DESC);

-- Composite index for report type and status
CREATE INDEX IF NOT EXISTS idx_report_type_status 
    ON reports(report_type, status);

-- =============================================================================
-- NOTIFICATION INDEXES
-- =============================================================================
-- Index for unread notifications
CREATE INDEX IF NOT EXISTS idx_notification_unread 
    ON notifications(employee_id, is_read) 
    WHERE is_read = false;

-- Index for notification date sorting
CREATE INDEX IF NOT EXISTS idx_notification_date 
    ON notifications(created_at DESC);

-- =============================================================================
-- AUDIT LOG INDEXES
-- =============================================================================
-- Index for audit log date range queries
CREATE INDEX IF NOT EXISTS idx_audit_date 
    ON audit_logs(created_at DESC);

-- Index for audit action filtering
CREATE INDEX IF NOT EXISTS idx_audit_action 
    ON audit_logs(action, created_at DESC);

-- =============================================================================
-- MAINTENANCE COMPLAINT INDEXES
-- =============================================================================
-- Index for pending maintenance complaints
CREATE INDEX IF NOT EXISTS idx_maintenance_pending 
    ON maintenance_complaints(status, created_at DESC) 
    WHERE status = 'pending';

-- =============================================================================
-- GPS/FIELD TRACKING INDEXES
-- =============================================================================
-- Index for active field tracking sessions
CREATE INDEX IF NOT EXISTS idx_field_session_active 
    ON field_tracking_sessions(employee_id, ended_at) 
    WHERE ended_at IS NULL;

-- Index for field tracking points by session
CREATE INDEX IF NOT EXISTS idx_field_point_session 
    ON field_tracking_points(session_id, recorded_at);

-- =============================================================================
-- PERFORMANCE NOTES
-- =============================================================================
-- 1. These indexes are optimized for PostgreSQL. SQLite will ignore some indexes.
-- 2. Monitor index usage with: SELECT * FROM pg_stat_user_indexes;
-- 3. Remove unused indexes to improve write performance.
-- 4. Consider partial indexes for frequently filtered queries (e.g., WHERE status = 'pending')
-- 5. For large tables (>1M rows), consider table partitioning by date.

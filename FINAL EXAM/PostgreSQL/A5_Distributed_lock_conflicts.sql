A5: Distributed Lock Conflict & Diagnosis (no extra rows)
-- ==========================================================

-- This script demonstrates lock conflicts in a distributed environment
-- Run these commands in separate sessions

-- ============================================
-- SESSION 1 (Node_A): Acquire lock on a fine
-- ============================================
-- Run this first and keep the transaction open

BEGIN;

-- Update a fine record and hold the lock
UPDATE Fine 
SET amount = amount + 5000
WHERE fine_id = 1;

-- Keep this transaction open (don't commit yet)
SELECT 
    fine_id,
    amount,
    status,
    pg_backend_pid() as session_pid,
    'Lock acquired - transaction open' as lock_status
FROM Fine 
WHERE fine_id = 1;

-- DO NOT COMMIT YET - keep session open

-- ============================================
-- SESSION 2 (Node_B or another connection): Try to update same row
-- ============================================
-- Run this in a separate terminal/session while Session 1 is still open

BEGIN;

-- This will block waiting for Session 1's lock
UPDATE Fine 
SET status = 'PAID'
WHERE fine_id = 1;

-- This statement will wait...

-- ============================================
-- SESSION 3 (Monitoring): Diagnose the lock conflict
-- ============================================
-- Run this in a third session to see the blocking

-- Query 1: Show blocking and waiting sessions
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement,
    blocked_activity.application_name AS blocked_application,
    blocking_activity.application_name AS blocking_application
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Query 2: Detailed lock information
SELECT 
    l.locktype,
    l.database,
    l.relation::regclass AS table_name,
    l.page,
    l.tuple,
    l.virtualxid,
    l.transactionid,
    l.mode,
    l.granted,
    a.pid,
    a.usename,
    a.application_name,
    a.client_addr,
    a.query_start,
    a.state,
    a.wait_event_type,
    a.wait_event
FROM pg_locks l
LEFT JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.relation = 'fine'::regclass
ORDER BY l.granted, a.query_start;

-- Query 3: Simple blocking tree
SELECT 
    activity.pid,
    activity.usename,
    activity.state,
    activity.query,
    activity.wait_event_type,
    activity.wait_event,
    blocking.pid AS blocking_pid
FROM pg_stat_activity activity
LEFT JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid))
WHERE activity.pid != pg_backend_pid()
  AND activity.state != 'idle'
ORDER BY activity.pid;

-- ============================================
-- RESOLUTION: Go back to SESSION 1 and commit
-- ============================================
-- In Session 1, run:
COMMIT;

-- Now Session 2 should complete automatically

-- ============================================
-- SESSION 2: Verify completion
-- ============================================
-- After Session 1 commits, Session 2 should complete
-- Then commit Session 2:
COMMIT;

-- ============================================
-- VERIFICATION: Check final state
-- ============================================
SELECT 
    fine_id,
    amount,
    status,
    'Lock released - both updates applied' as result
FROM Fine 
WHERE fine_id = 1;

-- Verify no active locks remain
SELECT 
    COUNT(*) as active_locks,
    CASE 
        WHEN COUNT(*) = 0 THEN 'All locks released'
        ELSE 'Some locks still active'
    END as lock_status
FROM pg_locks 
WHERE relation = 'fine'::regclass;

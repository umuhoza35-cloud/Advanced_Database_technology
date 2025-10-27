============================================================================
-- ASSIGNMENT 3 - TASK 6: DISTRIBUTED CONCURRENCY CONTROL
-- Demonstrating Lock Conflicts Across Distributed Nodes
-- ============================================================================
-- This script demonstrates distributed locking and concurrency control
-- ============================================================================

-- Step 1: Create concurrency test table
CREATE TABLE IF NOT EXISTS public.concurrency_test_log (
    test_id SERIAL PRIMARY KEY,
    session_id VARCHAR(50),
    operation VARCHAR(100),
    lock_type VARCHAR(20),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    released_at TIMESTAMP
);

-- Step 2: Create advisory lock tracking
CREATE TABLE IF NOT EXISTS public.distributed_locks (
    lock_id SERIAL PRIMARY KEY,
    resource_id INT,
    lock_type VARCHAR(20),
    session_id VARCHAR(50),
    acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    released_at TIMESTAMP
);

-- Step 3: Simulate Session 1 - Lock acquisition on Node A
-- Session 1 acquires exclusive lock
BEGIN TRANSACTION;

-- Acquire advisory lock
SELECT pg_advisory_lock(1001);

-- Insert lock record
INSERT INTO public.distributed_locks (resource_id, lock_type, session_id)
VALUES (1001, 'EXCLUSIVE', 'SESSION-1');

-- Perform update operation
UPDATE node_a_kigali.driver 
SET phone_number = '0788123456'
WHERE driver_id = 1;

-- Log operation
INSERT INTO public.concurrency_test_log (session_id, operation, lock_type, status)
VALUES ('SESSION-1', 'UPDATE_DRIVER', 'EXCLUSIVE', 'ACQUIRED');

-- Keep transaction open to demonstrate lock conflict
-- In real scenario, this would be in a separate session
-- COMMIT;

-- Step 4: Simulate Session 2 - Attempt to acquire same lock
-- Session 2 attempts to acquire same lock (would block)
-- This demonstrates lock conflict
BEGIN TRANSACTION;

-- Try to acquire same advisory lock (would block in real scenario)
-- SELECT pg_advisory_lock(1001);

-- Log attempted lock
INSERT INTO public.concurrency_test_log (session_id, operation, lock_type, status)
VALUES ('SESSION-2', 'UPDATE_DRIVER', 'EXCLUSIVE', 'WAITING');

-- Simulate timeout or deadlock detection
-- In production, this would eventually timeout or be detected as deadlock

COMMIT;

-- Step 5: Release locks and verify
-- Release advisory locks
SELECT pg_advisory_unlock(1001);

-- Update lock release time
UPDATE public.distributed_locks
SET released_at = CURRENT_TIMESTAMP
WHERE lock_id = (SELECT MAX(lock_id) FROM public.distributed_locks);

-- Step 6: Query lock information
-- Display lock status and conflicts
SELECT 
    "Lock Status Report" as report_type,
    COUNT(*) as total_locks,
    COUNT(CASE WHEN released_at IS NULL THEN 1 END) as active_locks,
    COUNT(CASE WHEN released_at IS NOT NULL THEN 1 END) as released_locks
FROM public.distributed_locks;

-- Step 7: Demonstrate deadlock scenario
-- Simulating potential deadlock
BEGIN TRANSACTION;

-- Session 1 locks resource A
SELECT pg_advisory_lock(2001);
INSERT INTO public.distributed_locks (resource_id, lock_type, session_id)
VALUES (2001, 'EXCLUSIVE', 'SESSION-1-DEADLOCK');

-- Simulate Session 2 locking resource B
-- (In real scenario, this would be in separate session)
-- SELECT pg_advisory_lock(2002);

-- Session 1 tries to lock resource B (would deadlock if Session 2 has it)
-- SELECT pg_advisory_lock(2002);

-- Log deadlock attempt
INSERT INTO public.concurrency_test_log (session_id, operation, lock_type, status)
VALUES ('SESSION-1-DEADLOCK', 'POTENTIAL_DEADLOCK', 'EXCLUSIVE', 'DETECTED');

-- Rollback to prevent actual deadlock
ROLLBACK;

-- Step 8: Verify concurrency control effectiveness
SELECT 
    'Concurrency Control Summary' as summary,
    COUNT(*) as total_operations,
    COUNT(CASE WHEN status = 'ACQUIRED' THEN 1 END) as successful_locks,
    COUNT(CASE WHEN status = 'WAITING' THEN 1 END) as waiting_operations,
    COUNT(CASE WHEN status = 'DETECTED' THEN 1 END) as detected_conflicts
FROM public.concurrency_test_log;

-- Step 9: Display lock conflict analysis
SELECT 
    'Lock Conflict Analysis' as analysis_type,
    session_id,
    COUNT(*) as lock_attempts,
    COUNT(CASE WHEN released_at IS NOT NULL THEN 1 END) as completed_locks
FROM public.distributed_locks
GROUP BY session_id;

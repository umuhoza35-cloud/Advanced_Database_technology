-- ============================================================================
-- ASSIGNMENT 3 - TASK 5: DISTRIBUTED ROLLBACK & RECOVERY
-- Simulating Network Failure and Recovery Procedures
-- ============================================================================
-- This script demonstrates recovery from distributed transaction failures
-- ============================================================================

-- Step 1: Create recovery tracking table
CREATE TABLE IF NOT EXISTS public.transaction_recovery_log (
    recovery_id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(50),
    failure_type VARCHAR(50),
    recovery_action VARCHAR(100),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- Step 2: Simulate network failure during distributed transaction
-- Simulating transaction failure scenario
BEGIN TRANSACTION;

-- Insert data into Node A
INSERT INTO node_a_kigali.driver (first_name, last_name, license_number, address)
VALUES ('Recovery', 'Test', 'DL-RECOVERY-001', 'Kigali');

-- Simulate network failure by raising an exception
-- This would normally be a network timeout or connection error
SAVEPOINT before_failure;

-- Attempt operation that might fail
INSERT INTO node_a_kigali.violation (officer_id, driver_id, vehicle_id, violation_type, violation_date, location, severity_level)
SELECT 1, driver_id, 1, 'Test Violation', CURRENT_DATE, 'Kigali Central', 'Minor'
FROM node_a_kigali.driver
WHERE license_number = 'DL-RECOVERY-001'
LIMIT 1;

-- Log recovery attempt
INSERT INTO public.transaction_recovery_log (transaction_id, failure_type, recovery_action, status)
VALUES ('TXN-RECOVERY-001', 'NETWORK_FAILURE', 'ROLLBACK_TO_SAVEPOINT', 'INITIATED');

-- Rollback to savepoint
ROLLBACK TO SAVEPOINT before_failure;

-- Complete the transaction
COMMIT;

-- Step 3: Verify recovery state
SELECT * FROM public.transaction_recovery_log WHERE transaction_id = 'TXN-RECOVERY-001';

-- Step 4: Query unresolved transactions (simulated)
-- Checking for unresolved transactions
SELECT 
    'Unresolved Transactions' as check_type,
    COUNT(*) as unresolved_count
FROM public.transaction_recovery_log
WHERE status IN ('INITIATED', 'PENDING', 'FAILED');

-- Step 5: Implement recovery procedure
-- Recovery procedure for failed transactions
DO $$
DECLARE
    v_recovery_id INT;
    v_transaction_id VARCHAR(50);
BEGIN
    -- Find unresolved transactions
    FOR v_recovery_id, v_transaction_id IN
        SELECT recovery_id, transaction_id 
        FROM public.transaction_recovery_log 
        WHERE status = 'INITIATED'
    LOOP
        -- Attempt recovery
        BEGIN
            -- Update recovery status
            UPDATE public.transaction_recovery_log
            SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP
            WHERE recovery_id = v_recovery_id;
            
            RAISE NOTICE 'Transaction % recovered successfully', v_transaction_id;
        EXCEPTION WHEN OTHERS THEN
            -- Log recovery failure
            UPDATE public.transaction_recovery_log
            SET status = 'FAILED', resolved_at = CURRENT_TIMESTAMP
            WHERE recovery_id = v_recovery_id;
            
            RAISE NOTICE 'Recovery failed for transaction %: %', v_transaction_id, SQLERRM;
        END;
    END LOOP;
END $$;

-- Step 6: Verify recovery completion
SELECT 
    'Recovery Status Summary' as summary_type,
    status,
    COUNT(*) as count
FROM public.transaction_recovery_log
GROUP BY status;

-- Step 7: Simulate cascading rollback across nodes
-- Cascading rollback demonstration
BEGIN TRANSACTION;

-- Create savepoint for Node A operations
SAVEPOINT node_a_operations;

INSERT INTO node_a_kigali.driver (first_name, last_name, license_number, address)
VALUES ('Cascade', 'Test', 'DL-CASCADE-001', 'Kigali');

-- Create savepoint for Node B operations
SAVEPOINT node_b_operations;

INSERT INTO node_b_regions.driver (first_name, last_name, license_number, address)
VALUES ('Cascade', 'Test', 'DL-CASCADE-002', 'Butare');

-- Simulate failure and rollback all operations
ROLLBACK TO SAVEPOINT node_a_operations;

-- Log cascading rollback
INSERT INTO public.transaction_recovery_log (transaction_id, failure_type, recovery_action, status)
VALUES ('TXN-CASCADE-001', 'CASCADING_FAILURE', 'ROLLBACK_ALL_NODES', 'COMPLETED');

COMMIT;

-- Step 8: Final recovery verification
SELECT 
    'Final Recovery Report' as report_type,
    COUNT(*) as total_recovery_attempts,
    COUNT(CASE WHEN status = 'RESOLVED' THEN 1 END) as successful_recoveries,
    COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_recoveries
FROM public.transaction_recovery_log;

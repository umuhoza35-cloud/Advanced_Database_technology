-- Step 1: Create a test transaction table for tracking
CREATE TABLE IF NOT EXISTS public.distributed_transaction_log (
    transaction_id VARCHAR(50) PRIMARY KEY,
    status VARCHAR(20),
    node_a_status VARCHAR(20),
    node_b_status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Step 2: Simulate 2PC - Phase 1: Prepare
-- Phase 1 - Prepare phase of 2PC
BEGIN TRANSACTION;

-- Insert test data into Node A
INSERT INTO node_a_kigali.driver (first_name, last_name, license_number, address)
VALUES ('John', 'Doe', 'DL-2PC-001', 'Kigali, Rwanda');

-- Insert test data into Node B (simulated via local schema)
INSERT INTO node_b_regions.driver (first_name, last_name, license_number, address)
VALUES ('Jane', 'Smith', 'DL-2PC-002', 'Butare, Rwanda');

-- Log the transaction
INSERT INTO public.distributed_transaction_log (transaction_id, status, node_a_status, node_b_status)
VALUES ('TXN-2PC-001', 'PREPARED', 'PREPARED', 'PREPARED');

-- Step 3: Phase 2: Commit
-- Phase 2 - Commit phase of 2PC
COMMIT;

-- Verify transaction completion
SELECT * FROM public.distributed_transaction_log WHERE transaction_id = 'TXN-2PC-001';

-- Step 4: Verify data was committed to both nodes
SELECT 'Node A - Kigali' as node, COUNT(*) as driver_count FROM node_a_kigali.driver
UNION ALL
SELECT 'Node B - Regions' as node, COUNT(*) as driver_count FROM node_b_regions.driver;

-- Step 5: Simulate 2PC with rollback scenario
-- Demonstrates rollback in 2PC
BEGIN TRANSACTION;

INSERT INTO node_a_kigali.driver (first_name, last_name, license_number, address)
VALUES ('Test', 'Rollback', 'DL-2PC-ROLLBACK', 'Test Location');

-- Simulate error condition
ROLLBACK;

-- Verify rollback - data should not be committed
SELECT COUNT(*) as drivers_after_rollback FROM node_a_kigali.driver 
WHERE license_number = 'DL-2PC-ROLLBACK';

-- Step 6: Complex 2PC scenario with multiple operations
-- Multi-operation 2PC transaction
BEGIN TRANSACTION;

-- Operation 1: Insert violation in Node A
INSERT INTO node_a_kigali.violation (officer_id, driver_id, vehicle_id, violation_type, violation_date, location, severity_level)
SELECT 1, 1, 1, 'Speeding', CURRENT_DATE, 'Kigali Central', 'Moderate'
WHERE EXISTS (SELECT 1 FROM node_a_kigali.driver LIMIT 1);

-- Operation 2: Insert fine in Node A
INSERT INTO node_a_kigali.fine (violation_id, amount_rwf, fine_date, due_date, status)
SELECT violation_id, 50000, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'Unpaid'
FROM node_a_kigali.violation
WHERE violation_type = 'Speeding'
LIMIT 1;

-- Log transaction state
INSERT INTO public.distributed_transaction_log (transaction_id, status, node_a_status, node_b_status)
VALUES ('TXN-2PC-COMPLEX', 'COMMITTED', 'COMMITTED', 'COMMITTED')
ON CONFLICT (transaction_id) DO UPDATE SET status = 'COMMITTED';

COMMIT;

-- Step 7: Query transaction log to verify 2PC execution
SELECT 
    transaction_id,
    status,
    node_a_status,
    node_b_status,
    created_at,
    completed_at
FROM public.distributed_transaction_log
ORDER BY created_at DESC;

-- Step 8: Verify atomicity - all operations succeeded or all failed
SELECT 
    'Atomicity Verification' as verification_type,
    COUNT(DISTINCT transaction_id) as total_transactions,
    COUNT(CASE WHEN status = 'COMMITTED' THEN 1 END) as committed_transactions,
    COUNT(CASE WHEN status = 'PREPARED' THEN 1 END) as prepared_transactions
FROM public.distributed_transaction_log;

 select*from licence_number;

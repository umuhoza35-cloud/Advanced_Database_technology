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

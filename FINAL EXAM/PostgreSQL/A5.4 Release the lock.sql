ELECT 
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

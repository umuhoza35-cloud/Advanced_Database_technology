SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'No pending transactions - System consistent'
        ELSE 'WARNING: ' || COUNT(*) || ' pending transactions found'
    END as status
FROM pg_prepared_xacts;

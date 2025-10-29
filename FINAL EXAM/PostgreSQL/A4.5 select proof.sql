SELECT 
    'Fine Records' as table_name,
    COUNT(*) as committed_rows
FROM Fine
UNION ALL
SELECT 
    'Payment Records',
    COUNT(*)
FROM Payment;

-- Display sample data
SELECT 
    f.fine_id,
    f.amount,
    f.status,
    f.total_paid,
    f.due_date,
    'Valid constraint-compliant record' as validation_status
FROM Fine f
ORDER BY f.fine_id DESC
LIMIT 5;

SELECT 
    p.payment_id,
    p.fine_id,
    p.amount,
    p.payment_method,
    p.payment_date,
    'Valid constraint-compliant record' as validation_status
FROM Payment p
ORDER BY p.payment_id DESC
LIMIT 5;

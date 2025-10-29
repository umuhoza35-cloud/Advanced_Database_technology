SELECT 
    'Total Violations' as metric,
    COUNT(*) as value
FROM Violation_A
UNION ALL
SELECT 
    'Violations with Region',
    COUNT(*)
FROM Violation_A
WHERE region IS NOT NULL;

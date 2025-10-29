SELECT 
    'PARALLEL' as execution_mode,
    violation_type,
    COUNT(*) as violation_count,
    ROUND(AVG(recorded_speed), 2) as avg_speed,
    COUNT(DISTINCT plate_number) as unique_vehicles
FROM Violation_ALL
WHERE recorded_speed IS NOT NULL
GROUP BY violation_type
ORDER BY violation_count DESC;

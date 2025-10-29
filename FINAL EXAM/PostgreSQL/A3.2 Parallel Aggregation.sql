-- STEP 3: PARALLEL Aggregation (force parallelism)
-- Enable parallel execution
SET max_parallel_workers_per_gather = 8;
SET force_parallel_mode = on;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    violation_type,
    COUNT(*) as violation_count,
    AVG(recorded_speed) as avg_speed,
    COUNT(DISTINCT plate_number) as unique_vehicles,
    COUNT(DISTINCT officer_id) as officers_involved
FROM Violation_ALL
WHERE recorded_speed IS NOT NULL
GROUP BY violation_type
ORDER BY violation_count DESC;

-- Execute the query
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

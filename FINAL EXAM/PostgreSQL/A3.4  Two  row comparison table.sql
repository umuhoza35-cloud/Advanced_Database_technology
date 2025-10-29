-- STEP 4: Comparison Table
-- Reset to default
SET max_parallel_workers_per_gather = 2;
SET force_parallel_mode = off;

-- Create comparison summary
SELECT 
    'Serial Execution' as mode,
    'Sequential Scan + Aggregate' as plan_type,
    'Single worker process' as workers,
    'Lower overhead for small data' as notes
UNION ALL
SELECT 
    'Parallel Execution',
    'Parallel Seq Scan + Gather',
    '8 parallel workers',
    'Higher overhead, beneficial for large datasets';

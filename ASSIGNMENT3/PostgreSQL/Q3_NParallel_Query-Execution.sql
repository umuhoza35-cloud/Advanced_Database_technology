-- ============================================================================
-- ASSIGNMENT 3 - TASK 3: PARALLEL QUERY EXECUTION
-- Demonstrating Serial vs Parallel Query Performance
-- ============================================================================
-- This script demonstrates parallel query execution in PostgreSQL
-- using EXPLAIN ANALYZE to compare performance
-- ============================================================================

-- Step 1: Enable parallel query execution
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers = 4;
SET parallel_setup_cost = 100;
SET parallel_tuple_cost = 0.01;

-- Step 2: Create a large test table for parallel query demonstration
CREATE TABLE IF NOT EXISTS node_a_kigali.violation_archive AS
SELECT * FROM node_a_kigali.violation
UNION ALL
SELECT * FROM node_a_kigali.violation
UNION ALL
SELECT * FROM node_a_kigali.violation;

-- Step 3: Serial Query Execution Plan
-- Disable parallel execution to show serial plan
SET max_parallel_workers_per_gather = 0;

EXPLAIN ANALYZE
SELECT 
    violation_type,
    severity_level,
    COUNT(*) as violation_count,
    AVG(EXTRACT(YEAR FROM violation_date)) as avg_year
FROM node_a_kigali.violation_archive
WHERE violation_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY violation_type, severity_level
ORDER BY violation_count DESC;

-- Step 4: Parallel Query Execution Plan
-- Enable parallel execution to show parallel plan
SET max_parallel_workers_per_gather = 4;

EXPLAIN ANALYZE
SELECT 
    violation_type,
    severity_level,
    COUNT(*) as violation_count,
    AVG(EXTRACT(YEAR FROM violation_date)) as avg_year
FROM node_a_kigali.violation_archive
WHERE violation_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY violation_type, severity_level
ORDER BY violation_count DESC;

-- Step 5: Complex parallel query with JOIN
-- Demonstrates parallel execution with joins
EXPLAIN ANALYZE
SELECT 
    v.violation_type,
    COUNT(*) as total_violations,
    SUM(f.amount_rwf) as total_fines,
    AVG(f.amount_rwf) as avg_fine
FROM node_a_kigali.violation_archive v
LEFT JOIN node_a_kigali.fine f ON v.violation_id = f.violation_id
WHERE v.violation_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY v.violation_type
HAVING COUNT(*) > 5
ORDER BY total_violations DESC;

-- Step 6: Aggregation query with parallel workers
-- Shows parallel aggregation performance
EXPLAIN ANALYZE
SELECT 
    EXTRACT(MONTH FROM violation_date) as month,
    EXTRACT(YEAR FROM violation_date) as year,
    severity_level,
    COUNT(*) as violation_count
FROM node_a_kigali.violation_archive
WHERE violation_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY EXTRACT(MONTH FROM violation_date), EXTRACT(YEAR FROM violation_date), severity_level
ORDER BY year DESC, month DESC;

-- Step 7: Reset parallel settings
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers = 4;

-- Step 8: Performance comparison query
-- Demonstrates query performance metrics
SELECT 
    'Parallel Query Execution' as test_type,
    COUNT(*) as rows_processed,
    CURRENT_TIMESTAMP as execution_time
FROM node_a_kigali.violation_archive;

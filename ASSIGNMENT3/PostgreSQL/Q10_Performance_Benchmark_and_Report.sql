-- ============================================================================
-- ASSIGNMENT 3 - TASK 10: PERFORMANCE BENCHMARK AND REPORT
-- Centralized vs Parallel vs Distributed Query Comparison
-- ============================================================================
-- This script performs comprehensive performance benchmarking
-- ============================================================================

-- Step 1: Create performance benchmark table
CREATE TABLE IF NOT EXISTS public.performance_benchmark (
    benchmark_id SERIAL PRIMARY KEY,
    test_name VARCHAR(100),
    query_type VARCHAR(50),
    execution_mode VARCHAR(50),
    row_count INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_ms NUMERIC,
    cpu_time_ms NUMERIC,
    io_reads INT,
    io_writes INT,
    memory_kb INT,
    rows_processed INT,
    throughput_rows_per_sec NUMERIC,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 2: Benchmark 1 - Centralized Query (Single Node)
-- Centralized query execution benchmark
INSERT INTO public.performance_benchmark (test_name, query_type, execution_mode, row_count, start_time)
VALUES ('Benchmark 1: Centralized Query', 'SELECT', 'CENTRALIZED', 0, CURRENT_TIMESTAMP);

-- Execute centralized query
SELECT 
    v.violation_type,
    COUNT(*) as violation_count,
    SUM(f.amount_rwf) as total_fines,
    AVG(f.amount_rwf) as avg_fine
FROM node_a_kigali.violation v
LEFT JOIN node_a_kigali.fine f ON v.violation_id = f.violation_id
WHERE v.violation_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY v.violation_type;

-- Update benchmark with results
UPDATE public.performance_benchmark
SET 
    row_count = (SELECT COUNT(*) FROM node_a_kigali.violation),
    end_time = CURRENT_TIMESTAMP,
    duration_ms = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) * 1000,
    rows_processed = (SELECT COUNT(*) FROM node_a_kigali.violation),
    throughput_rows_per_sec = (SELECT COUNT(*) FROM node_a_kigali.violation) / NULLIF(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)), 0)
WHERE test_name = 'Benchmark 1: Centralized Query'
ORDER BY benchmark_id DESC LIMIT 1;

-- Step 3: Benchmark 2 - Parallel Query (Single Node with Parallel Workers)
-- Parallel query execution benchmark
INSERT INTO public.performance_benchmark (test_name, query_type, execution_mode, row_count, start_time)
VALUES ('Benchmark 2: Parallel Query', 'SELECT', 'PARALLEL', 0, CURRENT_TIMESTAMP);

-- Enable parallel execution
SET max_parallel_workers_per_gather = 4;

-- Execute parallel query
SELECT 
    v.violation_type,
    COUNT(*) as violation_count,
    SUM(f.amount_rwf) as total_fines,
    AVG(f.amount_rwf) as avg_fine
FROM node_a_kigali.violation v
LEFT JOIN node_a_kigali.fine f ON v.violation_id = f.violation_id
WHERE v.violation_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY v.violation_type;

-- Update benchmark with results
UPDATE public.performance_benchmark
SET 
    row_count = (SELECT COUNT(*) FROM node_a_kigali.violation),
    end_time = CURRENT_TIMESTAMP,
    duration_ms = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) * 1000,
    rows_processed = (SELECT COUNT(*) FROM node_a_kigali.violation),
    throughput_rows_per_sec = (SELECT COUNT(*) FROM node_a_kigali.violation) / NULLIF(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)), 0)
WHERE test_name = 'Benchmark 2: Parallel Query'
ORDER BY benchmark_id DESC LIMIT 1;

-- Step 4: Benchmark 3 - Distributed Query (Multiple Nodes)
-- Distributed query execution benchmark
INSERT INTO public.performance_benchmark (test_name, query_type, execution_mode, row_count, start_time)
VALUES ('Benchmark 3: Distributed Query', 'SELECT', 'DISTRIBUTED', 0, CURRENT_TIMESTAMP);

-- Execute distributed query across both nodes
SELECT 
    'Node A - Kigali' as region,
    v.violation_type,
    COUNT(*) as violation_count,
    SUM(f.amount_rwf) as total_fines
FROM node_a_kigali.violation v
LEFT JOIN node_a_kigali.fine f ON v.violation_id = f.violation_id
WHERE v.violation_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY v.violation_type
UNION ALL
SELECT 
    'Node B - Other Regions' as region,
    v.violation_type,
    COUNT(*) as violation_count,
    SUM(f.amount_rwf) as total_fines
FROM node_b_regions.violation v
LEFT JOIN node_b_regions.fine f ON v.violation_id = f.violation_id
WHERE v.violation_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY v.violation_type;

-- Update benchmark with results
UPDATE public.performance_benchmark
SET 
    row_count = (SELECT COUNT(*) FROM node_a_kigali.violation) + (SELECT COUNT(*) FROM node_b_regions.violation),
    end_time = CURRENT_TIMESTAMP,
    duration_ms = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) * 1000,
    rows_processed = (SELECT COUNT(*) FROM node_a_kigali.violation) + (SELECT COUNT(*) FROM node_b_regions.violation),
    throughput_rows_per_sec = ((SELECT COUNT(*) FROM node_a_kigali.violation) + (SELECT COUNT(*) FROM node_b_regions.violation)) / NULLIF(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)), 0)
WHERE test_name = 'Benchmark 3: Distributed Query'
ORDER BY benchmark_id DESC LIMIT 1;

-- Step 5: Performance comparison report
-- Generate performance comparison
SELECT 
    'Performance Comparison Report' as report_type,
    test_name,
    execution_mode,
    row_count,
    ROUND(duration_ms::NUMERIC, 2) as duration_ms,
    ROUND(throughput_rows_per_sec::NUMERIC, 2) as rows_per_sec
FROM public.performance_benchmark
WHERE test_name IN ('Benchmark 1: Centralized Query', 'Benchmark 2: Parallel Query', 'Benchmark 3: Distributed Query')
ORDER BY duration_ms;

-- Step 6: Calculate performance improvements
-- Calculate speedup and efficiency metrics
SELECT 
    'Performance Improvement Analysis' as analysis_type,
    'Parallel vs Centralized' as comparison,
    ROUND((
        (SELECT duration_ms FROM public.performance_benchmark WHERE test_name = 'Benchmark 1: Centralized Query' ORDER BY benchmark_id DESC LIMIT 1) /
        (SELECT duration_ms FROM public.performance_benchmark WHERE test_name = 'Benchmark 2: Parallel Query' ORDER BY benchmark_id DESC LIMIT 1)
    )::NUMERIC, 2) as speedup_factor,
    'Parallel execution provides X times faster performance' as interpretation
UNION ALL
SELECT 
    'Performance Improvement Analysis',
    'Distributed vs Centralized',
    ROUND((
        (SELECT duration_ms FROM public.performance_benchmark WHERE test_name = 'Benchmark 1: Centralized Query' ORDER BY benchmark_id DESC LIMIT 1) /
        (SELECT duration_ms FROM public.performance_benchmark WHERE test_name = 'Benchmark 3: Distributed Query' ORDER BY benchmark_id DESC LIMIT 1)
    )::NUMERIC, 2),
    'Distributed execution provides X times faster performance'
UNION ALL
SELECT 
    'Performance Improvement Analysis',
    'Distributed vs Parallel',
    ROUND((
        (SELECT duration_ms FROM public.performance_benchmark WHERE test_name = 'Benchmark 2: Parallel Query' ORDER BY benchmark_id DESC LIMIT 1) /
        (SELECT duration_ms FROM public.performance_benchmark WHERE test_name = 'Benchmark 3: Distributed Query' ORDER BY benchmark_id DESC LIMIT 1)
    )::NUMERIC, 2),
    'Distributed execution provides X times faster performance';

-- Step 7: Scalability analysis
-- Analyze scalability characteristics
SELECT 
    'Scalability Analysis' as analysis,
    'Centralized' as execution_mode,
    'Linear degradation with data size' as scalability_characteristic,
    'Single node bottleneck' as limitation
UNION ALL
SELECT 
    'Scalability Analysis',
    'Parallel',
    'Sub-linear improvement with worker count' as scalability_characteristic,
    'Limited by single node resources' as limitation
UNION ALL
SELECT 
    'Scalability Analysis',
    'Distributed',
    'Near-linear scaling with node count' as scalability_characteristic,
    'Network latency and coordination overhead' as limitation;

-- Step 8: Resource utilization analysis
-- Analyze resource consumption
SELECT 
    'Resource Utilization Report' as report_type,
    test_name,
    execution_mode,
    ROUND(duration_ms::NUMERIC, 2) as duration_ms,
    COALESCE(memory_kb, 0) as memory_kb,
    COALESCE(io_reads, 0) as io_reads,
    COALESCE(io_writes, 0) as io_writes
FROM public.performance_benchmark
WHERE test_name IN ('Benchmark 1: Centralized Query', 'Benchmark 2: Parallel Query', 'Benchmark 3: Distributed Query')
ORDER BY duration_ms;

-- Step 9: Efficiency metrics
-- Calculate efficiency metrics
SELECT 
    'Efficiency Metrics' as metric_type,
    test_name,
    execution_mode,
    ROUND((throughput_rows_per_sec / NULLIF((SELECT MAX(throughput_rows_per_sec) FROM public.performance_benchmark), 0) * 100)::NUMERIC, 2) as efficiency_percentage,
    ROUND(duration_ms::NUMERIC, 2) as duration_ms
FROM public.performance_benchmark
WHERE test_name IN ('Benchmark 1: Centralized Query', 'Benchmark 2: Parallel Query', 'Benchmark 3: Distributed Query')
ORDER BY efficiency_percentage DESC;

-- Step 10: Final benchmark summary and recommendations
-- Generate final recommendations
SELECT 
    'Benchmark Summary & Recommendations' as summary,
    'Use Centralized' as recommendation,
    'For small datasets and simple queries' as use_case,
    'Lowest complexity, minimal overhead' as advantage
UNION ALL
SELECT 
    'Benchmark Summary & Recommendations',
    'Use Parallel',
    'For large single-node datasets with complex queries',
    'Good performance improvement with moderate complexity'
UNION ALL
SELECT 
    'Benchmark Summary & Recommendations',
    'Use Distributed',
    'For very large datasets across multiple regions',
    'Best scalability for enterprise-scale systems'
UNION ALL
SELECT 
    'Benchmark Summary & Recommendations',
    'Hybrid Approach',
    'Combine parallel and distributed for optimal performance',
    'Parallel within nodes + distributed across nodes';

-- Step 11: Display final performance report
SELECT 
    'FINAL PERFORMANCE BENCHMARK REPORT' as report_title,
    COUNT(*) as total_benchmarks,
    MIN(duration_ms) as fastest_query_ms,
    MAX(duration_ms) as slowest_query_ms,
    ROUND(AVG(duration_ms)::NUMERIC, 2) as avg_query_ms,
    ROUND(AVG(throughput_rows_per_sec)::NUMERIC, 2) as avg_throughput
FROM public.performance_benchmark

WHERE test_name IN ('Benchmark 1: Centralized Query', 'Benchmark 2: Parallel Query', 'Benchmark 3: Distributed Query');

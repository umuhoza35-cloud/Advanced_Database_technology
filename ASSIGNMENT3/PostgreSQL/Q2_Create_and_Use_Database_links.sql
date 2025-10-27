-- ============================================================================
-- ASSIGNMENT 3 - TASK 2: CREATE AND USE DATABASE LINKS (FDW)
-- Foreign Data Wrapper Setup for Distributed Queries
-- ============================================================================
-- This script sets up postgres_fdw to enable distributed queries
-- between Node A (Kigali) and Node B (Other Regions)
-- ============================================================================

-- Step 1: Create the postgres_fdw extension (if not exists)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Step 2: Create foreign server for Node B (simulated on same instance)
-- In production, this would point to a remote PostgreSQL server
CREATE SERVER IF NOT EXISTS node_b_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'localhost',
        dbname 'smart traffic Rwanda db',
        port '5432'
    );

-- Step 3: Create user mapping for the foreign server
-- This allows the current user to authenticate with the remote server
CREATE USER MAPPING IF NOT EXISTS FOR current_user
    SERVER node_b_server
    OPTIONS (user 'postgres', password 'postgres');

-- Step 4: Import foreign schema from Node B
-- This creates local foreign tables that reference remote tables
IMPORT FOREIGN SCHEMA node_b_regions
    FROM SERVER node_b_server
    INTO node_a_kigali;

-- Step 5: Verify foreign tables were created
SELECT * FROM information_schema.tables 
WHERE table_schema = 'node_a_kigali' 
AND table_type = 'FOREIGN';

-- ============================================================================
-- DISTRIBUTED QUERY EXAMPLES
-- ============================================================================

-- Example 1: Remote SELECT - Query data from Node B through FDW
-- This demonstrates accessing remote data from Node A
SELECT 
    'Node B - Remote Query' as source,
    COUNT(*) as total_violations
FROM node_a_kigali.violation
WHERE violation_date >= CURRENT_DATE - INTERVAL '30 days';

-- Example 2: Distributed JOIN - Join local and remote tables
-- This demonstrates joining data across distributed nodes
SELECT 
    'Distributed Join' as query_type,
    COUNT(DISTINCT v.violation_id) as total_violations,
    COUNT(DISTINCT f.fine_id) as total_fines
FROM node_a_kigali.violation v
LEFT JOIN node_a_kigali.fine f ON v.violation_id = f.violation_id;

-- Example 3: Union query across both nodes
-- This demonstrates combining data from both nodes
SELECT 
    'Node A - Kigali' as region,
    COUNT(*) as violation_count,
    SUM(f.amount_rwf) as total_fines_amount
FROM node_a_kigali.violation v
LEFT JOIN node_a_kigali.fine f ON v.violation_id = f.violation_id
GROUP BY region
UNION ALL
SELECT 
    'Node B - Other Regions' as region,
    COUNT(*) as violation_count,
    SUM(f.amount_rwf) as total_fines_amount
FROM node_b_regions.violation v
LEFT JOIN node_b_regions.fine f ON v.violation_id = f.violation_id
GROUP BY region;

-- Example 4: Distributed aggregation
-- This demonstrates aggregating data across nodes
SELECT 
    'Distributed Aggregation' as query_type,
    SUM(total_violations) as global_violations,
    SUM(total_fines) as global_fines
FROM (
    SELECT COUNT(*) as total_violations, COUNT(*) as total_fines
    FROM node_a_kigali.violation
    UNION ALL
    SELECT COUNT(*) as total_violations, COUNT(*) as total_fines
    FROM node_b_regions.violation
) distributed_data;

-- Verify FDW setup
SELECT * FROM pg_foreign_server;
SELECT * FROM pg_user_mapping;


-- A1: Fragment & Recombine Main Fact (≤10 rows)
-- =============================================

-- STEP 1: Setup Foreign Data Wrapper (PostgreSQL equivalent of DB Link)
-- Run this on Node_A to connect to Node_B

-- Install postgres_fdw extension (if not already installed)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create foreign server pointing to Node_B
-- REPLACE with your actual Node_B connection details
CREATE SERVER node_b_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5433', dbname 'traffic_violations_b');

-- Create user mapping for connection
-- REPLACE with your actual credentials
CREATE USER MAPPING FOR CURRENT_USER
    SERVER node_b_server
    OPTIONS (user 'postgres', password 'your_password');

-- Import foreign schema (Violation_B table from Node_B)
IMPORT FOREIGN SCHEMA public
    LIMIT TO (Violation_B, Vehicle, Officer)
    FROM SERVER node_b_server
    INTO public;

-- STEP 2: Create UNION ALL View (Recombination)
CREATE OR REPLACE VIEW Violation_ALL AS
SELECT violation_id, plate_number, officer_id, violation_type, 
       violation_date, location, speed_limit, recorded_speed, status,
       'Node_A' as source_node
FROM Violation_A
UNION ALL
SELECT violation_id, plate_number, officer_id, violation_type,
       violation_date, location, speed_limit, recorded_speed, status,
       'Node_B' as source_node
FROM Violation_B;

-- STEP 3: Validation Queries

-- Count validation
SELECT 'Fragment A Count' as source, COUNT(*) as row_count FROM Violation_A
UNION ALL
SELECT 'Fragment B Count', COUNT(*) FROM Violation_B
UNION ALL
SELECT 'Union View Count', COUNT(*) FROM Violation_ALL;

-- Checksum validation (using MOD 97 on primary key)
SELECT 'Fragment A Checksum' as source, 
       SUM(MOD(violation_id, 97)) as checksum,
       COUNT(*) as row_count
FROM Violation_A
UNION ALL
SELECT 'Fragment B Checksum',
       SUM(MOD(violation_id, 97)),
       COUNT(*)
FROM Violation_B
UNION ALL
SELECT 'Union View Checksum',
       SUM(MOD(violation_id, 97)),
       COUNT(*)
FROM Violation_ALL;

-- Display all violations with source node
SELECT * FROM Violation_ALL ORDER BY violation_date;

-- Verify fragmentation rule (HASH distribution)
SELECT 
    source_node,
    COUNT(*) as violations,
    STRING_AGG(plate_number, ', ') as plates
FROM Violation_ALL
GROUP BY source_node;

-- A2: Database Link & Cross-Node Join (3–10 rows result)
-- =======================================================

-- STEP 1: Database Link Setup (already done in A1)
-- The foreign data wrapper and server 'node_b_server' serves as our DB link

-- STEP 2: Remote SELECT on Vehicle table
-- Query Vehicle table from Node_B (via foreign table)
SELECT 
    plate_number,
    owner_name,
    vehicle_type,
    province,
    'Remote Node_B' as data_source
FROM Vehicle
LIMIT 5;

SELECT 
    plate_number,
    owner_name,
    vehicle_type,
    province,
    'Remote Node_a' as data_source
FROM Vehicle
LIMIT 5;

Select*from node_a and node_B, 


-- STEP 3: Distributed Join
-- Join local Violation_A with remote Officer data
-- This demonstrates cross-node join capability

-- Join local violations with remote officer data
SELECT 
    v.violation_id,
    v.plate_number,
    v.violation_type,
    v.violation_date,
    v.location,
    o.full_name as officer_name,
    o.badge_number,
    o.station,
    'Local-Remote Join' as join_type
FROM Violation_a v
INNER JOIN Officer o ON v.officer_id = o.officer_id
WHERE v.status = 'PENDING'
ORDER BY v.violation_date DESC
LIMIT 10;

-- Alternative: Join with remote Violation_B
SELECT 
    va.violation_id as local_violation_id,
    va.plate_number as local_plate,
    va.violation_type as local_type,
    vb.violation_id as remote_violation_id,
    vb.plate_number as remote_plate,
   vb.violation_type AS remote_type
    'Cross-Node Violation Comparison' as analysis
FROM Violation_a va
CROSS JOIN Violation_B vb
WHERE va.plate_number = vb.plate_number
LIMIT 5;

-- Distributed aggregation across nodes
SELECT 
    o.station,
    o.rank,
    COUNT(v.violation_id) as total_violations,
    STRING_AGG(DISTINCT v.violation_type, ', ') as violation_types
FROM Violation_ALL v
INNER JOIN Officer o ON v.officer_id = o.officer_id
GROUP BY o.station, o.rank
HAVING COUNT(v.violation_id) >= 1
ORDER BY total_violations DESC;

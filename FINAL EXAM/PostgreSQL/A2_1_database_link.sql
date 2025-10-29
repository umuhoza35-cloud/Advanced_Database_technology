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


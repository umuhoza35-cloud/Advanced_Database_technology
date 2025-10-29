STEP 2: Remote SELECT on Vehicle table
-- Query Vehicle table from Node_B (via foreign table)
SELECT 
    plate_number,
    owner_name,
    vehicle_type,
    province,
    'Remote Node_B' as data_source
FROM Vehicle
LIMIT 5;

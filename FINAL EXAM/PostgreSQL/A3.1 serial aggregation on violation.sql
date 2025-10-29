STEP 1: Verify Foreign Table Setup
-- Check if Violation_B foreign table exists
SELECT 
    foreign_table_name,
    foreign_server_name
FROM information_schema.foreign_tables
WHERE foreign_table_name = 'violation_b';

BEGIN;

-- This will block waiting for Session 1's lock
UPDATE Fine 
SET status = 'PAID'
WHERE fine_id = 1;

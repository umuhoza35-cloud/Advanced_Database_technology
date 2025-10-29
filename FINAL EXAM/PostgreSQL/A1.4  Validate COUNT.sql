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

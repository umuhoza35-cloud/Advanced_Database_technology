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
FROM Violation_A v
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
    vb.violation_type as remote_type,
    'Cross-Node Violation Comparison' as analysis
FROM Violation_A va
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

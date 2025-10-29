SELECT 
    gid as transaction_id,
    prepared as prepare_time,
    owner,
    database,
    'IN-DOUBT' as status
FROM pg_prepared_xacts
WHERE gid LIKE 'traffic_violation%';

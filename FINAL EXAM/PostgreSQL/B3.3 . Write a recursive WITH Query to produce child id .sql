WITH RECURSIVE transitive_isa AS (
    -- Base case: direct isA relationships
    SELECT 
        s as subtype,
        o as supertype,
        1 as distance,
        ARRAY[s, o] as path
    FROM TRIPLE
    WHERE p = 'isA'
    
    UNION
    
    -- Recursive case: transitive isA relationships
    SELECT 
        t.subtype,
        tr.o as supertype,
        t.distance + 1,
        t.path || tr.o
    FROM transitive_isa t
    INNER JOIN TRIPLE tr ON t.supertype = tr.s AND tr.p = 'isA'
    WHERE NOT (tr.o = ANY(t.path))  -- Prevent cycles
    AND t.distance < 5  -- Limit recursion depth
)
SELECT DISTINCT
    subtype,
    supertype,
    distance,
    array_to_string(path, ' → ') as inference_path
FROM transitive_isa
ORDER BY subtype, distance;

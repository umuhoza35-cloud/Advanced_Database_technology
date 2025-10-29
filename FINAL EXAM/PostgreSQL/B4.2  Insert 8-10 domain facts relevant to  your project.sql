SELECT 
        s as subtype,
        o as supertype,
        1 as distance,
        ARRAY[s, o] as path
    FROM TRIPLE
    WHERE p = 'isA'

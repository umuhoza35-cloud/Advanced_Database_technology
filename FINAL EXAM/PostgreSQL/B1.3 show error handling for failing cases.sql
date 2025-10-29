DO $$
BEGIN
    INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
    VALUES (1, CURRENT_TIMESTAMP + INTERVAL '1 day', 10000, 'Cash', 'FUTURE-' || gen_random_uuid());
    
    RAISE NOTICE 'ERROR: Future payment date was accepted!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'PASS: Future payment date rejected - %', SQLERRM;
    ROLLBACK;
END $$;

DO $$
BEGIN
    INSERT INTO Fine (violation_id, amount, due_date, status, total_paid)
    VALUES (1, 50000.00, CURRENT_DATE + 30, 'PAID', 75000.00);
    
    RAISE NOTICE 'ERROR: Overpayment was accepted!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'PASS: Overpayment rejected - %', SQLERRM;
    ROLLBACK;
END $$;

BEGIN;
INSERT INTO Fine (violation_id, amount, due_date, status)
VALUES (1, 30000.00, CURRENT_DATE + INTERVAL '30 days', 'UNPAID');
RAISE NOTICE 'PASS: Valid fine inserted';
COMMIT;

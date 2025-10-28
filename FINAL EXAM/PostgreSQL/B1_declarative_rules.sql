-- B6: Declarative Rules Hardening (≤10 committed rows)
-- =====================================================

-- STEP 1: Add/Verify Constraints on Fine table

-- Add named constraints
ALTER TABLE Fine 
    ADD CONSTRAINT chk_fine_amount_positive 
    CHECK (amount > 0);

ALTER TABLE Fine 
    ADD CONSTRAINT chk_fine_total_paid_non_negative 
    CHECK (total_paid >= 0);

ALTER TABLE Fine 
    ADD CONSTRAINT chk_fine_total_paid_not_exceed_amount 
    CHECK (total_paid <= amount);

ALTER TABLE Fine 
    ADD CONSTRAINT chk_fine_status_valid 
    CHECK (status IN ('UNPAID', 'PAID', 'OVERDUE', 'WAIVED'));

ALTER TABLE Fine
    ALTER COLUMN amount SET NOT NULL,
    ALTER COLUMN due_date SET NOT NULL,
    ALTER COLUMN status SET NOT NULL;

-- STEP 2: Add/Verify Constraints on Payment table

ALTER TABLE Payment 
    ADD CONSTRAINT chk_payment_amount_positive 
    CHECK (amount > 0);

ALTER TABLE Payment 
    ADD CONSTRAINT chk_payment_date_not_future 
    CHECK (payment_date <= CURRENT_TIMESTAMP);

ALTER TABLE Payment 
    ADD CONSTRAINT chk_payment_method_valid 
    CHECK (payment_method IN ('Cash', 'Mobile Money', 'Bank Transfer', 'Card'));

ALTER TABLE Payment
    ALTER COLUMN amount SET NOT NULL,
    ALTER COLUMN payment_date SET NOT NULL,
    ALTER COLUMN payment_method SET NOT NULL,
    ALTER COLUMN reference_number SET NOT NULL;

-- STEP 3: Test Constraints with Failing Cases (will be rolled back)

-- Test 1: Negative fine amount (SHOULD FAIL)
DO $$
BEGIN
    INSERT INTO Fine (violation_id, amount, due_date, status)
    VALUES (1, -50000.00, CURRENT_DATE + 30, 'UNPAID');
    
    RAISE NOTICE 'ERROR: Negative amount was accepted!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'PASS: Negative fine amount rejected - %', SQLERRM;
    ROLLBACK;
END $$;

-- Test 2: Invalid payment method (SHOULD FAIL)
DO $$
BEGIN
    INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
    VALUES (1, CURRENT_TIMESTAMP, 10000, 'Bitcoin', 'BTC-' || gen_random_uuid());
    
    RAISE NOTICE 'ERROR: Invalid payment method was accepted!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'PASS: Invalid payment method rejected - %', SQLERRM;
    ROLLBACK;
END $$;

-- Test 3: Future payment date (SHOULD FAIL)
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

-- Test 4: Total paid exceeds fine amount (SHOULD FAIL)
DO $$
BEGIN
    INSERT INTO Fine (violation_id, amount, due_date, status, total_paid)
    VALUES (1, 50000.00, CURRENT_DATE + 30, 'PAID', 75000.00);
    
    RAISE NOTICE 'ERROR: Overpayment was accepted!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'PASS: Overpayment rejected - %', SQLERRM;
    ROLLBACK;
END$$;

-- STEP 4: Test Constraints with Passing Cases (will be committed)

-- Passing Test 1: Valid fine
BEGIN;
INSERT INTO Fine (violation_id, amount, due_date, status)
VALUES (1, 30000.00, CURRENT_DATE + INTERVAL '30 days', 'UNPAID');
RAISE NOTICE 'PASS: Valid fine inserted';
COMMIT;

-- Passing Test 2: Valid payment
BEGIN;
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
VALUES (1, CURRENT_TIMESTAMP, 15000.00, 'Mobile Money', 'MTN-' || gen_random_uuid());
RAISE NOTICE 'PASS: Valid payment inserted';
COMMIT;

-- STEP 5: Verification - Show only committed rows
SELECT 
    'Fine Records' as table_name,
    COUNT(*) as committed_rows
FROM Fine
UNION ALL
SELECT 
    'Payment Records',
    COUNT(*)
FROM Payment;

-- Display sample data
SELECT 
    f.fine_id,
    f.amount,
    f.status,
    f.total_paid,
    f.due_date,
    'Valid constraint-compliant record' as validation_status
FROM Fine f
ORDER BY f.fine_id DESC
LIMIT 5;

SELECT 
    p.payment_id,
    p.fine_id,
    p.amount,
    p.payment_method,
    p.payment_date,
    'Valid constraint-compliant record' as validation_status
FROM Payment p
ORDER BY p.payment_id DESC
LIMIT 5;

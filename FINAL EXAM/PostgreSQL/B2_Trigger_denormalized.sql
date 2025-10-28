 STEP 1: Create trigger function to update denormalized totals
CREATE OR REPLACE FUNCTION update_fine_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_fine_id INTEGER;
    v_old_total DECIMAL(10,2);
    v_new_total DECIMAL(10,2);
    v_operation VARCHAR(10);
BEGIN
    -- Determine which fine_id to update based on operation
    IF TG_OP = 'DELETE' THEN
        v_fine_id := OLD.fine_id;
        v_operation := 'DELETE';
    ELSE
        v_fine_id := NEW.fine_id;
        v_operation := TG_OP;
    END IF;
    
    -- Get old total before update
    SELECT total_paid INTO v_old_total
    FROM Fine
    WHERE fine_id = v_fine_id;
    
    -- Recompute total from all payments
    SELECT COALESCE(SUM(amount), 0) INTO v_new_total
    FROM Payment
    WHERE fine_id = v_fine_id;
    
    -- Update the denormalized total in Fine table
    UPDATE Fine
    SET total_paid = v_new_total,
        status = CASE 
            WHEN v_new_total >= amount THEN 'PAID'
            WHEN v_new_total > 0 THEN 'UNPAID'
            ELSE 'UNPAID'
        END
    WHERE fine_id = v_fine_id;
    
    -- Log to audit table
    INSERT INTO Fine_AUDIT (fine_id, bef_total, aft_total, changed_at, key_col, operation)
    VALUES (v_fine_id, v_old_total, v_new_total, CURRENT_TIMESTAMP, 
            'fine_' || v_fine_id, v_operation);
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- STEP 2: Create statement-level trigger
DROP TRIGGER IF EXISTS trg_payment_update_fine_totals ON Payment;

CREATE TRIGGER trg_payment_update_fine_totals
    AFTER INSERT OR UPDATE OR DELETE ON Payment
    FOR EACH ROW
    EXECUTE FUNCTION update_fine_totals();

-- STEP 3: Setup test data
-- Ensure we have a fine to work with
INSERT INTO Fine (violation_id, amount, due_date, status, total_paid)
VALUES (1, 100000.00, CURRENT_DATE + INTERVAL '30 days', 'UNPAID', 0)
ON CONFLICT DO NOTHING;

-- Get the fine_id for testing
DO $$
DECLARE
    v_fine_id INTEGER;
BEGIN
    SELECT fine_id INTO v_fine_id FROM Fine WHERE amount = 100000.00 LIMIT 1;
    RAISE NOTICE 'Testing with fine_id: %', v_fine_id;
END $$;

-- STEP 4: Execute mixed DML operations

-- Operation 1: Insert first payment (partial payment)
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
SELECT fine_id, CURRENT_TIMESTAMP, 30000.00, 'Mobile Money', 'MTN-PAY-001'
FROM Fine WHERE amount = 100000.00 LIMIT 1;

-- Check audit log
SELECT 'After Payment 1' as checkpoint, * FROM Fine_AUDIT ORDER BY changed_at DESC LIMIT 1;

-- Operation 2: Insert second payment
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
SELECT fine_id, CURRENT_TIMESTAMP, 40000.00, 'Cash', 'CASH-PAY-002'
FROM Fine WHERE amount = 100000.00 LIMIT 1;

-- Check audit log
SELECT 'After Payment 2' as checkpoint, * FROM Fine_AUDIT ORDER BY changed_at DESC LIMIT 1;

-- Operation 3: Update a payment amount
UPDATE Payment 
SET amount = 45000.00
WHERE reference_number = 'CASH-PAY-002';

-- Check audit log
SELECT 'After Payment Update' as checkpoint, * FROM Fine_AUDIT ORDER BY changed_at DESC LIMIT 1;

-- Operation 4: Insert final payment to complete the fine
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
SELECT fine_id, CURRENT_TIMESTAMP, 25000.00, 'Bank Transfer', 'BANK-PAY-003'
FROM Fine WHERE amount = 100000.00 LIMIT 1;

-- STEP 5: Verification

-- Show Fine with updated totals
SELECT 
    f.fine_id,
    f.amount as fine_amount,
    f.total_paid,
    f.status,
    CASE 
        WHEN f.total_paid >= f.amount THEN 'Fully Paid'
        WHEN f.total_paid > 0 THEN 'Partially Paid'
        ELSE 'Unpaid'
    END as payment_status,
    (f.amount - f.total_paid) as remaining_balance
FROM Fine f
WHERE f.amount = 100000.00;

-- Show all payments for this fine
SELECT 
    p.payment_id,
    p.amount,
    p.payment_method,
    p.payment_date,
    p.reference_number
FROM Payment p
WHERE p.fine_id = (SELECT fine_id FROM Fine WHERE amount = 100000.00 LIMIT 1)
ORDER BY p.payment_date;

-- Show complete audit trail
SELECT 
    audit_id,
    fine_id,
    operation,
    bef_total as before_total,
    aft_total as after_total,
    (aft_total - bef_total) as change_amount,
    changed_at,
    key_col
FROM Fine_AUDIT
WHERE fine_id = (SELECT fine_id FROM Fine WHERE amount = 100000.00 LIMIT 1)
ORDER BY changed_at;

-- Summary validation
SELECT 
    'Trigger Validation' as check_type,
    COUNT(*) as audit_entries,
    MIN(bef_total) as initial_total,
    MAX(aft_total) as final_total
FROM Fine_AUDIT
WHERE fine_id = (SELECT fine_id FROM Fine WHERE amount = 100000.00 LIMIT 1);

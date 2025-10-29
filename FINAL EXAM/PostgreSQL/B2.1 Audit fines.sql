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
    WHERE fine_id = v_fine_id

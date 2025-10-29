-- STEP 2: Create statement-level trigger
DROP TRIGGER IF EXISTS trg_payment_update_fine_totals ON Payment;

CREATE TRIGGER trg_payment_update_fine_totals
    AFTER INSERT OR UPDATE OR DELETE ON Payment
    FOR EACH ROW
    EXECUTE FUNCTION update_fine_totals();

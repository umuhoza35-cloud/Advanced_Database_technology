STEP 3: Create trigger function for Payment table
CREATE OR REPLACE FUNCTION check_payment_limits()
RETURNS TRIGGER AS $$
DECLARE
    v_alert_max INTEGER;
    v_alert_min INTEGER;
BEGIN
    -- Check maximum payment limit
    v_alert_max := fn_should_alert('MAX_DAILY_PAYMENT', NEW.amount);
    
    IF v_alert_max = 1 THEN
        RAISE EXCEPTION 'Payment amount % exceeds daily limit. Check BUSINESS_LIMITS.', 
            NEW.amount
            USING ERRCODE = '23514';  -- check_violation
    END IF;
    
    -- Check minimum payment limit
    v_alert_min := fn_should_alert('MIN_PAYMENT_AMOUNT', NEW.amount);
    
    IF v_alert_min = 1 THEN
        RAISE EXCEPTION 'Payment amount % is below minimum required. Check BUSINESS_LIMITS.', 
            NEW.amount
            USING ERRCODE = '23514';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 4: Create trigger function for Fine table
CREATE OR REPLACE FUNCTION check_fine_limits()
RETURNS TRIGGER AS $$
DECLARE
    v_alert INTEGER;
BEGIN
    -- Check maximum fine amount
    v_alert := fn_should_alert('MAX_FINE_AMOUNT', NEW.amount);
    
    IF v_alert = 1 THEN
        RAISE EXCEPTION 'Fine amount % exceeds maximum allowed. Check BUSINESS_LIMITS.', 
            NEW.amount
            USING ERRCODE = '23514';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 5: Create triggers
DROP TRIGGER IF EXISTS trg_check_payment_limits ON Payment;
CREATE TRIGGER trg_check_payment_limits
    BEFORE INSERT OR UPDATE ON Payment
    FOR EACH ROW
    EXECUTE FUNCTION check_payment_limits();

DROP TRIGGER IF EXISTS trg_check_fine_limits ON Fine;
CREATE TRIGGER trg_check_fine_limits
    BEFORE INSERT OR UPDATE ON Fine
    FOR EACH ROW
    EXECUTE FUNCTION check_fine_limits();

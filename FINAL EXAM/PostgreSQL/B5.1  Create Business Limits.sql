STEP 1: Seed business limits table
TRUNCATE TABLE BUSINESS_LIMITS;

INSERT INTO BUSINESS_LIMITS (rule_key, threshold, active, description) VALUES
('MAX_DAILY_PAYMENT', 500000.00, 'Y', 'Maximum payment amount allowed per transaction'),
('MAX_FINE_AMOUNT', 1000000.00, 'Y', 'Maximum fine amount that can be issued'),
('MIN_PAYMENT_AMOUNT', 1000.00, 'Y', 'Minimum payment amount required');

-- STEP 2: Create alert function
CREATE OR REPLACE FUNCTION fn_should_alert(
    p_rule_key VARCHAR,
    p_test_amount DECIMAL
) RETURNS INTEGER AS $$
DECLARE
    v_threshold DECIMAL;
    v_active CHAR(1);
    v_current_total DECIMAL;
BEGIN
    -- Get the business rule

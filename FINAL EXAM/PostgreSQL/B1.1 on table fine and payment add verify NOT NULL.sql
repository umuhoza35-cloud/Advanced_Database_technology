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

Select * from Payement; 

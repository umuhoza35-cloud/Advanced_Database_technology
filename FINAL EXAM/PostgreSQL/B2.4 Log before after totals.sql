-- Operation 4: Insert final payment to complete the fine
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
SELECT fine_id, CURRENT_TIMESTAMP, 25000.00, 'Bank Transfer', 'BANK-PAY-003'
FROM Fine WHERE amount = 100000.00 LIMIT 1;

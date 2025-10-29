INSERT INTO Fine (violation_id, amount, due_date, status, total_paid)
VALUES (1, 100000.00, CURRENT_DATE + INTERVAL '30 days', 'UNPAID', 0)
ON CONFLICT DO NOTHING;


BEGIN;

INSERT INTO Violation_A (plate_number, officer_id, violation_type, violation_date, location, status)
VALUES ('RAD456B', 'OFF002', 'Reckless Driving', CURRENT_TIMESTAMP, 'Nyamirambo', 'PENDING');

-- Prepare the transaction (2PC first phase)
PREPARE TRANSACTION 'traffic_violation_tx_001';

INSERT INTO TRIPLE (s, p, o) VALUES
-- Type hierarchy
('Speeding', 'isA', 'MovingViolation'),
('RunningRedLight', 'isA', 'MovingViolation'),
('RecklessDriving', 'isA', 'MovingViolation'),
('MovingViolation', 'isA', 'TrafficViolation'),
('IllegalParking', 'isA', 'ParkingViolation'),
('ParkingViolation', 'isA', 'TrafficViolation'),
('TrafficViolation', 'isA', 'LegalOffense'),
-- Severity relationships
('RecklessDriving', 'hasSeverity', 'High'),
('Speeding', 'hasSeverity', 'Medium'),
('IllegalParking', 'hasSeverity', 'Low');

select * from TRIPLE;

INSERT INTO Violation_A (plate_number, officer_id, violation_type, violation_date, location, speed_limit, recorded_speed, status) VALUES
('RAD123A', 'OFF001', 'Speeding', '2024-01-15 14:30:00', 'KN 5 Ave, Kigali', 60, 85, 'PENDING'),
('RAD456B', 'OFF002', 'Illegal Parking', '2024-01-16 10:20:00', 'Kimihurura, Kigali', NULL, NULL, 'PAID');


CREATE TABLE Violation_B (
    violation_id SERIAL PRIMARY KEY,
    plate_number VARCHAR(20) NOT NULL REFERENCES Vehicle(plate_number),
    officer_id VARCHAR(20) NOT NULL REFERENCES Officer(officer_id),
    violation_type VARCHAR(100) NOT NULL,
    violation_date TIMESTAMP NOT NULL,
    location VARCHAR(200) NOT NULL,
    speed_limit INTEGER,
    recorded_speed INTEGER,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'APPEALED', 'DISMISSED'))
);
 Select* from Violation_B; 
 
-- Fragmentation Rule: Violations outside Kigali City go to Node_B
-- Population (3 rows on Node_B):
INSERT INTO Violation_B (plate_number, officer_id, violation_type, violation_date, location, speed_limit, recorded_speed, status) VALUES
('RAD456B', 'OFF001', 'Running Red Light', '2024-01-17 09:15:00', 'Nyabugogo Junction', NULL, NULL, 'PENDING'),
('RAD123A', 'OFF002', 'No Seatbelt', '2024-01-18 16:45:00', 'Remera Roundabout', NULL, NULL, 'PENDING'),
('RAD789C', 'OFF001', 'Overloading', '2024-01-19 11:30:00', 'Muhanga Highway', NULL, NULL, 'PENDING');


SELECT COUNT(*) AS total_rows
FROM (
    SELECT * FROM violation_node_A
    UNION ALL
    SELECT * FROM violation_node_b
) AS combined;

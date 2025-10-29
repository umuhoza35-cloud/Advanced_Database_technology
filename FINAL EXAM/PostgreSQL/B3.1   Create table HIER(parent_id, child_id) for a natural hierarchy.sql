 STEP 1: Create and populate hierarchy table
-- Hierarchy represents administrative regions in Rwanda

TRUNCATE TABLE HIER;

INSERT INTO HIER (parent_id, child_id, node_name) VALUES
(NULL, 'RW', 'Rwanda'),
('RW', 'KGL', 'Kigali City'),
('RW', 'EST', 'Eastern Province'),
('KGL', 'KGL-GAS', 'Gasabo District'),
('KGL', 'KGL-KIC', 'Kicukiro District'),
('EST', 'EST-RWA', 'Rwamagana District'),
('KGL-GAS', 'KGL-GAS-REM', 'Remera Sector'),
('KGL-KIC', 'KGL-KIC-KAN', 'Kanombe Sector');

Select * from HIER; 

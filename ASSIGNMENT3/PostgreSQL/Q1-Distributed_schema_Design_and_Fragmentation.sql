-- ============================================================================
-- ASSIGNMENT 3 - TASK 1: DISTRIBUTED SCHEMA DESIGN & FRAGMENTATION
-- Node A: Kigali Region (Horizontal Fragmentation)
-- ============================================================================
-- This script creates Node A of a distributed database system
-- Node A handles traffic violations for Kigali region
-- Fragmentation Strategy: Horizontal - by city/region
-- ============================================================================

-- Create schema for Node A (Kigali)
CREATE SCHEMA IF NOT EXISTS node_a_kigali;

-- Officer table - Kigali officers only
CREATE TABLE IF NOT EXISTS node_a_kigali.officer (
    officer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    badge_number VARCHAR(20) UNIQUE NOT NULL,
    rank VARCHAR(30),
    station_location VARCHAR(100),
    phone_number VARCHAR(15),
    email VARCHAR(100),
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_officer_kigali CHECK (station_location IN ('Kigali Central', 'Kigali North', 'Kigali South', 'Kigali East', 'Kigali West'))
);

-- Driver table - Drivers with violations in Kigali
CREATE TABLE IF NOT EXISTS node_a_kigali.driver (
    driver_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(20) UNIQUE NOT NULL,
    date_of_birth DATE,
    address VARCHAR(200),
    phone_number VARCHAR(15),
    email VARCHAR(100),
    license_expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicle table - Vehicles registered in Kigali
CREATE TABLE IF NOT EXISTS node_a_kigali.vehicle (
    vehicle_id SERIAL PRIMARY KEY,
    driver_id INT NOT NULL REFERENCES node_a_kigali.driver(driver_id) ON DELETE CASCADE,
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50),
    make VARCHAR(50),
    model VARCHAR(50),
    year INT,
    color VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Violation table - Violations recorded in Kigali
CREATE TABLE IF NOT EXISTS node_a_kigali.violation (
    violation_id SERIAL PRIMARY KEY,
    officer_id INT NOT NULL REFERENCES node_a_kigali.officer(officer_id),
    driver_id INT NOT NULL REFERENCES node_a_kigali.driver(driver_id),
    vehicle_id INT NOT NULL REFERENCES node_a_kigali.vehicle(vehicle_id),
    violation_type VARCHAR(100) NOT NULL,
    violation_date DATE NOT NULL,
    violation_time TIME,
    location VARCHAR(200),
    description TEXT,
    severity_level VARCHAR(20) CHECK (severity_level IN ('Minor', 'Moderate', 'Severe')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_violation_kigali CHECK (location LIKE '%Kigali%')
);

-- Fine table - Fines for Kigali violations
CREATE TABLE IF NOT EXISTS node_a_kigali.fine (
    fine_id SERIAL PRIMARY KEY,
    violation_id INT NOT NULL REFERENCES node_a_kigali.violation(violation_id),
    amount_rwf DECIMAL(10, 2) NOT NULL,
    fine_date DATE NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Unpaid' CHECK (status IN ('Unpaid', 'Paid', 'Overdue', 'Waived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment table - Payments for Kigali fines
CREATE TABLE IF NOT EXISTS node_a_kigali.payment (
    payment_id SERIAL PRIMARY KEY,
    fine_id INT NOT NULL REFERENCES node_a_kigali.fine(fine_id),
    payment_date DATE NOT NULL,
    amount_paid_rwf DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50),
    transaction_reference VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_node_a_violation_date ON node_a_kigali.violation(violation_date);
CREATE INDEX idx_node_a_violation_location ON node_a_kigali.violation(location);
CREATE INDEX idx_node_a_fine_status ON node_a_kigali.fine(status);
CREATE INDEX idx_node_a_driver_id ON node_a_kigali.driver(driver_id);

-- Add comments for documentation
COMMENT ON SCHEMA node_a_kigali IS 'Node A: Kigali Region - Horizontal fragmentation of traffic violations database';
COMMENT ON TABLE node_a_kigali.violation IS 'Violations recorded in Kigali region only';
COMMENT ON TABLE node_a_kigali.fine IS 'Fines for violations in Kigali region';

-- Verify schema creation
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'node_a_kigali';


- ============================================================================
-- ASSIGNMENT 3 - TASK 1: DISTRIBUTED SCHEMA DESIGN & FRAGMENTATION
-- Node B: Other Regions (Horizontal Fragmentation)
-- ============================================================================
-- This script creates Node B of a distributed database system
-- Node B handles traffic violations for regions outside Kigali
-- Fragmentation Strategy: Horizontal - by city/region
-- ============================================================================

-- Create schema for Node B (Other Regions)
CREATE SCHEMA IF NOT EXISTS node_b_regions;

-- Officer table - Officers from other regions
CREATE TABLE IF NOT EXISTS node_b_regions.officer (
    officer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    badge_number VARCHAR(20) UNIQUE NOT NULL,
    rank VARCHAR(30),
    station_location VARCHAR(100),
    phone_number VARCHAR(15),
    email VARCHAR(100),
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_officer_regions CHECK (station_location NOT IN ('Kigali Central', 'Kigali North', 'Kigali South', 'Kigali East', 'Kigali West'))
);

-- Driver table - Drivers with violations outside Kigali
CREATE TABLE IF NOT EXISTS node_b_regions.driver (
    driver_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(20) UNIQUE NOT NULL,
    date_of_birth DATE,
    address VARCHAR(200),
    phone_number VARCHAR(15),
    email VARCHAR(100),
    license_expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicle table - Vehicles registered outside Kigali
CREATE TABLE IF NOT EXISTS node_b_regions.vehicle (
    vehicle_id SERIAL PRIMARY KEY,
    driver_id INT NOT NULL REFERENCES node_b_regions.driver(driver_id) ON DELETE CASCADE,
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50),
    make VARCHAR(50),
    model VARCHAR(50),
    year INT,
    color VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Violation table - Violations recorded outside Kigali
CREATE TABLE IF NOT EXISTS node_b_regions.violation (
    violation_id SERIAL PRIMARY KEY,
    officer_id INT NOT NULL REFERENCES node_b_regions.officer(officer_id),
    driver_id INT NOT NULL REFERENCES node_b_regions.driver(driver_id),
    vehicle_id INT NOT NULL REFERENCES node_b_regions.vehicle(vehicle_id),
    violation_type VARCHAR(100) NOT NULL,
    violation_date DATE NOT NULL,
    violation_time TIME,
    location VARCHAR(200),
    description TEXT,
    severity_level VARCHAR(20) CHECK (severity_level IN ('Minor', 'Moderate', 'Severe')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_violation_regions CHECK (location NOT LIKE '%Kigali%')
);

-- Fine table - Fines for violations outside Kigali
CREATE TABLE IF NOT EXISTS node_b_regions.fine (
    fine_id SERIAL PRIMARY KEY,
    violation_id INT NOT NULL REFERENCES node_b_regions.violation(violation_id),
    amount_rwf DECIMAL(10, 2) NOT NULL,
    fine_date DATE NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Unpaid' CHECK (status IN ('Unpaid', 'Paid', 'Overdue', 'Waived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment table - Payments for fines outside Kigali
CREATE TABLE IF NOT EXISTS node_b_regions.payment (
    payment_id SERIAL PRIMARY KEY,
    fine_id INT NOT NULL REFERENCES node_b_regions.fine(fine_id),
    payment_date DATE NOT NULL,
    amount_paid_rwf DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50),
    transaction_reference VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_node_b_violation_date ON node_b_regions.violation(violation_date);
CREATE INDEX idx_node_b_violation_location ON node_b_regions.violation(location);
CREATE INDEX idx_node_b_fine_status ON node_b_regions.fine(status);
CREATE INDEX idx_node_b_driver_id ON node_b_regions.driver(driver_id);

-- Add comments for documentation
COMMENT ON SCHEMA node_b_regions IS 'Node B: Other Regions - Horizontal fragmentation of traffic violations database';
COMMENT ON TABLE node_b_regions.violation IS 'Violations recorded outside Kigali region';
COMMENT ON TABLE node_b_regions.fine IS 'Fines for violations outside Kigali region';

-- Verify schema creation
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'node_b_regions';

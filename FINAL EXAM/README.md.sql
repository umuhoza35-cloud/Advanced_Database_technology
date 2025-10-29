
 UMUHOZA Marie Justine 
Reg number: 223027308
  Advanced Database Technology Final Exam- README file

#  Case study: Smart Traffic Violations - Rwanda

Project Description 
A comprehensive distributed database system for managing traffic violations in Rwanda, implementing advanced PostgreSQL features including horizontal fragmentation, distributed queries, recursive hierarchies, and business rule enforcement.

This project demonstrates 10 advanced database answers (A1-A5, B1-B5) for managing traffic violations with:
•	Distributed Database Architecture (Node A and Node B)
•	Horizontal Fragmentationwith UNION ALL recombination
•	Foreign Data Wrappers (PostgreSQL's database link equivalent)
•	Advanced SQL Features Recursive CTEs, triggers, constraints
•	Business Rule Enforcement with functions and triggers

1.  Core Tables
•	Vehicle**: Vehicle registration information
•	Officer**: Traffic police officer details
•	Violation_A / Violation_B**: Horizontally fragmented violation records
•	Fine**: Penalty information for violations
•	Payment**: Payment transactions for fines

2. Supporting Tables
•	Fine_AUDIT**: Audit trail for fine updates
•	HIER**: Hierarchical region structure
•	TRIPLE**: Knowledge base for transitive inference
•	BUSINESS_LIMITS**: Configurable business rules

 This project is analysed in two main sections A and B 

A-Series: Distributed and Parallel Database Tasks


A1. Distributed Schema Design and Fragmentation

 This part focused on splitting the SmartTrafficRwandaDB database into two nodes, Node_A and Node_B, to simulate a distributed environment. The goal was to demonstrate how data can be divided horizontally between locations. Node_A and Node_B store different subsets of violation data. After inserting 10 rows (5 per node), validation queries confirmed that data from both nodes could be recombined correctly using the UNION ALL view. The total row count and checksum tests confirmed integrity across the distributed setup.

CREATE OR REPLACE VIEW Violation_ALL AS
SELECT violation_id, plate_number, officer_id, violation_type, 
       violation_date, location, speed_limit, recorded_speed, status,
       'Node_A' as source_node
FROM Violation_A
UNION ALL
SELECT violation_id, plate_number, officer_id, violation_type,
       violation_date, location, speed_limit, recorded_speed, status,
       'Node_B' as source_node
FROM Violation_B;

Purpose: To design a horizontally fragmented database across two logical nodes (Node_A and Node_B) representing different data sites.

A1.1: The schema is divided into Violation_A (Node_A) and Violation_B (Node_B). A deterministic fragmentation rule assigns violations to different nodes.

A1.2: Inserts ≤10 total rows (e.g., 5 per node) to test data distribution consistency across fragments.

A1.3–A1.4: Validation queries check that the combined rows from both fragments match totals in the Violation_ALL view, ensuring correct fragmentation and recombination. Checksum validation confirms data integrity.
   


A2. Database Link and Cross-Node Join
   
This task simulated database links using PostgreSQL’s postgres_fdw. The setup allowed Node_A to access data stored in Node_B, effectively imitating Oracle’s remote connections. Remote SELECT queries retrieved vehicle information, while distributed joins combined local and remote data. The results demonstrated that queries could seamlessly integrate information from multiple nodes, validating the concept of a distributed database system.

   A2.1–A2.2: postgres_fdw connects Node_A to Node_B. Remote SELECT statements show how data from Vehicle on Node_B can be queried from Node_A.

A2.3: Demonstrates distributed joins between local and remote tables (Violation_A with Officer or Violation_B) and aggregation across nodes. It validates inter-node query execution and distributed computation capability.


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
 

A3. Parallel vs. Serial Aggregation

Parallel query execution was enabled to show how PostgreSQL can speed up operations on large datasets. Serial aggregation processed queries in a single thread, while parallel aggregation used multiple worker processes to handle data faster. The results showed that while small datasets run efficiently in serial mode, larger ones benefit greatly from parallel execution. Execution plans and performance comparisons supported this finding.

Purpose: To measure query performance improvement using PostgreSQL’s parallel query execution.

A3.1: Serial aggregation executes in one process, showing base performance.

A3.2: Parallel aggregation uses multiple worker processes to reduce execution time for large datasets.

A3.3: Execution plans (EXPLAIN ANALYZE) compare serial vs parallel modes.

A3.4: A comparison table summarizes results, showing that parallel mode benefits larger workloads while serial suits small data.
   

A4. Two-Phase Commit and Recovery

This part illustrated how PostgreSQL ensures data consistency during distributed transactions. The two-phase commit (2PC) process was implemented using PREPARE TRANSACTION and COMMIT PREPARED commands. The test confirmed that transactions either fully commit or fully roll back across both nodes, preserving atomicity. The recovery queries showed no pending transactions, meaning the system reached full consistency after all operations.

 Purpose: To demonstrate atomic distributed transactions ensuring data consistency across nodes.

A4.1–A4.2: One transaction inserts a local record and prepares it (PREPARE TRANSACTION).

A4.3: Queries pg_prepared_xacts to list transactions pending commit.

A4.4: Confirms when no pending transactions remain, indicating full commit or rollback.

A4.5: Final consistency checks verify that data in Fine and Violation tables align, ensuring 2PC worked correctly.

   SELECT 'Fragment A Count' as source, COUNT(*) as row_count FROM Violation_A
UNION ALL
SELECT 'Fragment B Count', COUNT(*) FROM Violation_B
UNION ALL
SELECT 'Union View Count', COUNT(*) FROM Violation_ALL;

-- Checksum validation (using MOD 97 on primary key)
SELECT 'Fragment A Checksum' as source, 
       SUM(MOD(violation_id, 97)) as checksum,
       COUNT(*) as row_count
FROM Violation_A
UNION ALL
SELECT 'Fragment B Checksum',
       SUM(MOD(violation_id, 97)),
       COUNT(*)
FROM Violation_B
UNION ALL
SELECT 'Union View Checksum',
       SUM(MOD(violation_id, 97)),
       COUNT(*)
FROM Violation_ALL;

-- Display all violations with source node
SELECT * FROM Violation_ALL ORDER BY violation_date;

   

A5. Distributed Lock Conflict

Two database sessions were run simultaneously to test how PostgreSQL handles concurrent updates. Session 1 locked a Fine record while Session 2 attempted to modify it, resulting in a blocking situation. Using pg_stat_activity, the lock conflict was identified, showing PostgreSQL’s ability to prevent conflicting updates. Once Session 1 released the lock, Session 2 completed successfully, demonstrating effective concurrency control.

Purpose: To test concurrency control by simulating simultaneous updates on shared data.

A5.1–A5.2: Two sessions attempt to update the same Fine record, creating a lock conflict.

A5.3: pg_stat_activity identifies blocking and waiting processes.

A5.4: Releasing the lock shows that once Session 1 commits, Session 2 completes successfully—demonstrating PostgreSQL’s transaction isolation and locking mechanism.


  SELECT 
    'Violations without Fines' as check_type,
    COUNT(*) as count
FROM Violation_A v
LEFT JOIN Fine f ON v.violation_id = f.violation_id
WHERE f.fine_id IS NULL
UNION ALL
SELECT 
    'Total Violations',
    COUNT(*)
FROM Violation_A
UNION ALL
SELECT 
    'Total Fines',
    COUNT(*)
FROM Fine;

-- Display final committed data
SELECT 
    v.violation_id,
    v.violation_type,
    v.plate_number,
    f.fine_id,
    f.amount,
    f.status as fine_status
FROM Violation_A v
LEFT JOIN Fine f ON v.violation_id = f.violation_id
ORDER BY v.violation_id DESC
LIMIT 5;


B-Series: Declarative Constraints, Triggers, and Business Logic
B1. Declarative Rules Hardening

This task enforced stronger data integrity rules using constraints on the Payment table. Rules were added to prevent future payment dates, ensure positive amounts, and limit payment methods to valid types. Error-handling procedures confirmed that incorrect entries were rejected, while valid data was successfully inserted. Validation queries proved that only correct and compliant rows were committed to the database.

Purpose: To enforce strict data integrity using CHECK and NOT NULL constraints.

B1.1: Adds rules on Payment table ensuring valid amount, non-future date, and allowed payment methods.

B1.3: Error-handling scripts show that invalid inserts (future dates, overpayments) are rejected.

B1.4: Verification queries confirm only valid rows were committed into Fine and Payment.
   
An Event–Condition–Action (ECA) trigger was implemented to automatically update the total amount paid for each fine. Whenever a payment was inserted, updated, or deleted, the Fine table’s total was recalculated to stay consistent. This automation minimized manual updates and ensured that Fine and Payment data remained synchronized. Audit logs confirmed that updates occurred correctly after each transaction.

B3. Recursive Hierarchy Roll-Up

A recursive hierarchy model was created to represent Rwanda’s administrative divisions, from the country level down to the sector. The recursive SQL query (WITH RECURSIVE) traced relationships between parent and child entities. The result successfully displayed hierarchical paths, showing how PostgreSQL can manage multi-level data structures. The task also reused seed data to verify relationships and data completeness.

B4. Mini Knowledge Base with Transitive Inference

This section established a mini knowledge base using triples (subject, predicate, object) to model relationships among different traffic violations. Logical connections such as “Speeding is a MovingViolation” were inserted. Recursive inference queries successfully derived indirect relationships, proving that PostgreSQL can perform semantic reasoning—useful for categorizing and analyzing traffic offenses.

B5. Business Limit Alert (Function + Trigger)

The final section implemented automated business rule enforcement. Thresholds for maximum and minimum payments and fines were defined in a BUSINESS_LIMITS table. Functions and triggers checked each transaction before insertion. Invalid payments and fines (those exceeding or below limits) triggered errors and were rejected, while valid ones passed successfully. Verification queries showed only approved transactions, demonstrating a robust control mechanism for financial compliance.



SELECT 
        s as subtype,
        o as supertype,
        1 as distance,
        ARRAY[s, o] as path
    FROM TRIPLE
    WHERE p = 'isA'
   -- B10: Business Limit Alert (Function + Trigger) (row-budget safe)
-- =================================================================

-- STEP 1: Seed business limits table
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
    SELECT threshold, active 
    INTO v_threshold, v_active
    FROM BUSINESS_LIMITS
    WHERE rule_key = p_rule_key;
    
    -- If rule doesn't exist or is inactive, allow
    IF NOT FOUND OR v_active = 'N' THEN
        RETURN 0;
    END IF;
    
    -- Check specific rules
    IF p_rule_key = 'MAX_DAILY_PAYMENT' THEN
        -- Check if payment exceeds daily limit
        IF p_test_amount > v_threshold THEN
            RETURN 1;  -- Alert: exceeds limit
        END IF;
        
    ELSIF p_rule_key = 'MAX_FINE_AMOUNT' THEN
        -- Check if fine amount exceeds maximum
        IF p_test_amount > v_threshold THEN
            RETURN 1;  -- Alert: exceeds limit
        END IF;
        
    ELSIF p_rule_key = 'MIN_PAYMENT_AMOUNT' THEN
        -- Check if payment is below minimum
        IF p_test_amount < v_threshold THEN
            RETURN 1;  -- Alert: below minimum
        END IF;
    END IF;
    
    RETURN 0;  -- No alert
END;
$$ LANGUAGE plpgsql;

-- STEP 3: Create trigger function for Payment table
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

-- STEP 6: Test cases

-- Test 1: Payment BELOW minimum (SHOULD FAIL)
DO $$
BEGIN
    INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
    VALUES (1, CURRENT_TIMESTAMP, 500.00, 'Cash', 'TEST-FAIL-MIN-' || gen_random_uuid());
    
    RAISE NOTICE 'ERROR: Below-minimum payment was accepted!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'PASS: Below-minimum payment rejected - %', SQLERRM;
        ROLLBACK;
END $$;

-- Test 2: Payment ABOVE maximum (SHOULD FAIL)
DO $$
BEGIN
    INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
    VALUES (1, CURRENT_TIMESTAMP, 600000.00, 'Bank Transfer', 'TEST-FAIL-MAX-' || gen_random_uuid());
    
    RAISE NOTICE 'ERROR: Above-maximum payment was accepted!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'PASS: Above-maximum payment rejected - %', SQLERRM;
        ROLLBACK;
END $$;

-- Test 3: Valid payment within limits (SHOULD PASS)
BEGIN;
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
VALUES (1, CURRENT_TIMESTAMP, 50000.00, 'Mobile Money', 'TEST-PASS-1-' || gen_random_uuid());
RAISE NOTICE 'PASS: Valid payment accepted';
COMMIT;

-- Test 4: Another valid payment (SHOULD PASS)
BEGIN;
INSERT INTO Payment (fine_id, payment_date, amount, payment_method, reference_number)
VALUES (1, CURRENT_TIMESTAMP, 25000.00, 'Cash', 'TEST-PASS-2-' || gen_random_uuid());
RAISE NOTICE 'PASS: Valid payment accepted';
COMMIT;

-- Test 5: Fine ABOVE maximum (SHOULD FAIL)
DO $$
BEGIN
    INSERT INTO Fine (violation_id, amount, due_date, status)
    VALUES (1, 1500000.00, CURRENT_DATE + 30, 'UNPAID');
    
    RAISE NOTICE 'ERROR: Excessive fine was accepted!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'PASS: Excessive fine rejected - %', SQLERRM;
        ROLLBACK;
END $$;

-- Test 6: Valid fine within limits (SHOULD PASS)
BEGIN;
INSERT INTO Fine (violation_id, amount, due_date, status)
VALUES (2, 75000.00, CURRENT_DATE + INTERVAL '30 days', 'UNPAID');
RAISE NOTICE 'PASS: Valid fine accepted';
COMMIT;

-- STEP 7: Verification

-- Show business limits
SELECT 
    rule_key,
    threshold,
    active,
    description,
    CASE active
        WHEN 'Y' THEN 'Enforced'
        ELSE 'Disabled'

Overall Summary

This Smart Traffic Violation Monitoring System project demonstrated advanced PostgreSQL capabilities in managing distributed and parallel databases. It covered schema fragmentation, foreign data access, parallel execution, two-phase commits, concurrency handling, declarative integrity, triggers, recursive queries, and business rule enforcement. Each step validated PostgreSQL’s strength in ensuring performance, consistency, and accuracy across multiple database nodes.
   



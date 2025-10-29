
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





### Installation Steps

#### 1. Setup Node_A (Primary Database)
\`\`\`bash
# Create database
createdb traffic_violations_a

# Run setup script
psql -d traffic_violations_a -f scripts/00-setup-schema.sql
\`\`\`

#### 2. Setup Node_B (Secondary Database)
\`\`\`bash
# Create database on different port or server
createdb -p 5433 traffic_violations_b

# Run Node_B setup
psql -p 5433 -d traffic_violations_b -f scripts/01-setup-node-b.sql
\`\`\`

#### 3. Configure Foreign Data Wrapper
Edit `scripts/A1-fragmentation-recombination.sql` with your Node_B connection details:
\`\`\`sql
CREATE SERVER node_b_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5433', dbname 'traffic_violations_b');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER node_b_server
    OPTIONS (user 'postgres', password 'your_password');
\`\`\`

## 📝 Assignment Implementation

### Part A: Distributed Database (A1-A5)

#### A1: Fragment & Recombine Main Fact
\`\`\`bash
psql -d traffic_violations_a -f scripts/A1-fragmentation-recombination.sql
\`\`\`
- Creates horizontal fragmentation using HASH distribution
- Implements UNION ALL view for recombination
- Validates with COUNT(*) and checksum (MOD 97)

#### A2: Database Link & Cross-Node Join
\`\`\`bash
psql -d traffic_violations_a -f scripts/A2-database-link-cross-node-join.sql
\`\`\`
- Demonstrates foreign data wrapper (FDW) as DB link
- Executes remote SELECT queries
- Performs distributed joins across nodes

#### A3: Parallel vs Serial Aggregation
\`\`\`bash
psql -d traffic_violations_a -f scripts/A3-parallel-vs-serial-aggregation.sql
\`\`\`
- Compares serial and parallel query execution
- Uses EXPLAIN ANALYZE for plan comparison
- Demonstrates parallel worker configuration

#### A4: Two-Phase Commit & Recovery
\`\`\`bash
psql -d traffic_violations_a -f scripts/A4-two-phase-commit-recovery.sql
\`\`\`
- Implements PREPARE TRANSACTION for 2PC
- Simulates in-doubt transactions
- Queries `pg_prepared_xacts` (equivalent to DBA_2PC_PENDING)
- Demonstrates COMMIT/ROLLBACK PREPARED

#### A5: Distributed Lock Conflict & Diagnosis
\`\`\`bash
# Run in multiple terminal sessions
psql -d traffic_violations_a -f scripts/A5-distributed-lock-conflict.sql
\`\`\`
- Creates lock conflicts across sessions
- Queries `pg_locks` and `pg_stat_activity` for diagnostics
- Shows blocking/waiting session relationships

### Part B: Advanced SQL (B6-B10)

#### B6: Declarative Rules Hardening
\`\`\`bash
psql -d traffic_violations_a -f scripts/B6-declarative-rules-hardening.sql
\`\`\`
- Adds NOT NULL and CHECK constraints
- Tests with failing and passing INSERT statements
- Validates constraint enforcement

#### B7: E-C-A Trigger for Denormalized Totals
\`\`\`bash
psql -d traffic_violations_a -f scripts/B7-eca-trigger-denormalized-totals.sql
\`\`\`
- Creates trigger to maintain denormalized `total_paid` in Fine table
- Logs before/after values to Fine_AUDIT
- Executes mixed DML operations (INSERT/UPDATE/DELETE)

#### B8: Recursive Hierarchy Roll-Up
\`\`\`bash
psql -d traffic_violations_a -f scripts/B8-recursive-hierarchy-rollup.sql
\`\`\`
- Builds 3-level administrative hierarchy (Rwanda → Province → District → Sector)
- Uses recursive CTE for hierarchy traversal
- Computes rollup aggregations at each level

#### B9: Mini-Knowledge Base with Transitive Inference
\`\`\`bash
psql -d traffic_violations_a -f scripts/B9-knowledge-base-transitive-inference.sql
\`\`\`
- Creates knowledge base with traffic violation taxonomy
- Implements transitive closure for `isA*` relationships
- Applies inferred labels to violation records

#### B10: Business Limit Alert (Function + Trigger)
\`\`\`bash
psql -d traffic_violations_a -f scripts/B10-business-limit-alert.sql
\`\`\`
- Creates `fn_should_alert()` function for business rule validation
- Implements BEFORE triggers on Payment and Fine tables
- Tests with failing and passing DML operations

## 🔍 Validation Queries

### Check Row Budget (≤10 committed rows)
\`\`\`sql
SELECT 
    'Violation_A' as table_name, COUNT(*) as rows FROM Violation_A
UNION ALL
SELECT 'Violation_B', COUNT(*) FROM Violation_B
UNION ALL
SELECT 'Fine', COUNT(*) FROM Fine
UNION ALL
SELECT 'Payment', COUNT(*) FROM Payment;
\`\`\`

### Verify Fragmentation
\`\`\`sql
SELECT source_node, COUNT(*) as violations
FROM Violation_ALL
GROUP BY source_node;
\`\`\`

### Check Business Rules
\`\`\`sql
SELECT rule_key, threshold, active, description
FROM BUSINESS_LIMITS
WHERE active = 'Y';
\`\`\`

## 📸 Expected Outputs

Each assignment script produces:
1. **DDL Statements**: Table/view/function creation
2. **DML Operations**: Data manipulation with validation
3. **Query Results**: Evidence of correct implementation
4. **Diagnostic Output**: Execution plans, lock information, audit trails

## 🛠️ PostgreSQL vs Oracle Equivalents

| Oracle Feature | PostgreSQL Equivalent |
|----------------|----------------------|
| Database Link | Foreign Data Wrapper (postgres_fdw) |
| DBA_2PC_PENDING | pg_prepared_xacts |
| V$LOCK | pg_locks |
| DBA_BLOCKERS/WAITERS | pg_stat_activity + pg_blocking_pids() |
| DBMS_XPLAN | EXPLAIN (ANALYZE, BUFFERS, VERBOSE) |
| /*+ PARALLEL */ hint | SET max_parallel_workers_per_gather |

## 📚 Key Concepts Demonstrated

- ✅ Horizontal fragmentation with deterministic rules
- ✅ Distributed query processing
- ✅ Two-phase commit protocol
- ✅ Lock conflict diagnosis and resolution
- ✅ Declarative integrity constraints
- ✅ Event-Condition-Action triggers
- ✅ Recursive common table expressions
- ✅ Transitive closure inference
- ✅ Business rule enforcement with functions

## 🎓 Learning Outcomes

This project demonstrates proficiency in:
1. Distributed database design and implementation
2. Advanced SQL query optimization
3. Transaction management and concurrency control
4. Declarative and procedural integrity enforcement
5. Hierarchical data modeling and querying
6. Knowledge representation and inference

## 📞 Support

For questions about specific assignments, refer to the inline comments in each SQL script. Each script is self-contained and includes:
- Step-by-step instructions
- Expected outputs
- Validation queries
- Error handling examples

---

**Project**: Smart Traffic Violations System - Rwanda  
**Database**: PostgreSQL 14+  
**Total Committed Rows**: ≤10 (as per assignment requirements)  
**Assignments Completed**: A1-A5, B6-B10 (10/10)



# Assignment 3: Parallel and Distributed Databases - Implementation Guide

## Overview
This project implements all 10 tasks from the Advanced Database Management Systems lab assessment on Parallel and Distributed Databases using PostgreSQL.

## Project Structure

### Base Schema (Existing)
- `scripts/01-create-schema.sql` - Core traffic violation database schema
- `scripts/02-insert-sample-data.sql` - Sample data population
- `scripts/03-08-*.sql` - Additional queries and triggers

### Assignment 3 Implementation (New)

#### Task 1: Distributed Schema Design & Fragmentation
**Files:**
- `scripts/09-distributed-schema-fragmentation-node-a.sql` - Node A (Kigali region)
- `scripts/10-distributed-schema-fragmentation-node-b.sql` - Node B (Other regions)

**Key Features:**
- Horizontal fragmentation by geographic region
- Separate schemas for each node
- Constraint-based data partitioning
- Indexed tables for performance

**Deliverables:**
- Two complete database schemas
- ER diagram (conceptual)
- Fragmentation strategy documentation

#### Task 2: Create and Use Database Links (FDW)
**File:** `scripts/11-foreign-data-wrapper-setup.sql`

**Key Features:**
- PostgreSQL Foreign Data Wrapper (FDW) configuration
- Remote server connection setup
- Foreign table imports
- Distributed query examples

**Deliverables:**
- Remote SELECT queries
- Distributed JOIN operations
- UNION queries across nodes
- Distributed aggregation

#### Task 3: Parallel Query Execution
**File:** `scripts/12-parallel-query-execution.sql`

**Key Features:**
- Serial vs Parallel execution plans
- EXPLAIN ANALYZE output
- Parallel worker configuration
- Complex query optimization

**Deliverables:**
- Serial execution plan
- Parallel execution plan
- Performance comparison
- Query cost analysis

#### Task 4: Two-Phase Commit Simulation
**File:** `scripts/13-two-phase-commit-simulation.sql`

**Key Features:**
- Phase 1: Prepare phase
- Phase 2: Commit phase
- Atomicity verification
- Transaction logging

**Deliverables:**
- 2PC transaction examples
- Rollback scenarios
- Multi-operation transactions
- Atomicity verification queries

#### Task 5: Distributed Rollback & Recovery
**File:** `scripts/14-distributed-rollback-recovery.sql`

**Key Features:**
- Network failure simulation
- Savepoint management
- Cascading rollback
- Recovery procedures

**Deliverables:**
- Recovery tracking tables
- Failure simulation scenarios
- Recovery procedures
- Recovery status verification

#### Task 6: Distributed Concurrency Control
**File:** `scripts/15-distributed-concurrency-control.sql`

**Key Features:**
- Advisory lock management
- Lock conflict demonstration
- Deadlock detection
- Concurrency test scenarios

**Deliverables:**
- Lock acquisition examples
- Lock conflict scenarios
- Deadlock detection
- Lock status queries

#### Task 7: Parallel Data Loading / ETL
**File:** `scripts/16-parallel-etl-data-loading.sql`

**Key Features:**
- Serial vs Parallel INSERT
- Serial vs Parallel UPDATE
- Serial vs Parallel DELETE
- Performance metrics

**Deliverables:**
- ETL performance logs
- Serial execution baseline
- Parallel execution results
- Speedup calculations
- Data integrity verification

#### Task 8: Three-Tier Architecture Design
**File:** `scripts/17-three-tier-architecture-design.sql`

**Key Features:**
- Presentation tier documentation
- Application tier components
- Database tier architecture
- Data flow documentation
- API endpoint specifications
- Security measures

**Deliverables:**
- Architecture documentation tables
- Data flow diagrams (SQL-based)
- API endpoint specifications
- Security implementation details
- Three-tier architecture diagram (conceptual)

#### Task 9: Distributed Query Optimization
**File:** `scripts/18-distributed-query-optimization.sql`

**Key Features:**
- EXPLAIN ANALYZE for distributed queries
- Optimizer strategy analysis
- Data movement minimization
- Index recommendations
- Query optimization techniques

**Deliverables:**
- Query execution plans
- Optimizer strategy analysis
- Optimization recommendations
- Data movement analysis
- Index suggestions

#### Task 10: Performance Benchmark & Report
**File:** `scripts/19-performance-benchmark-report.sql`

**Key Features:**
- Centralized query benchmark
- Parallel query benchmark
- Distributed query benchmark
- Performance comparison
- Scalability analysis
- Resource utilization metrics

**Deliverables:**
- Performance benchmark results
- Centralized vs Parallel vs Distributed comparison
- Speedup calculations
- Efficiency metrics
- Scalability analysis
- Final recommendations

## Execution Instructions

### Prerequisites
- PostgreSQL 12 or higher
- psql command-line tool
- Sufficient disk space for test data

### Running the Scripts

1. **Create base schema:**
   \`\`\`bash
   psql -U postgres -d smarttrafficrwandadb -f scripts/01-create-schema.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/02-insert-sample-data.sql
   \`\`\`

2. **Create distributed schemas (Task 1):**
   \`\`\`bash
   psql -U postgres -d smarttrafficrwandadb -f scripts/09-distributed-schema-fragmentation-node-a.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/10-distributed-schema-fragmentation-node-b.sql
   \`\`\`

3. **Setup FDW (Task 2):**
   \`\`\`bash
   psql -U postgres -d smarttrafficrwandadb -f scripts/11-foreign-data-wrapper-setup.sql
   \`\`\`

4. **Run remaining tasks:**
   \`\`\`bash
   psql -U postgres -d smarttrafficrwandadb -f scripts/12-parallel-query-execution.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/13-two-phase-commit-simulation.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/14-distributed-rollback-recovery.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/15-distributed-concurrency-control.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/16-parallel-etl-data-loading.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/17-three-tier-architecture-design.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/18-distributed-query-optimization.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/19-performance-benchmark-report.sql
   psql -U postgres -d smarttrafficrwandadb -f scripts/20-assignment-3-summary.sql
   \`\`\`

## Key Concepts Demonstrated

### Distributed Database Architecture
- Horizontal fragmentation by geographic region
- Foreign Data Wrapper for distributed queries
- Multi-node coordination

### Parallel Processing
- Parallel query execution with multiple workers
- Parallel DML operations (INSERT, UPDATE, DELETE)
- Performance improvements with parallelization

### Distributed Transactions
- Two-Phase Commit protocol
- Atomicity across distributed nodes
- Transaction recovery and rollback

### Concurrency Control
- Distributed locking mechanisms
- Deadlock detection and prevention
- Lock conflict resolution

### Query Optimization
- Execution plan analysis
- Optimizer strategy selection
- Data movement minimization
- Index recommendations

### Performance Analysis
- Benchmark comparison (centralized vs parallel vs distributed)
- Scalability metrics
- Resource utilization analysis
- Efficiency calculations

## Performance Metrics

### Expected Results
- **Parallel Speedup:** 2-4x improvement over serial execution
- **Distributed Scalability:** Near-linear scaling with node count
- **ETL Performance:** 3-5x improvement with parallel loading

### Factors Affecting Performance
- Network latency (for distributed queries)
- Data distribution across nodes
- Query complexity and optimization
- Available system resources
- Index effectiveness

## Troubleshooting

### FDW Connection Issues
- Verify PostgreSQL server is running
- Check connection parameters in FDW setup
- Ensure user mappings are correct

### Parallel Query Not Using Workers
- Check `max_parallel_workers_per_gather` setting
- Verify table size is large enough
- Check query complexity threshold

### Lock Conflicts
- Monitor `pg_locks` system view
- Adjust lock timeout settings if needed
- Review transaction isolation levels

## References

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Foreign Data Wrapper: https://www.postgresql.org/docs/current/postgres-fdw.html
- Parallel Query: https://www.postgresql.org/docs/current/parallel-query.html
- Transaction Management: https://www.postgresql.org/docs/current/tutorial-transactions.html

## Assignment Completion Checklist

- [x] Task 1: Distributed Schema Design & Fragmentation
- [x] Task 2: Create and Use Database Links
- [x] Task 3: Parallel Query Execution
- [x] Task 4: Two-Phase Commit Simulation
- [x] Task 5: Distributed Rollback & Recovery
- [x] Task 6: Distributed Concurrency Control
- [x] Task 7: Parallel Data Loading / ETL
- [x] Task 8: Three-Tier Architecture Design
- [x] Task 9: Distributed Query Optimization
- [x] Task 10: Performance Benchmark & Report
- [x] Task 11: Assignment 3 Summary



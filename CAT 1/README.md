# Smart Traffic Violation Monitoring System — **SmartTrafficRwandaDB**

A PostgreSQL schema and utility SQL for recording **traffic officers, drivers, vehicles, violations, fines, and payments**, enabling authorities to track violations, apply penalties, and monitor driver compliance.

---

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Entity–Relationship (ER) Overview](#entityrelationship-er-overview)
- [Schema Details](#schema-details)
  - [Officer](#officer)
  - [Driver](#driver)
  - [Vehicle](#vehicle)
  - [Violation](#violation)
  - [Fine](#fine)
  - [Payment](#payment)
- [Constraints & Data Quality](#constraints--data-quality)
- [Indexes](#indexes)
- [Views](#views)
  - [`vw_penalties_by_city`](#vw_penalties_by_city)
  - [`vw_common_violations_by_city`](#vw_common_violations_by_city)
- [Procedures, Functions & Triggers](#procedures-functions--triggers)
  - [`process_payment` function](#process_payment-function)
  - [`update_driver_offense_status` trigger](#update_driver_offense_status-trigger)
  - [`recalculate_all_driver_offenses` function](#recalculate_all_driver_offenses-function)
- [Operational Queries (Reports & Analytics)](#operational-queries-reports--analytics)
- [Sample Workflows](#sample-workflows)
- [Testing Tips](#testing-tips)
- [Troubleshooting](#troubleshooting)
- [Security & Privacy Notes](#security--privacy-notes)
- [Extensibility Ideas](#extensibility-ideas)
- [License](#license)

---

## Overview
This database powers a **Smart Traffic Violation Monitoring System** suitable for deployments in Rwanda (and adaptable elsewhere). It captures:
- **Officers** (who issue violations)
- **Drivers** and their **vehicles**
- **Violations**, **fines**, and **payments**
- Derived **compliance** and **performance** metrics via views and reporting queries

> **PostgreSQL version**: Tested with PostgreSQL 13+ (should work on 12+).

---

## Quick Start

1. **Create database (optional)**
   ```sql
   CREATE DATABASE "SmartTrafficRwandaDB";
   ```

2. **Connect and run the schema script** (order already handled in the script):
   ```bash
   psql -d SmartTrafficRwandaDB -f path/to/schema.sql
   ```

3. **Verify success message**
   ```sql
   SELECT 'Schema created successfully!' AS status;
   ```

4. *(Optional)* **Seed some data** (officers, drivers, vehicles, a few violations & fines) to exercise reports and triggers.

---

## Entity–Relationship (ER) Overview

```
Driver (1) ──< Vehicle (N)
   |
   | Vehicle (1) ──< Violation (N) >── (1) Officer
                            |
                            | (1:1)
                            v
                           Fine (1) ── (1:1) ──> Payment (0..1)
```

- A **Driver** owns one or more **Vehicles**.
- A **Violation** is issued **by** an **Officer** **to** a **Vehicle**.
- Each **Violation** has exactly one **Fine** (enforced by a `UNIQUE` on `Fine.ViolationID`).
- Each **Fine** can have at most one **Payment** (`Payment.FineID` is `UNIQUE`).

---

## Schema Details

### Officer
Stores traffic police officer info.
```sql
CREATE TABLE Officer (
  OfficerID SERIAL PRIMARY KEY,
  FullName  VARCHAR(100) NOT NULL,
  Station   VARCHAR(100) NOT NULL,
  BadgeNo   VARCHAR(20)  UNIQUE NOT NULL,
  Contact   VARCHAR(15)  NOT NULL,
  CONSTRAINT chk_officer_contact CHECK (Contact ~ '^\+?[0-9]{10,15}$')
);
```
*Key points*: unique `BadgeNo`, phone format check, station retained for performance summaries.

### Driver
```sql
CREATE TABLE Driver (
  DriverID     SERIAL PRIMARY KEY,
  FullName     VARCHAR(100) NOT NULL,
  LicenseNo    VARCHAR(20) UNIQUE NOT NULL,
  Contact      VARCHAR(15) NOT NULL,
  City         VARCHAR(50) NOT NULL,
  OffenseCount INT DEFAULT 0,
  IsFlagged    BOOLEAN DEFAULT FALSE,
  CONSTRAINT chk_driver_contact CHECK (Contact ~ '^\+?[0-9]{10,15}$'),
  CONSTRAINT chk_offense_count CHECK (OffenseCount >= 0)
);
```
*Key points*: `OffenseCount` and `IsFlagged` maintained by trigger/function for repeat offenders.

### Vehicle
```sql
CREATE TABLE Vehicle (
  VehicleID SERIAL PRIMARY KEY,
  DriverID  INT NOT NULL REFERENCES Driver(DriverID) ON DELETE CASCADE,
  PlateNo   VARCHAR(20) UNIQUE NOT NULL,
  Type      VARCHAR(50) NOT NULL,
  Status    VARCHAR(20) DEFAULT 'Active',
  CONSTRAINT chk_vehicle_status CHECK (Status IN ('Active','Suspended','Impounded'))
);
```
*Key points*: cascades when driver is deleted; status is constrained.

### Violation
```sql
CREATE TABLE Violation (
  ViolationID SERIAL PRIMARY KEY,
  VehicleID   INT NOT NULL REFERENCES Vehicle(VehicleID) ON DELETE CASCADE,
  OfficerID   INT NOT NULL REFERENCES Officer(OfficerID) ON DELETE CASCADE,
  Date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  Type        VARCHAR(100) NOT NULL,
  Penalty     DECIMAL(10,2) NOT NULL,
  Status      VARCHAR(20) DEFAULT 'Pending',
  CONSTRAINT chk_penalty CHECK (Penalty > 0),
  CONSTRAINT chk_violation_status CHECK (Status IN ('Pending','Paid','Overdue'))
);
```
*Key points*: monetary `Penalty` vs. `Fine.Amount` allow modeling of statutory penalty and billable fine separately.

### Fine
```sql
CREATE TABLE Fine (
  FineID      SERIAL PRIMARY KEY,
  ViolationID INT UNIQUE NOT NULL REFERENCES Violation(ViolationID) ON DELETE CASCADE,
  Amount      DECIMAL(10,2) NOT NULL,
  Status      VARCHAR(20) DEFAULT 'Unpaid',
  DueDate     DATE NOT NULL,
  CONSTRAINT chk_fine_amount CHECK (Amount > 0),
  CONSTRAINT chk_fine_status CHECK (Status IN ('Unpaid','Paid','Overdue'))
);
```
*Key points*: 1:1 to `Violation` via `UNIQUE (ViolationID)`; status lifecycle managed by business logic.

### Payment
```sql
CREATE TABLE Payment (
  PaymentID   SERIAL PRIMARY KEY,
  FineID      INT UNIQUE NOT NULL REFERENCES Fine(FineID) ON DELETE CASCADE,
  Amount      DECIMAL(10,2) NOT NULL,
  PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  Method      VARCHAR(50) NOT NULL,
  CONSTRAINT chk_payment_amount CHECK (Amount > 0),
  CONSTRAINT chk_payment_method CHECK (Method IN ('Cash','Mobile Money','Bank Transfer','Card'))
);
```
*Key points*: one payment per fine. Extendable to partial payments by relaxing the `UNIQUE` and summing amounts.

---

## Constraints & Data Quality
- **Phone numbers**: `^\+?[0-9]{10,15}$` on `Officer.Contact` and `Driver.Contact`.
- **Enumerations** enforced with `CHECK` on:
  - `Violation.Status`: `Pending | Paid | Overdue`
  - `Fine.Status`: `Unpaid | Paid | Overdue`
  - `Vehicle.Status`: `Active | Suspended | Impounded`
  - `Payment.Method`: `Cash | Mobile Money | Bank Transfer | Card`
- **Non-negativity checks** on monetary fields and `OffenseCount`.

---

## Indexes
```sql
CREATE INDEX idx_vehicle_driver   ON Vehicle(DriverID);
CREATE INDEX idx_violation_vehicle ON Violation(VehicleID);
CREATE INDEX idx_violation_officer ON Violation(OfficerID);
CREATE INDEX idx_violation_date    ON Violation(Date);
CREATE INDEX idx_fine_status       ON Fine(Status);
CREATE INDEX idx_driver_city       ON Driver(City);
```
These support common joins and filters for reports and dashboards.

---

## Views

### `vw_penalties_by_city`
Aggregates violations and fines by **Driver.City**, including a **PaymentComplianceRate**.
```sql
SELECT * FROM vw_penalties_by_city;
```

### `vw_common_violations_by_city`
Most frequent violation types and their penalties per city.
```sql
SELECT * FROM vw_common_violations_by_city;
```

---

## Procedures, Functions & Triggers

### `process_payment` function
Automates inserting a payment, marking the **Fine** and **Violation** as `Paid`.
```sql
SELECT process_payment(2, 30000, 'Mobile Money');
```
> **Note**: In production, validate that `p_amount` equals the outstanding amount before marking as `Paid`.

### `update_driver_offense_status` trigger
After **inserting a Violation**, recomputes the driver’s `OffenseCount` and flags `IsFlagged = TRUE` when `>= 3`.
- Created on `Violation` with `AFTER INSERT`.

### `recalculate_all_driver_offenses` function
Manual utility to recompute `OffenseCount` and `IsFlagged` for **all** drivers, useful after bulk loads.

> **Deduplication note**: The source includes duplicated definitions of the **trigger function** and the **recalculate function** blocks. Keep only **one** copy of each in your final script to avoid confusion during maintenance.

---

## Operational Queries (Reports & Analytics)

- **Unpaid fines by driver (summary + details)**  
  Helps collections teams prioritize outreach.
- **Officers issuing the most fines / breakdown by type**  
  For performance oversight and training needs.
- **Overdue fines report**  
  Includes `DaysOverdue` to rank urgency.
- **Revenue by payment method**  
  Track channels (Cash vs. Mobile Money, etc.).
- **Monthly violation trends**  
  For seasonality and forecasting.
- **Vehicle status summary**  
  Operational fleet-state visibility.
- **Driver compliance report**  
  Payment compliance rate and offender flagging.
- **Station performance report**  
  Volume and value of penalties by officer station.

> All of the above are provided as ready‑to‑run SELECT statements in the script.

---

## Sample Workflows

### A. Record a new violation
1. Ensure **Driver**, **Vehicle**, and **Officer** exist.
2. Insert into `Violation` (and `Fine` with `DueDate`).
3. Trigger updates driver `OffenseCount`; views & reports reflect changes.

### B. Process a payment
- **One‑off (inline)** using transaction block in the script:
  ```sql
  BEGIN;
    INSERT INTO Payment (FineID, Amount, Method)
    VALUES (1, 50000, 'Mobile Money');
    UPDATE Fine SET Status = 'Paid' WHERE FineID = 1;
    UPDATE Violation
      SET Status = 'Paid'
      WHERE ViolationID = (SELECT ViolationID FROM Fine WHERE FineID = 1);
  COMMIT;
  ```
- **Reusable** via `process_payment(fine_id, amount, method)`:
  ```sql
  SELECT process_payment(1, 50000, 'Mobile Money');
  ```

### C. Review outcomes
```sql
SELECT v.ViolationID, v.Type, v.Status,
       f.FineID, f.Status AS FineStatus,
       p.PaymentID, p.Amount, p.PaymentDate, p.Method
FROM Violation v
JOIN Fine f   ON v.ViolationID = f.ViolationID
LEFT JOIN Payment p ON f.FineID = p.FineID
WHERE v.ViolationID = 1;
```

---

## Testing Tips
- **Happy path**: create a driver with one vehicle, add three violations; confirm `IsFlagged = TRUE`.
- **Edge cases**:
  - Phone numbers failing the regex should be rejected.
  - Negative or zero monetary amounts should be rejected by `CHECK` constraints.
  - Deleting a **Driver** should cascade to **Vehicle → Violation → Fine → Payment** as designed.
- **Performance smoke tests**: run the provided reports with 10k+ rows to validate index choices.

---

## Troubleshooting
- **“relation already exists”**: The script starts with `DROP TABLE IF EXISTS ... CASCADE;` to allow clean re‑runs.
- **Duplicate function/trigger definitions**: Keep only the **last** (or first) definition; remove duplicates to simplify diffs.
- **Payment not allowed**: Ensure a corresponding **Fine** exists and that `Payment.FineID` remains `UNIQUE` (1:1).

---

## Security & Privacy Notes
- Store only **necessary PII** (driver/officer contacts). Consider masking, data retention policies, and role‑based access in application layers.
- For auditability, consider adding `created_at`, `created_by`, `updated_at`, `updated_by` columns and immutable history tables for sensitive actions.

---

## Extensibility Ideas
- **Partial payments** and payment plans (remove `UNIQUE` from `Payment.FineID` and sum payments).
- **Geo‑tagging** violations (lat/long) for heatmaps.
- **Offense categories** table to standardize `Violation.Type`.
- **Notifications** for impending **DueDate** (scheduled job that flips to `Overdue`).
- **Role-based access control (RBAC)** via PostgreSQL roles and views.
- **JSONB audit trail** for changes to critical tables.

---

## License
Specify your license (e.g., MIT) as needed.

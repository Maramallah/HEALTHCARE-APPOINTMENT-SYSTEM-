# 🏥 Healthcare Appointment System — Database Project

> A full-cycle relational database project covering schema design, transactions, concurrency, recovery, stored procedures, window functions, query optimization, NoSQL integration, and data warehousing with a star schema.

![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-blue?style=flat-square&logo=microsoftsqlserver)
![MongoDB](https://img.shields.io/badge/MongoDB-NoSQL-green?style=flat-square&logo=mongodb)
![Data Warehouse](https://img.shields.io/badge/Data%20Warehouse-Star%20Schema-orange?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [ERD & Schema Design](#2-erd--schema-design)
3. [Relational Tables (Physical Schema)](#3-relational-tables-physical-schema)
4. [Triggers](#4-triggers)
5. [Transactions](#5-transactions)
6. [Concurrency Simulation](#6-concurrency-simulation)
7. [Recovery](#7-recovery)
8. [Stored Procedures](#8-stored-procedures)
9. [SQL Queries](#9-sql-queries)
10. [Window Functions](#10-window-functions)
11. [Query Optimization (Indexing)](#11-query-optimization-indexing)
12. [MongoDB — NoSQL Integration](#12-mongodb--nosql-integration)
13. [Data Warehouse & Star Schema](#13-data-warehouse--star-schema)
14. [Analytical Queries](#14-analytical-queries)
15. [File Structure](#15-file-structure)

---

## 1. Project Overview

This project models a real-world **Healthcare Appointment System** using a full database engineering lifecycle:

- Designing an **ERD** with entity specialization (ISA)
- Implementing a normalized **relational schema** in SQL Server
- Enforcing business rules with **triggers**
- Guaranteeing data integrity through **ACID transactions**
- Simulating **concurrency conflicts** and **recovery scenarios**
- Encapsulating logic in **stored procedures**
- Performing advanced analytics with **window functions**
- Optimizing performance with **indexes**
- Migrating the appointment entity to **MongoDB** with embedded documents
- Building a **data warehouse** with a star schema and **OLAP analytical queries**

### Sample Data

| Entity | Records |
|---|---|
| Patients | Ahmed Ali, Sara Mohamed, Omar Hassan, Mona Khaled |
| Doctors | Dr. John Smith (Cardiology), Dr. Sara Ali (Neurology) |
| Appointments | 4 appointments across May–June 2026 |
| Medications | Panadol 500mg, Aspirin 100mg |

---

## 2. ERD & Schema Design

The Entity-Relationship Diagram captures all entities, attributes, relationships, and constraints of the system.

### Entities & Relationships

| Relationship | Cardinality | Description |
|---|---|---|
| Patient → Appointment | 1 : N | A patient can book many appointments |
| Doctor → Appointment | 1 : N | A doctor is assigned to many appointments |
| Appointment → Prescription | 1 : 1 | Each appointment generates at most one prescription |
| Prescription → Medication | N : M | A prescription contains many medications (via junction table) |
| Patient ISA | Disjoint | A patient is either Inpatient **or** Outpatient — never both |

### Key Constraints

- A doctor **cannot** have two appointments at the same date and time — enforced by a `UNIQUE` constraint on `(Doctor_id, Appointment_date, Appointment_time)`
- Every appointment must reference a valid patient and doctor — enforced by **foreign keys**
- Prescriptions are linked to exactly one appointment
- Medication dosage and instructions are stored in the junction table `Prescription_Medication`

> 📌 See `ERD.png` for the full ERD diagram.

---

## 3. Relational Tables (Physical Schema)

```sql
CREATE TABLE Patient (
    Patient_id    INT PRIMARY KEY,
    Full_Name     VARCHAR(100),
    Gender        VARCHAR(10),
    Date_of_birth DATE,
    Phone         VARCHAR(20)
);

CREATE TABLE Patient_Address (
    Patient_id  INT,
    City_State  VARCHAR(50),
    Street_name VARCHAR(100),
    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id)
);

CREATE TABLE Inpatient (
    Patient_id     INT PRIMARY KEY,
    Admission_date DATE,
    Room_number    INT,
    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id)
);

CREATE TABLE Outpatient (
    Patient_id       INT PRIMARY KEY,
    Registration_num VARCHAR(50),
    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id)
);

CREATE TABLE Doctor (
    Doctor_id   INT PRIMARY KEY,
    Full_name   VARCHAR(100),
    Speciality  VARCHAR(100),
    Phone       VARCHAR(20),
    Email       VARCHAR(100),
    License_num VARCHAR(50)
);

CREATE TABLE Appointment (
    Appointment_id   INT PRIMARY KEY,
    Appointment_date DATE,
    Appointment_time TIME,
    Status           VARCHAR(50),
    Reason_of_visit  VARCHAR(255),
    Patient_id       INT,
    Doctor_id        INT,
    UNIQUE (Doctor_id, Appointment_date, Appointment_time),
    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id),
    FOREIGN KEY (Doctor_id)  REFERENCES Doctor(Doctor_id)
);

CREATE TABLE Prescription (
    Prescription_id INT PRIMARY KEY,
    Date_issued     DATE,
    Notes           TEXT,
    Appointment_id  INT,
    FOREIGN KEY (Appointment_id) REFERENCES Appointment(Appointment_id)
);

CREATE TABLE Medication (
    Medication_id   INT PRIMARY KEY,
    Medication_Name VARCHAR(100)
);

CREATE TABLE Prescription_Medication (
    Prescription_id INT,
    Medication_id   INT,
    Dosage          VARCHAR(50),
    Instructions    TEXT,
    PRIMARY KEY (Prescription_id, Medication_id),
    FOREIGN KEY (Prescription_id) REFERENCES Prescription(Prescription_id),
    FOREIGN KEY (Medication_id)   REFERENCES Medication(Medication_id)
);
```

---

## 4. Triggers

Two `AFTER INSERT` triggers enforce the **disjoint ISA constraint** — a patient cannot be both an Inpatient and an Outpatient simultaneously.

### `trg_inpatient_check`

Fires on `INSERT` into `Inpatient`. If the patient already exists in `Outpatient`, the transaction is rolled back and error `50001` is raised.

```sql
CREATE TRIGGER trg_inpatient_check
ON Inpatient AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Outpatient o ON i.Patient_id = o.Patient_id
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Patient already registered as Outpatient', 1;
    END
END;
```

### `trg_outpatient_check`

Fires on `INSERT` into `Outpatient`. If the patient already exists in `Inpatient`, the transaction is rolled back and error `50002` is raised.

```sql
CREATE TRIGGER trg_outpatient_check
ON Outpatient AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Inpatient p ON i.Patient_id = p.Patient_id
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Patient already registered as Inpatient', 1;
    END
END;
```

> ⚠️ To transfer a patient from Outpatient to Inpatient, you must `DELETE` from Outpatient **first**, then `INSERT` into Inpatient — both inside one transaction.

---

## 5. Transactions

All critical operations are wrapped in explicit `BEGIN TRANSACTION / COMMIT / ROLLBACK` blocks inside `BEGIN TRY...BEGIN CATCH` to guarantee **atomicity**.

### Transaction 1 — Book a New Appointment

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO Appointment
    VALUES (3, '2026-05-02', '11:00', 'Scheduled', 'Consultation', 3, 2);
    COMMIT;
    PRINT 'Appointment booked successfully';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'Error occurred while booking appointment';
END CATCH;
```

### Transaction 2 — Cancel an Appointment

Updates the appointment status to `'Cancelled'`. Rolls back if the update fails.

### Transaction 3 — Register a New Patient

Atomically inserts into `Patient`, `Patient_Address`, and `Outpatient`. All three inserts succeed together or none at all.

### Transaction 4 — Create a Prescription with Medications

Inserts a `Prescription` and multiple `Prescription_Medication` rows together — ensuring no prescription exists without its medications.

### Transaction 5 — Transfer Patient from Outpatient to Inpatient

Deletes from `Outpatient` first (to satisfy the ISA trigger), then inserts into `Inpatient`. Both steps are atomic.

> ✅ All transactions follow **ACID** principles: **A**tomic, **C**onsistent, **I**solated, **D**urable.

---

## 6. Concurrency Simulation

Demonstrates how SQL Server handles **locking and blocking** when two sessions access the same row simultaneously.

### Session 1 — Holds an Exclusive Lock

```sql
BEGIN TRANSACTION;
    UPDATE Appointment
    SET    Status = 'In Progress'
    WHERE  Appointment_id = 2;

    WAITFOR DELAY '00:00:20'; -- keeps the transaction open for 20 seconds
COMMIT;
```

### Session 2 — Blocked (run while Session 1 is waiting)

```sql
-- This SELECT will BLOCK until Session 1 commits or rolls back
SELECT * FROM Appointment WHERE Appointment_id = 2;
```

**Why it blocks:** Session 1 holds an **exclusive (X) lock** on the row. Session 2 requests a **shared (S) lock** for the `SELECT` — which is incompatible, so it waits.

### Session 3 — Monitor Blocking in Real Time

```sql
SELECT
    r.session_id,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time,
    t.text AS query_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id > 0;
```

---

## 7. Recovery

Demonstrates how SQL Server uses the **Write-Ahead Log (WAL)** to recover from errors and crashes.

### Recovery 2A — Constraint Violation Rollback

Intentionally inserts a duplicate appointment (same doctor, date, time) to trigger the `UNIQUE` constraint. The `CATCH` block executes `ROLLBACK`, restoring the database to its pre-transaction state.

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    -- Duplicate: same doctor, date, time → violates UNIQUE constraint
    INSERT INTO Appointment
    VALUES (99, '2026-05-01', '10:00', 'Scheduled', 'Test', 1, 1);
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ROLLBACK executed: ' + ERROR_MESSAGE();
END CATCH;
```

### Recovery 2B — Simulated System Crash

Starts a transaction inserting a 'Ghost Patient' but never commits. Manual `ROLLBACK` simulates crash recovery.

```sql
BEGIN TRANSACTION;
    INSERT INTO Patient VALUES (99, 'Ghost Patient', 'Male', '2000-01-01', '00000000000');
-- Simulate crash: close SSMS without committing
-- SQL Server WAL will UNDO this on restart
ROLLBACK;
PRINT 'Simulated crash recovery: uncommitted transaction was rolled back';
```

**WAL Behavior on Restart:**
- ✅ Committed transactions → **REDONE** (rolled forward)
- ❌ Uncommitted transactions → **UNDONE** (rolled back)

> The Ghost Patient will **not** appear in the database after rollback.

---

## 8. Stored Procedures

### `sp_BookAppointment`

Validates doctor availability and patient existence before booking. Wraps the insert in a transaction.

```sql
EXEC sp_BookAppointment 10, '2026-06-01', '09:00', 'Scheduled', 'Annual Checkup', 3, 2;

-- Test conflict (same doctor, same time slot):
EXEC sp_BookAppointment 11, '2026-06-01', '09:00', 'Scheduled', 'Follow-up', 1, 2;
-- Output: 'Error: Doctor already has an appointment at this time.'
```

**Validation checks:**
- Doctor is not already booked at that exact date and time
- Patient exists in the `Patient` table

### `sp_GetPatientHistory`

Returns the complete history for a given patient — all appointments, doctors, prescriptions, and medications ordered by most recent first.

```sql
EXEC sp_GetPatientHistory 1;
```

**Returns:** Patient name, appointment date/time, status, reason, doctor name & specialty, prescription notes, medication name, dosage, and instructions.

---

## 9. SQL Queries

A comprehensive set of queries covering all common data access patterns:

```sql
-- All scheduled appointments
SELECT * FROM Appointment WHERE Status = 'Scheduled';

-- Full appointment summary (JOIN)
SELECT a.Appointment_id, p.Full_Name AS Patient_Name,
       d.Full_name AS Doctor_Name, a.Appointment_date, a.Status
FROM   Appointment a
JOIN   Patient p ON a.Patient_id = p.Patient_id
JOIN   Doctor  d ON a.Doctor_id  = d.Doctor_id;

-- Appointments per doctor
SELECT d.Full_name, COUNT(a.Appointment_id) AS Total_Appointments
FROM   Doctor d JOIN Appointment a ON d.Doctor_id = a.Doctor_id
GROUP BY d.Doctor_id, d.Full_name
HAVING COUNT(a.Appointment_id) > 1;

-- Inpatient vs Outpatient count
SELECT 'Inpatient'  AS Type, COUNT(*) AS Total FROM Inpatient
UNION ALL
SELECT 'Outpatient' AS Type, COUNT(*) AS Total FROM Outpatient;

-- Medications per prescription
SELECT pr.Prescription_id, m.Medication_Name, pm.Dosage, pm.Instructions
FROM   Prescription_Medication pm
JOIN   Prescription pr ON pm.Prescription_id = pr.Prescription_id
JOIN   Medication   m  ON pm.Medication_id   = m.Medication_id;
```

---

## 10. Window Functions

Window functions perform advanced analytics **without collapsing rows**.

### ROW_NUMBER — Appointment sequence per doctor

```sql
SELECT d.Full_name, p.Full_Name, a.Appointment_date,
       ROW_NUMBER() OVER (
           PARTITION BY a.Doctor_id
           ORDER BY a.Appointment_date, a.Appointment_time
       ) AS Appointment_Number
FROM Appointment a
JOIN Doctor  d ON a.Doctor_id  = d.Doctor_id
JOIN Patient p ON a.Patient_id = p.Patient_id;
```

### RANK — Doctors by total appointments

```sql
SELECT d.Full_name, COUNT(a.Appointment_id) AS Total_Appointments,
       RANK() OVER (ORDER BY COUNT(a.Appointment_id) DESC) AS Doctor_Rank
FROM Doctor d JOIN Appointment a ON d.Doctor_id = a.Doctor_id
GROUP BY d.Doctor_id, d.Full_name;
```

### DENSE_RANK — Patients by visit frequency

Same as `RANK` but without gaps when ties occur.

### LAG / LEAD — Gap between consecutive appointments

```sql
SELECT p.Full_Name, a.Appointment_date,
       LAG(a.Appointment_date)  OVER (PARTITION BY a.Patient_id ORDER BY a.Appointment_date) AS Previous_Appointment,
       LEAD(a.Appointment_date) OVER (PARTITION BY a.Patient_id ORDER BY a.Appointment_date) AS Next_Appointment,
       DATEDIFF(DAY,
           LAG(a.Appointment_date) OVER (PARTITION BY a.Patient_id ORDER BY a.Appointment_date),
           a.Appointment_date
       ) AS Days_Since_Last
FROM Appointment a JOIN Patient p ON a.Patient_id = p.Patient_id;
```

### Running Total — Cumulative appointments per doctor

```sql
SELECT d.Full_name, a.Appointment_date,
       COUNT(a.Appointment_id) OVER (
           PARTITION BY a.Doctor_id
           ORDER BY a.Appointment_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS Running_Total
FROM Appointment a JOIN Doctor d ON a.Doctor_id = d.Doctor_id;
```

---

## 11. Query Optimization (Indexing)

Non-clustered indexes are created on the most frequently filtered and joined columns.

```sql
-- Filter by date and status (most common WHERE clause)
CREATE NONCLUSTERED INDEX IX_Appointment_Date_Status
ON Appointment (Appointment_date, Status);

-- Doctor specialty lookups
CREATE NONCLUSTERED INDEX IX_Doctor_Speciality
ON Doctor (Speciality);

-- Patient gender filters
CREATE NONCLUSTERED INDEX IX_Patient_Gender
ON Patient (Gender);

-- JOIN optimization on Patient_id and Doctor_id
CREATE NONCLUSTERED INDEX IX_Appointment_PatientDoctor
ON Appointment (Patient_id, Doctor_id);
```

**Verifying index usage:**

```sql
SELECT OBJECT_NAME(i.object_id) AS TableName, i.name AS IndexName,
       s.user_seeks, s.user_scans, s.user_lookups, s.last_user_seek
FROM sys.indexes i
JOIN sys.dm_db_index_usage_stats s
     ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Appointment', 'Doctor', 'Patient');
```

> 💡 Use **"Include Actual Execution Plan"** (`Ctrl+M` in SSMS) before and after creating indexes to compare query cost.

---

## 12. MongoDB — NoSQL Integration

The `Appointment` table is converted into a MongoDB collection. Documents **embed** patient and doctor sub-documents directly, eliminating JOINs.

### Document Structure

```js
{
    appointment_id: 1,
    appointment_date: new Date("2026-05-01"),
    appointment_time: "10:00",
    status: "Scheduled",
    reason_of_visit: "Checkup",
    patient: { id: 1, name: "Ahmed Ali", gender: "Male" },
    doctor:  { id: 1, name: "Dr. John Smith", speciality: "Cardiology" }
}
```

### Operations

#### 7A — Insert Documents

```js
db.Appointments.insertMany([...]);
```

#### 7B — Query Documents

```js
// All scheduled appointments
db.Appointments.find({ status: "Scheduled" }).pretty();

// Appointments for a specific doctor
db.Appointments.find({ "doctor.name": "Dr. John Smith" }).pretty();

// Projection: show only patient name, date, status
db.Appointments.find(
    { status: "Scheduled" },
    { "patient.name": 1, appointment_date: 1, status: 1, _id: 0 }
).pretty();

// Count appointments per doctor (aggregation pipeline)
db.Appointments.aggregate([
    { $group: { _id: "$doctor.name", total_appointments: { $sum: 1 } } },
    { $sort: { total_appointments: -1 } }
]);
```

#### 7C — Update Documents

```js
// Update a single appointment status
db.Appointments.updateOne(
    { appointment_id: 2 },
    { $set: { status: "Completed" } }
);

// Add a notes field to all of a doctor's appointments
db.Appointments.updateMany(
    { "doctor.id": 1 },
    { $set: { notes: "Patient must bring previous reports" } }
);
```

#### 7D — Delete Documents

```js
db.Appointments.deleteOne({ appointment_id: 1, status: "Cancelled" });
```

#### 7E — Create Indexes

```js
// Single index on date
db.Appointments.createIndex({ appointment_date: 1 });

// Compound index: doctor + date
db.Appointments.createIndex({ "doctor.id": 1, appointment_date: 1 });
```

> ⚠️ MongoDB uses embedded documents instead of foreign keys. Patient/doctor data may be duplicated across documents — a deliberate trade-off for read performance.

---

## 13. Data Warehouse & Star Schema

The operational OLTP database is transformed into a **data warehouse** optimized for analytical (OLAP) queries using a **Star Schema**.

### Star Schema Diagram

```
          Dim_Patient          Dim_Doctor
              |                    |
Dim_Date ── Fact_Appointment ── Dim_Medication
              |                    |
          Dim_Status           Dim_Reason
```

### Dimension Tables

| Table | Key Columns | Purpose |
|---|---|---|
| `Dim_Patient` | Patient_Key, Full_Name, Gender, Age_Group, City_State | Patient attributes + derived Age_Group |
| `Dim_Doctor` | Doctor_Key, Full_name, Speciality | Doctor attributes |
| `Dim_Date` | Date_Key, Full_Date, Day_Num, Month_Name, Quarter, Year_Num, Weekday_Name | Full date calendar attributes |
| `Dim_Status` | Status_Key, Status_Name | Appointment status descriptors |
| `Dim_Reason` | Reason_Key, Reason_Name | Reason of visit categories |
| `Dim_Medication` | Medication_Key, Medication_Name | Medication reference |

### Fact Table

```sql
CREATE TABLE Fact_Appointment (
    Fact_id            INT PRIMARY KEY IDENTITY(1,1),
    Appointment_id     INT,
    Patient_Key        INT FOREIGN KEY REFERENCES Dim_Patient(Patient_Key),
    Doctor_Key         INT FOREIGN KEY REFERENCES Dim_Doctor(Doctor_Key),
    Date_Key           INT FOREIGN KEY REFERENCES Dim_Date(Date_Key),
    Status_Key         INT FOREIGN KEY REFERENCES Dim_Status(Status_Key),
    Reason_Key         INT FOREIGN KEY REFERENCES Dim_Reason(Reason_Key),
    Medication_Key     INT FOREIGN KEY REFERENCES Dim_Medication(Medication_Key),
    -- MEASURES (numeric, additive)
    Appointment_Count  INT  DEFAULT 1,   -- always 1, used for COUNT aggregations
    Has_Prescription   BIT,             -- 1 = prescription was generated
    Prescription_Count INT  DEFAULT 0,  -- number of prescriptions per appointment
    Medication_Count   INT  DEFAULT 0   -- number of medications per appointment
);
```

### ETL Process

1. Load `Dim_Status` and `Dim_Reason` from distinct values in `Appointment`
2. Load `Dim_Patient` with derived `Age_Group` using `DATEDIFF` + `CASE`
3. Load `Dim_Doctor` from the `Doctor` table
4. Load `Dim_Date` from all distinct appointment dates with full calendar attributes
5. Load `Dim_Medication` from the `Medication` table
6. Load `Fact_Appointment` by joining all operational tables — one row per **appointment × medication** combination

> Appointments without prescriptions get one row with `Medication_Key = NULL` and `Has_Prescription = 0`.

---

## 14. Analytical Queries

Seven OLAP-style queries run against the star schema:

```sql
-- Q1: Total appointments per doctor
SELECT dd.Full_name, dd.Speciality,
       SUM(fa.Appointment_Count) AS Total_Appointments
FROM Fact_Appointment fa JOIN Dim_Doctor dd ON fa.Doctor_Key = dd.Doctor_Key
GROUP BY dd.Full_name, dd.Speciality
ORDER BY Total_Appointments DESC;

-- Q2: Monthly appointment trend
SELECT dt.Year_Num, dt.Month_Name,
       SUM(fa.Appointment_Count) AS Monthly_Total
FROM Fact_Appointment fa JOIN Dim_Date dt ON fa.Date_Key = dt.Date_Key
GROUP BY dt.Year_Num, dt.Month_Num, dt.Month_Name
ORDER BY dt.Year_Num, dt.Month_Num;

-- Q3: Most prescribed medications
SELECT dm.Medication_Name, COUNT(*) AS Times_Prescribed
FROM Fact_Appointment fa JOIN Dim_Medication dm ON fa.Medication_Key = dm.Medication_Key
GROUP BY dm.Medication_Name ORDER BY Times_Prescribed DESC;

-- Q4: Appointment status breakdown
SELECT ds.Status_Name, COUNT(*) AS Total
FROM Fact_Appointment fa JOIN Dim_Status ds ON fa.Status_Key = ds.Status_Key
GROUP BY ds.Status_Name;

-- Q5: Patient × Doctor cross-analysis
SELECT dp.Full_Name AS Patient_Name, dd.Full_name AS Doctor_Name,
       SUM(fa.Appointment_Count) AS Appointments
FROM Fact_Appointment fa
JOIN Dim_Patient dp ON fa.Patient_Key = dp.Patient_Key
JOIN Dim_Doctor  dd ON fa.Doctor_Key  = dd.Doctor_Key
GROUP BY dp.Full_Name, dd.Full_name ORDER BY Appointments DESC;

-- Q6: Prescription rate per doctor
SELECT dd.Full_name,
       SUM(fa.Appointment_Count) AS Total_Appointments,
       SUM(CAST(fa.Has_Prescription AS INT)) AS With_Prescription,
       CAST(SUM(CAST(fa.Has_Prescription AS INT)) * 100.0
            / NULLIF(SUM(fa.Appointment_Count), 0) AS DECIMAL(5,2)) AS Prescription_Rate_Pct
FROM Fact_Appointment fa JOIN Dim_Doctor dd ON fa.Doctor_Key = dd.Doctor_Key
GROUP BY dd.Full_name ORDER BY Prescription_Rate_Pct DESC;

-- Q7: Appointments by patient age group
SELECT dp.Age_Group, SUM(fa.Appointment_Count) AS Total_Appointments
FROM Fact_Appointment fa JOIN Dim_Patient dp ON fa.Patient_Key = dp.Patient_Key
GROUP BY dp.Age_Group ORDER BY Total_Appointments DESC;
```

---

## 15. File Structure

```
healthcare-appointment-system/
│
├── Session1.sql                          # Main SQL file (all sections)
│   ├── Schema creation (tables)
│   ├── Triggers
│   ├── Sample data inserts
│   ├── Transactions (5 scenarios)
│   ├── Concurrency simulation (3 sessions)
│   ├── Recovery demos (2A, 2B)
│   ├── Stored Procedures (sp_BookAppointment, sp_GetPatientHistory)
│   ├── SQL Queries
│   ├── Window Functions (ROW_NUMBER, RANK, DENSE_RANK, LAG/LEAD, Running Total)
│   ├── Query Optimization (indexes)
│   └── Data Warehouse (ETL + star schema + analytical queries)
│
├── mongodb_queries.js                    # MongoDB collection operations (7A–7E)
│
├── Health_care_appointment_system.png    # ERD diagram
├── Screenshot_star_schema.png            # Star schema diagram
│
└── README.md                             # This file
```

---

## 🛠️ How to Run

### SQL Server

1. Open **SSMS** (SQL Server Management Studio)
2. Connect to your SQL Server instance
3. Open `Session1.sql`
4. Run sections top-to-bottom (schema → data → queries → warehouse)
5. For concurrency simulation, open two separate SSMS query windows

### MongoDB

1. Start your MongoDB instance
2. Open **MongoDB Compass** or **mongosh**
3. Run `mongodb_queries.js` section by section
4. The script uses database `HealthcareDB`

---

*Healthcare Appointment System — Database Engineering Project | SQL Server + MongoDB | 2026*

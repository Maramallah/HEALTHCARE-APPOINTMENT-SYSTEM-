-- =====================================================
-- HEALTHCARE APPOINTMENT SYSTEM 
-- =====================================================


CREATE TABLE Patient (
    Patient_id INT PRIMARY KEY,
    Full_Name VARCHAR(100),
    Gender VARCHAR(10),
    Date_of_birth DATE,
    Phone VARCHAR(20)
);
CREATE TABLE Patient_Address (
    Patient_id INT,
    City_State varchar(50),
    Street_name varchar(100),
    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id),
);


CREATE TABLE Inpatient (
    Patient_id INT PRIMARY KEY,
    Admission_date DATE,
    Room_number INT,

    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id)
);

CREATE TABLE Outpatient (
    Patient_id INT PRIMARY KEY,
    Registration_num VARCHAR(50),

    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id)
);



CREATE TABLE Doctor (
    Doctor_id INT PRIMARY KEY,
    Full_name VARCHAR(100),
    Speciality VARCHAR(100),
    Phone VARCHAR(20),
    Email VARCHAR(100),
    License_num VARCHAR(50)
);

CREATE TABLE Appointment (
    Appointment_id INT PRIMARY KEY,
    Appointment_date DATE,
    Appointment_time TIME,
    Status VARCHAR(50),
    Reason_of_visit VARCHAR(255),
    Patient_id INT,
    Doctor_id INT,
    UNIQUE (Doctor_id, Appointment_date, Appointment_time),
    FOREIGN KEY (Patient_id) REFERENCES Patient(Patient_id),
    FOREIGN KEY (Doctor_id) REFERENCES Doctor(Doctor_id)
);

CREATE TABLE Prescription (
    Prescription_id INT PRIMARY KEY,
    Date_issued DATE,
    Notes TEXT,
    Appointment_id INT,
    FOREIGN KEY (Appointment_id) REFERENCES Appointment(Appointment_id)
);

CREATE TABLE Medication (
    Medication_id INT PRIMARY KEY,
    Medication_Name VARCHAR(100)
);


CREATE TABLE Prescription_Medication (
    Prescription_id INT,
    Medication_id INT,
    Dosage VARCHAR(50),
    Instructions TEXT,
    PRIMARY KEY (Prescription_id, Medication_id),
    FOREIGN KEY (Prescription_id) REFERENCES Prescription(Prescription_id),
    FOREIGN KEY (Medication_id) REFERENCES Medication(Medication_id)
);

GO
CREATE TRIGGER trg_inpatient_check
ON Inpatient
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Outpatient o ON i.Patient_id = o.Patient_id
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Patient already registered as Outpatient', 1;
    END
END;
GO
CREATE TRIGGER trg_outpatient_check
ON Outpatient
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Inpatient p ON i.Patient_id = p.Patient_id
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Patient already registered as Inpatient', 1;
    END
END;
GO
INSERT INTO Patient VALUES (1, 'Ahmed Ali', 'Male', '1995-01-10', '01011111111');
INSERT INTO Patient VALUES (2, 'Sara Mohamed', 'Female', '1998-05-20', '01022222222');
INSERT INTO Patient VALUES (3, 'Omar Hassan', 'Male', '1990-09-15', '01033333333');

INSERT INTO Patient_Address VALUES (1, 'Alexandria', 'El Raml Street');
INSERT INTO Patient_Address VALUES (2, 'Cairo', 'Nasr City Street');
INSERT INTO Patient_Address VALUES (3, 'Giza', 'Dokki Street');

INSERT INTO Doctor VALUES (1, 'Dr. John Smith', 'Cardiology', '01111111111', 'john@clinic.com', 'LIC123');
INSERT INTO Doctor VALUES (2, 'Dr. Sara Ali', 'Neurology', '01122222222', 'sara@clinic.com', 'LIC456');

INSERT INTO Inpatient VALUES (1, '2026-04-01', 101);
INSERT INTO Outpatient VALUES (2, 'REG-2001');
--INSERT INTO Outpatient VALUES (1, 'REG-9999'); --test trigger

--INSERT INTO Inpatient VALUES (2, '2026-04-02', 102);  --test trigger

INSERT INTO Appointment VALUES (1, '2026-05-01', '10:00', 'Scheduled', 'Checkup', 1, 1);
--INSERT INTO Appointment VALUES (2, '2026-05-01', '10:00', 'Scheduled', 'Follow-up', 2, 1); --test doctor can't have same appointment
INSERT INTO Appointment VALUES (2, '2026-05-01', '10:30', 'Scheduled', 'Follow-up', 2, 1);

INSERT INTO Prescription VALUES (1, '2026-05-01', 'Take meds daily', 1);

INSERT INTO Medication VALUES (1, 'Panadol');
INSERT INTO Medication VALUES (2, 'Aspirin');

INSERT INTO Prescription_Medication VALUES (1, 1, '500mg', 'After food');
INSERT INTO Prescription_Medication VALUES (1, 2, '100mg', 'Before sleep');


SELECT * FROM Patient;
SELECT * FROM Doctor;
SELECT * FROM Appointment;

SELECT *
FROM   Appointment
WHERE  Status = 'Scheduled';

SELECT *
FROM   Appointment
WHERE  Appointment_date = '2026-05-01';

SELECT *
FROM   Doctor
WHERE  Speciality = 'Cardiology';

SELECT *
FROM   Patient
WHERE  Gender = 'Male';


SELECT a.Appointment_id,
       p.Full_Name   AS Patient_Name,
       d.Full_name   AS Doctor_Name,
       a.Appointment_date,
       a.Appointment_time,
       a.Status
FROM   Appointment a
JOIN   Patient     p ON a.Patient_id = p.Patient_id
JOIN   Doctor      d ON a.Doctor_id  = d.Doctor_id;



SELECT pr.Prescription_id,
       pr.Date_issued,
       pr.Notes,
       a.Appointment_date,
       a.Reason_of_visit
FROM   Prescription pr
JOIN   Appointment  a  ON pr.Appointment_id = a.Appointment_id;


-- the medicines in every Prescription with dosage and instructions
SELECT pr.Prescription_id,
       m.Medication_Name,
       pm.Dosage,
       pm.Instructions
FROM   Prescription_Medication pm
JOIN   Prescription            pr ON pm.Prescription_id = pr.Prescription_id
JOIN   Medication              m  ON pm.Medication_id   = m.Medication_id;


SELECT p.Full_Name,
       p.Phone,
       pa.City_State,
       pa.Street_name
FROM   Patient         p
JOIN   Patient_Address pa ON p.Patient_id = pa.Patient_id; 



SELECT d.Full_name          AS Doctor_Name,
       COUNT(a.Appointment_id) AS Total_Appointments
FROM   Doctor      d
JOIN   Appointment a ON d.Doctor_id = a.Doctor_id
GROUP BY d.Doctor_id, d.Full_name;


SELECT p.Full_Name          AS Patient_Name,
       COUNT(a.Appointment_id) AS Total_Appointments
FROM   Patient     p
JOIN   Appointment a ON p.Patient_id = a.Patient_id
GROUP BY p.Patient_id, p.Full_Name;


SELECT 'Inpatient'  AS Type, COUNT(*) AS Total FROM Inpatient
UNION ALL
SELECT 'Outpatient' AS Type, COUNT(*) AS Total FROM Outpatient;

-- all appointment by date then time ascending
SELECT *
FROM   Appointment
ORDER BY Appointment_date ASC, Appointment_time ASC;


SELECT TOP 1 *
FROM   Prescription
ORDER BY Date_issued DESC;


SELECT d.Full_name, COUNT(a.Appointment_id) AS Total_Appointments
FROM Doctor d
JOIN Appointment a ON d.Doctor_id = a.Doctor_id
GROUP BY d.Full_name
HAVING COUNT(a.Appointment_id) > 1;

-- =========================================
-- Transaction: Book a new appointment
-- Purpose: Insert a new appointment safely
-- Ensures the operation is completed or rolled back
-- =========================================

BEGIN TRY
    BEGIN TRANSACTION;  -- Start the transaction

    -- Insert a new appointment record
    INSERT INTO Appointment
    VALUES (3, '2026-05-02', '11:00', 'Scheduled', 'Consultation', 3, 2);

    COMMIT;  -- Commit changes if no errors occur
    PRINT 'Appointment booked successfully';

END TRY
BEGIN CATCH
    ROLLBACK;  -- Roll back all changes if an error occurs
    PRINT 'Error occurred while booking appointment';
END CATCH;

-- =========================================
-- Transaction: Cancel an appointment
-- Purpose: Update appointment status to 'Cancelled'
-- =========================================

BEGIN TRY
    BEGIN TRANSACTION;  -- Start the transaction

    -- Update the status of the appointment
    UPDATE Appointment
    SET Status = 'Cancelled'
    WHERE Appointment_id = 1;

    COMMIT;  -- Save changes
    PRINT 'Appointment cancelled successfully';

END TRY
BEGIN CATCH
    ROLLBACK;  -- Undo changes if an error occurs
    PRINT 'Error occurred while cancelling appointment';
END CATCH;

-- =========================================
-- Transaction: Register a new patient
-- Purpose: Insert patient data, address, and assign as Outpatient
-- Ensures all related data is inserted together
-- =========================================

BEGIN TRY
    BEGIN TRANSACTION;  -- Start the transaction

    -- Insert patient basic information
    INSERT INTO Patient
    VALUES (4, 'Mona Khaled', 'Female', '2000-03-10', '01044444444');

    -- Insert patient address
    INSERT INTO Patient_Address
    VALUES (4, 'Cairo', 'Maadi Street');

    -- Assign patient as Outpatient
    INSERT INTO Outpatient
    VALUES (4, 'REG-3001');

    COMMIT;  -- Commit if all inserts succeed
    PRINT 'Patient registered successfully';

END TRY
BEGIN CATCH
    ROLLBACK;  -- Roll back if any step fails
    PRINT 'Error occurred while registering patient';
END CATCH;

-- =========================================
-- Transaction: Create a prescription with medications
-- Purpose: Insert prescription and related medications together
-- =========================================

BEGIN TRY
    BEGIN TRANSACTION;  -- Start the transaction

    -- Insert prescription record
    INSERT INTO Prescription
    VALUES (2, '2026-05-02', 'New prescription', 2);

    -- Insert medications linked to the prescription
    INSERT INTO Prescription_Medication
    VALUES (2, 1, '500mg', 'Twice daily');

    INSERT INTO Prescription_Medication
    VALUES (2, 2, '50mg', 'After meal');

    COMMIT;  -- Save all changes
    PRINT 'Prescription created successfully';

END TRY
BEGIN CATCH
    ROLLBACK;  -- Undo all changes if any error occurs
    PRINT 'Error occurred while creating prescription';
END CATCH;

-- =========================================
-- Transaction: Transfer patient type
-- Purpose: Move patient from Outpatient to Inpatient
-- Important: Must delete first due to trigger constraints
-- =========================================

BEGIN TRY
    BEGIN TRANSACTION;  -- Start the transaction

    -- Remove patient from Outpatient
    DELETE FROM Outpatient
    WHERE Patient_id = 2;

    -- Insert patient into Inpatient
    INSERT INTO Inpatient
    VALUES (2, '2026-05-03', 102);

    COMMIT;  -- Commit changes if successful
    PRINT 'Patient transferred to inpatient successfully';

END TRY
BEGIN CATCH
    ROLLBACK;  -- Roll back if any error occurs
    PRINT 'Error occurred while transferring patient';
END CATCH;

-- =====================================================
-- SECTION 1: CONCURRENCY SIMULATION
-- =====================================================
-- Run Session 1 and Session 2 in two separate SSMS windows simultaneously.
-- Session 1 holds a transaction open;Session 2 tries to read/write the same row → BLOCKING occurs.

-- ========================
-- SESSION 1 
-- ========================
BEGIN TRANSACTION;

    -- Update appointment status — holds an exclusive lock on Appointment_id = 2
    UPDATE Appointment
    SET    Status = 'In Progress'
    WHERE  Appointment_id = 2;

    -- DO NOT COMMIT YET — leave this transaction open
    -- Switch to Session 2 now to see the block
    WAITFOR DELAY '00:00:20';  -- waits 20 seconds to simulate a long transaction

COMMIT;
PRINT 'Session 1 committed';

-- ========================
-- SESSION 2 (Run While Session 1 Is Waiting)
-- ========================
-- This query will BLOCK until Session 1 commits or rolls back:
SELECT *
FROM   Appointment
WHERE  Appointment_id = 2;


-- To observe the block in real time, run this in a THIRD window:
SELECT
    r.session_id,
    r.status,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time,
    r.command,
    t.text AS query_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id > 0;



-- EXPLANATION:
-- Session 1 holds an exclusive (X) lock on the row in Appointment.
-- Session 2 requests a shared (S) lock for the SELECT → blocked.
-- This simulates a real concurrency conflict in a booking system
-- where two users try to access the same appointment simultaneously.


-- =====================================================
-- SECTION 2: RECOVERY
-- =====================================================

-- ========================
-- 2A: Transaction Rollback Demo
-- ========================
BEGIN TRY
    BEGIN TRANSACTION;

    -- Intentionally insert a duplicate appointment (same doctor, date, time) → violates UNIQUE constraint
    INSERT INTO Appointment
    VALUES (99, '2026-05-01', '10:00', 'Scheduled', 'Test', 1, 1);

    COMMIT;
    PRINT 'Committed (should not reach here)';

END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ROLLBACK executed: ' + ERROR_MESSAGE();
    -- Recovery: the database returns to its state before the BEGIN TRANSACTION
END CATCH;

-- ========================
-- 2B: Simulate System Failure (Uncommitted Transaction)
-- ========================
-- Step 1: Start a transaction but do NOT commit
BEGIN TRANSACTION;

    INSERT INTO Patient
    VALUES (99, 'Ghost Patient', 'Male', '2000-01-01', '00000000000');
select * from Patient;

-- Step 2: Simulate crash by closing SSMS without committing
-- SQL Server uses the Write-Ahead Log (WAL) for recovery:
--   • On restart, SQL Server reads the transaction log.
--   • Committed transactions are REDONE (rolled forward).
--   • Uncommitted transactions (like this one) are UNDONE (rolled back).
-- Result: 'Ghost Patient' will NOT appear in the database after restart.

-- ROLLBACK;  --  manually simulate the recovery
ROLLBACK;
PRINT 'Simulated crash recovery: uncommitted transaction was rolled back';
select * from Patient;


-- =====================================================
-- SECTION 3: STORED PROCEDURES
-- =====================================================

-- ========================
-- SP 1: Book a New Appointment
-- ========================
GO
CREATE OR ALTER PROCEDURE sp_BookAppointment
    @Appointment_id   INT,
    @Appt_date        DATE,
    @Appt_time        TIME,
    @Status           VARCHAR(50),
    @Reason           VARCHAR(255),
    @Patient_id       INT,
    @Doctor_id        INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the doctor already has an appointment at that date/time
    IF EXISTS (
        SELECT 1 FROM Appointment
        WHERE  Doctor_id        = @Doctor_id
          AND  Appointment_date = @Appt_date
          AND  Appointment_time = @Appt_time
    )
    BEGIN
        PRINT 'Error: Doctor already has an appointment at this time.';
        RETURN;
    END

    -- Check if the patient exists
    IF NOT EXISTS (SELECT 1 FROM Patient WHERE Patient_id = @Patient_id)
    BEGIN
        PRINT 'Error: Patient does not exist.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Appointment (Appointment_id, Appointment_date, Appointment_time, Status, Reason_of_visit, Patient_id, Doctor_id)
            VALUES (@Appointment_id, @Appt_date, @Appt_time, @Status, @Reason, @Patient_id, @Doctor_id);

        COMMIT;
        PRINT 'Appointment booked successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error booking appointment: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Test the stored procedure:
EXEC sp_BookAppointment 10, '2026-06-01', '09:00', 'Scheduled', 'Annual Checkup', 3, 2;

-- Test conflict (same doctor, same time):
EXEC sp_BookAppointment 11, '2026-06-01', '09:00', 'Scheduled', 'Follow-up', 1, 2;


-- ========================
-- SP 2: Get Patient Full History
-- ========================
GO
CREATE OR ALTER PROCEDURE sp_GetPatientHistory
    @Patient_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.Full_Name,
        a.Appointment_date,
        a.Appointment_time,
        a.Status,
        a.Reason_of_visit,
        d.Full_name        AS Doctor_Name,
        d.Speciality,
        pr.Date_issued     AS Prescription_Date,
        pr.Notes           AS Prescription_Notes,
        m.Medication_Name,
        pm.Dosage,
        pm.Instructions
    FROM Patient p
    JOIN Appointment           a  ON p.Patient_id       = a.Patient_id
    JOIN Doctor                d  ON a.Doctor_id        = d.Doctor_id
    LEFT JOIN Prescription     pr ON a.Appointment_id   = pr.Appointment_id
    LEFT JOIN Prescription_Medication pm ON pr.Prescription_id = pm.Prescription_id
    LEFT JOIN Medication        m  ON pm.Medication_id  = m.Medication_id
    WHERE p.Patient_id = @Patient_id
    ORDER BY a.Appointment_date DESC;
END;
GO

-- Test:
EXEC sp_GetPatientHistory 1;


-- =====================================================
-- SECTION 4: WINDOW FUNCTIONS
-- =====================================================

-- ========================
-- 4A: ROW_NUMBER — Rank appointments per doctor by date
-- ========================
SELECT
    d.Full_name                                                   AS Doctor_Name,
    p.Full_Name                                                   AS Patient_Name,
    a.Appointment_date,
    a.Appointment_time,
    ROW_NUMBER() OVER (
        PARTITION BY a.Doctor_id
        ORDER BY     a.Appointment_date, a.Appointment_time
    )                                                             AS Appointment_Number
FROM Appointment a
JOIN Doctor  d ON a.Doctor_id  = d.Doctor_id
JOIN Patient p ON a.Patient_id = p.Patient_id;

-- ========================
-- 4B: RANK — Rank doctors by number of appointments
-- ========================
SELECT
    d.Full_name                                   AS Doctor_Name,
    COUNT(a.Appointment_id)                       AS Total_Appointments,
    RANK() OVER (
        ORDER BY COUNT(a.Appointment_id) DESC
    )                                             AS Doctor_Rank
FROM Doctor d
JOIN Appointment a ON d.Doctor_id = a.Doctor_id
GROUP BY d.Doctor_id, d.Full_name;

-- ========================
-- 4C: DENSE_RANK — Rank patients by number of appointments
-- ========================
SELECT
    p.Full_Name                                   AS Patient_Name,
    COUNT(a.Appointment_id)                       AS Total_Appointments,
    DENSE_RANK() OVER (
        ORDER BY COUNT(a.Appointment_id) DESC
    )                                             AS Patient_Rank
FROM Patient p
JOIN Appointment a ON p.Patient_id = a.Patient_id
GROUP BY p.Patient_id, p.Full_Name;

-- ========================
-- 4D: LAG / LEAD — Time gap between a patient's consecutive appointments
-- ========================
SELECT
    p.Full_Name,
    a.Appointment_date,
    LAG(a.Appointment_date)  OVER (PARTITION BY a.Patient_id ORDER BY a.Appointment_date) AS Previous_Appointment,
    LEAD(a.Appointment_date) OVER (PARTITION BY a.Patient_id ORDER BY a.Appointment_date) AS Next_Appointment,
    DATEDIFF(DAY,
        LAG(a.Appointment_date) OVER (PARTITION BY a.Patient_id ORDER BY a.Appointment_date),
        a.Appointment_date
    )                                                                                      AS Days_Since_Last
FROM Appointment a
JOIN Patient p ON a.Patient_id = p.Patient_id;

-- ========================
-- 4E: Running total of appointments per doctor over time
-- ========================
SELECT
    d.Full_name,
    a.Appointment_date,
    COUNT(a.Appointment_id) OVER (
        PARTITION BY a.Doctor_id
        ORDER BY     a.Appointment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Total
FROM Appointment a
JOIN Doctor d ON a.Doctor_id = d.Doctor_id;


-- =====================================================
-- SECTION 5: QUERY OPTIMIZATION (INDEXING)
-- =====================================================

-- ========================
-- 5A: Non-Clustered Index on Appointment date & status (frequent filter columns)
-- ========================
CREATE NONCLUSTERED INDEX IX_Appointment_Date_Status
ON Appointment (Appointment_date, Status);

-- ========================
-- 5B: Non-Clustered Index on Doctor specialty (frequent filter)
-- ========================
CREATE NONCLUSTERED INDEX IX_Doctor_Speciality
ON Doctor (Speciality);

-- ========================
-- 5C: Non-Clustered Index on Patient gender (used in WHERE filters)
-- ========================
CREATE NONCLUSTERED INDEX IX_Patient_Gender
ON Patient (Gender);

-- ========================
-- 5D: Non-Clustered Index on Appointment.Patient_id and Doctor_id (JOIN columns)
-- ========================
CREATE NONCLUSTERED INDEX IX_Appointment_PatientDoctor
ON Appointment (Patient_id, Doctor_id);

-- ========================
-- 5E: Performance comparison — check execution plan
-- ========================
-- Run these with "Include Actual Execution Plan" (Ctrl+M in SSMS) BEFORE and AFTER creating indexes:

-- Query 1: Filter by date (benefits from IX_Appointment_Date_Status)
SELECT * FROM Appointment WHERE Appointment_date = '2026-05-01' AND Status = 'Scheduled';

-- Query 2: Filter doctor by specialty (benefits from IX_Doctor_Speciality)
SELECT * FROM Doctor WHERE Speciality = 'Cardiology';

-- Check index usage stats:
SELECT
    OBJECT_NAME(i.object_id)        AS TableName,
    i.name                          AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.last_user_seek
FROM sys.indexes i
JOIN sys.dm_db_index_usage_stats s
     ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Appointment', 'Doctor', 'Patient');


-- =====================================================
-- SECTION 6: DATA WAREHOUSE — STAR SCHEMA
-- =====================================================
-- Fact table: Fact_Appointment (one row per appointment)
-- Dimensions: Dim_Patient, Dim_Doctor, Dim_Date, Dim_Medication

-- ========================
-- 6A: Create Dimension Tables
-- ========================
GO

CREATE TABLE Dim_Patient (
    Patient_Key    INT PRIMARY KEY IDENTITY(1,1),
    Patient_id     INT,
    Full_Name      VARCHAR(100),
    Gender         VARCHAR(10),
    Date_of_birth  DATE,
    City_State     VARCHAR(50)
);

CREATE TABLE Dim_Doctor (
    Doctor_Key   INT PRIMARY KEY IDENTITY(1,1),
    Doctor_id    INT,
    Full_name    VARCHAR(100),
    Speciality   VARCHAR(100)
);

CREATE TABLE Dim_Date (
    Date_Key     INT PRIMARY KEY,   -- format: YYYYMMDD
    Full_Date    DATE,
    Day_Num      INT,
    Month_Num    INT,
    Month_Name   VARCHAR(20),
    Quarter      INT,
    Year_Num     INT,
    Weekday_Name VARCHAR(20)
);

CREATE TABLE Dim_Medication (
    Medication_Key  INT PRIMARY KEY IDENTITY(1,1),
    Medication_id   INT,
    Medication_Name VARCHAR(100)
);

-- ========================
-- 6B: Create Fact Table
-- ========================
CREATE TABLE Fact_Appointment (
    Fact_id         INT PRIMARY KEY IDENTITY(1,1),
    Appointment_id  INT,
    Patient_Key     INT FOREIGN KEY REFERENCES Dim_Patient(Patient_Key),
    Doctor_Key      INT FOREIGN KEY REFERENCES Dim_Doctor(Doctor_Key),
    Date_Key        INT FOREIGN KEY REFERENCES Dim_Date(Date_Key),
    Medication_Key  INT FOREIGN KEY REFERENCES Dim_Medication(Medication_Key),
    Status          VARCHAR(50),
    Reason_of_visit VARCHAR(255),
    Prescription_id INT,
    Dosage          VARCHAR(50),
    -- Measures
    Appointment_Count    INT DEFAULT 1,
    Has_Prescription     BIT            -- 1 = yes, 0 = no
);

-- ========================
-- 6C: ETL — Populate Dimension Tables from OLTP
-- ========================

-- Load Dim_Patient
INSERT INTO Dim_Patient (Patient_id, Full_Name, Gender, Date_of_birth, City_State)
SELECT
    p.Patient_id,
    p.Full_Name,
    p.Gender,
    p.Date_of_birth,
    pa.City_State
FROM Patient p
LEFT JOIN Patient_Address pa ON p.Patient_id = pa.Patient_id;

-- Load Dim_Doctor
INSERT INTO Dim_Doctor (Doctor_id, Full_name, Speciality)
SELECT Doctor_id, Full_name, Speciality FROM Doctor;

-- Load Dim_Date (generate dates for all appointment dates present in OLTP)
INSERT INTO Dim_Date (Date_Key, Full_Date, Day_Num, Month_Num, Month_Name, Quarter, Year_Num, Weekday_Name)
SELECT DISTINCT
    CAST(FORMAT(Appointment_date, 'yyyyMMdd') AS INT) AS Date_Key,
    Appointment_date,
    DAY(Appointment_date),
    MONTH(Appointment_date),
    DATENAME(MONTH, Appointment_date),
    DATEPART(QUARTER, Appointment_date),
    YEAR(Appointment_date),
    DATENAME(WEEKDAY, Appointment_date)
FROM Appointment
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Date
    WHERE Date_Key = CAST(FORMAT(Appointment_date, 'yyyyMMdd') AS INT)
);

-- Load Dim_Medication
INSERT INTO Dim_Medication (Medication_id, Medication_Name)
SELECT Medication_id, Medication_Name FROM Medication;

-- ========================
-- 6D: ETL — Populate Fact Table
-- ========================
INSERT INTO Fact_Appointment (
    Appointment_id, Patient_Key, Doctor_Key, Date_Key,
    Medication_Key, Status, Reason_of_visit,
    Prescription_id, Dosage, Appointment_Count, Has_Prescription
)
SELECT
    a.Appointment_id,
    dp.Patient_Key,
    dd.Doctor_Key,
    CAST(FORMAT(a.Appointment_date, 'yyyyMMdd') AS INT)   AS Date_Key,
    dm.Medication_Key,
    a.Status,
    a.Reason_of_visit,
    pr.Prescription_id,
    pm.Dosage,
    1                                                     AS Appointment_Count,
    CASE WHEN pr.Prescription_id IS NOT NULL THEN 1 ELSE 0 END AS Has_Prescription
FROM Appointment a
JOIN Dim_Patient  dp ON a.Patient_id       = dp.Patient_id
JOIN Dim_Doctor   dd ON a.Doctor_id        = dd.Doctor_id
LEFT JOIN Prescription     pr ON a.Appointment_id  = pr.Appointment_id
LEFT JOIN Prescription_Medication pm ON pr.Prescription_id = pm.Prescription_id
LEFT JOIN Dim_Medication   dm ON pm.Medication_id  = dm.Medication_id;

-- ========================
-- 6E: Analytical Queries on Data Warehouse
-- ========================

-- Q1: Total appointments per doctor
SELECT
    dd.Full_name         AS Doctor_Name,
    dd.Speciality,
    SUM(fa.Appointment_Count) AS Total_Appointments
FROM Fact_Appointment fa
JOIN Dim_Doctor dd ON fa.Doctor_Key = dd.Doctor_Key
GROUP BY dd.Full_name, dd.Speciality
ORDER BY Total_Appointments DESC;

-- Q2: Monthly appointment trend
SELECT
    dt.Year_Num,
    dt.Month_Name,
    SUM(fa.Appointment_Count) AS Monthly_Total
FROM Fact_Appointment fa
JOIN Dim_Date dt ON fa.Date_Key = dt.Date_Key
GROUP BY dt.Year_Num, dt.Month_Num, dt.Month_Name
ORDER BY dt.Year_Num, dt.Month_Num;

-- Q3: Most prescribed medications
SELECT
    dm.Medication_Name,
    COUNT(*) AS Times_Prescribed
FROM Fact_Appointment fa
JOIN Dim_Medication dm ON fa.Medication_Key = dm.Medication_Key
GROUP BY dm.Medication_Name
ORDER BY Times_Prescribed DESC;

-- Q4: Appointment status breakdown
SELECT
    Status,
    COUNT(*) AS Total
FROM Fact_Appointment
GROUP BY Status;

-- Q5: Appointments per patient per doctor (cross analysis)
SELECT
    dp.Full_Name   AS Patient_Name,
    dd.Full_name   AS Doctor_Name,
    COUNT(*)       AS Appointments
FROM Fact_Appointment fa
JOIN Dim_Patient dp ON fa.Patient_Key = dp.Patient_Key
JOIN Dim_Doctor  dd ON fa.Doctor_Key  = dd.Doctor_Key
GROUP BY dp.Full_Name, dd.Full_name
ORDER BY Appointments DESC;

-- Q6: Prescription rate per doctor (% of appointments that generated a prescription)
SELECT
    dd.Full_name                                                     AS Doctor_Name,
    COUNT(*)                                                         AS Total_Appointments,
    SUM(CAST(fa.Has_Prescription AS INT))                            AS With_Prescription,
    CAST(SUM(CAST(fa.Has_Prescription AS INT)) * 100.0
         / COUNT(*) AS DECIMAL(5,2))                                 AS Prescription_Rate_Pct
FROM Fact_Appointment fa
JOIN Dim_Doctor dd ON fa.Doctor_Key = dd.Doctor_Key
GROUP BY dd.Full_name;


-- =====================================================
-- DATA WAREHOUSE — STAR SCHEMA 
-- Healthcare Appointment System
-- =====================================================

-- =====================================================
-- STEP 1: BULK-POPULATE OLTP TABLES (20–50 records each)
-- =====================================================

-- ── Extra Patients (we already have 1–4 from final_project2.sql) ──
INSERT INTO Patient VALUES (5,  'Layla Hassan',    'Female', '1993-07-22', '01055555555');
INSERT INTO Patient VALUES (6,  'Youssef Nabil',   'Male',   '1988-11-03', '01066666666');
INSERT INTO Patient VALUES (7,  'Nadia Samir',     'Female', '2001-02-14', '01077777777');
INSERT INTO Patient VALUES (8,  'Karim Fouad',     'Male',   '1975-06-30', '01088888888');
INSERT INTO Patient VALUES (9,  'Hana Mostafa',    'Female', '1999-09-09', '01099999999');
INSERT INTO Patient VALUES (10, 'Tarek Adel',      'Male',   '1983-04-18', '01010101010');
INSERT INTO Patient VALUES (11, 'Rania Salah',     'Female', '1996-12-05', '01011101110');
INSERT INTO Patient VALUES (12, 'Sherif Magdy',    'Male',   '1979-08-25', '01012121212');
INSERT INTO Patient VALUES (13, 'Eman Fawzy',      'Female', '2003-03-17', '01013131313');
INSERT INTO Patient VALUES (14, 'Bassem Gamal',    'Male',   '1991-01-28', '01014141414');
INSERT INTO Patient VALUES (15, 'Dina Ramzy',      'Female', '1985-10-10', '01015151515');
INSERT INTO Patient VALUES (16, 'Amr Tawfik',      'Male',   '2002-05-05', '01016161616');
INSERT INTO Patient VALUES (17, 'Salma Waheed',    'Female', '1994-07-07', '01017171717');
INSERT INTO Patient VALUES (18, 'Hossam Khalil',   'Male',   '1980-03-20', '01018181818');
INSERT INTO Patient VALUES (19, 'Mervat Saber',    'Female', '1997-11-11', '01019191919');
INSERT INTO Patient VALUES (20, 'Walid Zaki',      'Male',   '1987-06-15', '01020202020');
INSERT INTO Patient VALUES (21, 'Mohamed Adel', 'Male', '1992-02-11', '01021212121');
INSERT INTO Patient VALUES (22, 'Reem Ashraf', 'Female', '2000-08-19', '01022222333');
INSERT INTO Patient VALUES (23, 'Hassan Ali', 'Male', '1986-03-14', '01023232323');
INSERT INTO Patient VALUES (24, 'Nourhan Tamer', 'Female', '1995-06-25', '01024242424');
INSERT INTO Patient VALUES (25, 'Mostafa Ibrahim', 'Male', '1981-12-01', '01025252525');
INSERT INTO Patient VALUES (26, 'Yara Saeed', 'Female', '1998-04-17', '01026262626');
INSERT INTO Patient VALUES (27, 'Ali Mahmoud', 'Male', '1990-09-09', '01027272727');
INSERT INTO Patient VALUES (28, 'Lina Adel', 'Female', '2002-11-23', '01028282828');
INSERT INTO Patient VALUES (29, 'Khaled Samir', 'Male', '1978-01-30', '01029292929');
INSERT INTO Patient VALUES (30, 'Heba Nasser', 'Female', '1993-07-07', '01030303030');
INSERT INTO Patient VALUES (31, 'Omar Saad', 'Male', '1996-10-10', '01031313131');
INSERT INTO Patient VALUES (32, 'Salma Youssef', 'Female', '1999-05-05', '01032323232');
INSERT INTO Patient VALUES (33, 'Ahmed Nabil', 'Male', '1989-03-03', '01033333444');
INSERT INTO Patient VALUES (34, 'Dalia Hassan', 'Female', '1991-01-12', '01034343434');
INSERT INTO Patient VALUES (35, 'Ziad Fathy', 'Male', '2003-06-18', '01035353535');
INSERT INTO Patient VALUES (36, 'Mariam Adel', 'Female', '1997-09-21', '01036363636');
INSERT INTO Patient VALUES (37, 'Sherif Omar', 'Male', '1984-04-04', '01037373737');
INSERT INTO Patient VALUES (38, 'Farah Mostafa', 'Female', '2001-02-28', '01038383838');
INSERT INTO Patient VALUES (39, 'Tamer Khalil', 'Male', '1987-08-08', '01039393939');
INSERT INTO Patient VALUES (40, 'Aya Reda', 'Female', '1994-12-12', '01040404040');

INSERT INTO Patient_Address VALUES (5,  'Alexandria', 'Sidi Gaber Street');
INSERT INTO Patient_Address VALUES (6,  'Cairo',      'Heliopolis Street');
INSERT INTO Patient_Address VALUES (7,  'Giza',       'Mohandessin Street');
INSERT INTO Patient_Address VALUES (8,  'Alexandria', 'Montaza Street');
INSERT INTO Patient_Address VALUES (9,  'Cairo',      'Zamalek Street');
INSERT INTO Patient_Address VALUES (10, 'Cairo',      'Maadi Street');
INSERT INTO Patient_Address VALUES (11, 'Giza',       'Agouza Street');
INSERT INTO Patient_Address VALUES (12, 'Alexandria', 'Smouha Street');
INSERT INTO Patient_Address VALUES (13, 'Cairo',      'Ain Shams Street');
INSERT INTO Patient_Address VALUES (14, 'Cairo',      'Nasr City Street');
INSERT INTO Patient_Address VALUES (15, 'Giza',       '6th of October Street');
INSERT INTO Patient_Address VALUES (16, 'Alexandria', 'Ibrahimia Street');
INSERT INTO Patient_Address VALUES (17, 'Cairo',      'Shubra Street');
INSERT INTO Patient_Address VALUES (18, 'Cairo',      'Imbaba Street');
INSERT INTO Patient_Address VALUES (19, 'Giza',       'Haram Street');
INSERT INTO Patient_Address VALUES (20, 'Alexandria', 'El-Mandara Street');
INSERT INTO Patient_Address VALUES (21, 'Cairo', 'Helwan Street');
INSERT INTO Patient_Address VALUES (22, 'Alexandria', 'Stanley Street');
INSERT INTO Patient_Address VALUES (23, 'Giza', 'Faisal Street');
INSERT INTO Patient_Address VALUES (24, 'Cairo', 'Downtown Street');
INSERT INTO Patient_Address VALUES (25, 'Alexandria', 'Gleem Street');
INSERT INTO Patient_Address VALUES (26, 'Giza', 'Haram Street');
INSERT INTO Patient_Address VALUES (27, 'Cairo', 'Nasr City Street');
INSERT INTO Patient_Address VALUES (28, 'Alexandria', 'Miami Street');
INSERT INTO Patient_Address VALUES (29, 'Giza', 'Dokki Street');
INSERT INTO Patient_Address VALUES (30, 'Cairo', 'Maadi Street');
INSERT INTO Patient_Address VALUES (31, 'Cairo', 'Ain Shams Street');
INSERT INTO Patient_Address VALUES (32, 'Alexandria', 'Sidi Bishr Street');
INSERT INTO Patient_Address VALUES (33, 'Giza', 'October Street');
INSERT INTO Patient_Address VALUES (34, 'Cairo', 'Heliopolis Street');
INSERT INTO Patient_Address VALUES (35, 'Alexandria', 'Mandara Street');
INSERT INTO Patient_Address VALUES (36, 'Giza', 'Agouza Street');
INSERT INTO Patient_Address VALUES (37, 'Cairo', 'Shubra Street');
INSERT INTO Patient_Address VALUES (38, 'Alexandria', 'Raml Station Street');
INSERT INTO Patient_Address VALUES (39, 'Giza', 'Imbaba Street');
INSERT INTO Patient_Address VALUES (40, 'Cairo', 'Zamalek Street');

-- Assign patient types
INSERT INTO Outpatient VALUES (5,  'REG-3002');
INSERT INTO Outpatient VALUES (6,  'REG-3003');
INSERT INTO Outpatient VALUES (7,  'REG-3004');
INSERT INTO Inpatient  VALUES (8,  '2026-04-10', 102);
INSERT INTO Outpatient VALUES (9,  'REG-3005');
INSERT INTO Outpatient VALUES (10, 'REG-3006');
INSERT INTO Inpatient  VALUES (11, '2026-04-15', 103);
INSERT INTO Outpatient VALUES (12, 'REG-3007');
INSERT INTO Outpatient VALUES (13, 'REG-3008');
INSERT INTO Outpatient VALUES (14, 'REG-3009');
INSERT INTO Outpatient VALUES (15, 'REG-3010');
INSERT INTO Outpatient VALUES (16, 'REG-3011');
INSERT INTO Outpatient VALUES (17, 'REG-3012');
INSERT INTO Inpatient  VALUES (18, '2026-04-20', 104);
INSERT INTO Outpatient VALUES (19, 'REG-3013');
INSERT INTO Outpatient VALUES (20, 'REG-3014');
INSERT INTO Outpatient VALUES (21, 'REG-3015');
INSERT INTO Outpatient VALUES (22, 'REG-3016');
INSERT INTO Inpatient VALUES (23, '2026-05-01', 105);
INSERT INTO Outpatient VALUES (24, 'REG-3017');
INSERT INTO Outpatient VALUES (25, 'REG-3018');
INSERT INTO Inpatient VALUES (26, '2026-05-02', 106);
INSERT INTO Outpatient VALUES (27, 'REG-3019');
INSERT INTO Outpatient VALUES (28, 'REG-3020');
INSERT INTO Outpatient VALUES (29, 'REG-3021');
INSERT INTO Inpatient VALUES (30, '2026-05-03', 107);
INSERT INTO Outpatient VALUES (31, 'REG-3022');
INSERT INTO Outpatient VALUES (32, 'REG-3023');
INSERT INTO Inpatient VALUES (33, '2026-05-04', 108);
INSERT INTO Outpatient VALUES (34, 'REG-3024');
INSERT INTO Outpatient VALUES (35, 'REG-3025');
INSERT INTO Outpatient VALUES (36, 'REG-3026');
INSERT INTO Outpatient VALUES (37, 'REG-3027');
INSERT INTO Inpatient VALUES (38, '2026-05-05', 109);
INSERT INTO Outpatient VALUES (39, 'REG-3028');
INSERT INTO Outpatient VALUES (40, 'REG-3029');

-- ── Extra Doctors (we already have 1–2) ──
INSERT INTO Doctor VALUES (3, 'Dr. Mona Kamel',    'Orthopedics',     '01133333333', 'mona@clinic.com',    'LIC789');
INSERT INTO Doctor VALUES (4, 'Dr. Tariq Hassan',  'Dermatology',     '01144444444', 'tariq@clinic.com',   'LIC101');
INSERT INTO Doctor VALUES (5, 'Dr. Heba Younis',   'Pediatrics',      '01155555555', 'heba@clinic.com',    'LIC112');
INSERT INTO Doctor VALUES (6, 'Dr. Amira Lotfy',   'Ophthalmology',   '01166666666', 'amira@clinic.com',   'LIC131');
INSERT INTO Doctor VALUES (7, 'Dr. Ahmed Zaki', 'ENT', '01177777777', 'ahmed@clinic.com', 'LIC200');
INSERT INTO Doctor VALUES (8, 'Dr. Laila Gamal', 'Oncology', '01188888888', 'laila@clinic.com', 'LIC201');
INSERT INTO Doctor VALUES (9, 'Dr. Omar Nabil', 'Psychiatry', '01199999999', 'omar@clinic.com', 'LIC202');
INSERT INTO Doctor VALUES (10, 'Dr. Nada Sherif', 'Gynecology', '01100000000', 'nada@clinic.com', 'LIC203');
INSERT INTO Doctor VALUES (11, 'Dr. Samir Farouk', 'Cardiology', '01112121212', 'samir@clinic.com', 'LIC204');
INSERT INTO Doctor VALUES (12, 'Dr. Hanan Mostafa', 'Neurology', '01113131313', 'hanan@clinic.com', 'LIC205');
INSERT INTO Doctor VALUES (13, 'Dr. Ahmed ElShazly', 'Orthopedics', '01114141414', 'ahmed.shazly@clinic.com', 'LIC206');
INSERT INTO Doctor VALUES (14, 'Dr. Reham Adel', 'Dermatology', '01115151515', 'reham@clinic.com', 'LIC207');
INSERT INTO Doctor VALUES (15, 'Dr. Mostafa Riad', 'Pediatrics', '01116161616', 'mostafa@clinic.com', 'LIC208');
INSERT INTO Doctor VALUES (16, 'Dr. Yasmin Kamal', 'Ophthalmology', '01117171717', 'yasmin@clinic.com', 'LIC209');
INSERT INTO Doctor VALUES (17, 'Dr. Tarek Hussein', 'Gastroenterology', '01118181818', 'tarek@clinic.com', 'LIC210');
INSERT INTO Doctor VALUES (18, 'Dr. Mona Abdelrahman', 'Endocrinology', '01119191919', 'mona.endocrine@clinic.com', 'LIC211');
INSERT INTO Doctor VALUES (19, 'Dr. Ali Hamed', 'Urology', '01120202020', 'ali@clinic.com', 'LIC212');
INSERT INTO Doctor VALUES (20, 'Dr. Salwa Nagi', 'Psychiatry', '01121212121', 'salwa@clinic.com', 'LIC213');

-- ── Extra Medications ──
INSERT INTO Medication VALUES (3, 'Amoxicillin');
INSERT INTO Medication VALUES (4, 'Ibuprofen');
INSERT INTO Medication VALUES (5, 'Omeprazole');
INSERT INTO Medication VALUES (6, 'Metformin');
INSERT INTO Medication VALUES (7, 'Atorvastatin');
INSERT INTO Medication VALUES (8, 'Lisinopril');
INSERT INTO Medication VALUES (9, 'Paracetamol');
INSERT INTO Medication VALUES (10, 'Ceftriaxone');
INSERT INTO Medication VALUES (11, 'Doxycycline');
INSERT INTO Medication VALUES (12, 'Clarithromycin');
INSERT INTO Medication VALUES (13, 'Prednisone');
INSERT INTO Medication VALUES (14, 'Cetirizine');
INSERT INTO Medication VALUES (15, 'Salbutamol');
INSERT INTO Medication VALUES (16, 'Furosemide');
INSERT INTO Medication VALUES (17, 'Warfarin');
INSERT INTO Medication VALUES (18, 'Insulin');
INSERT INTO Medication VALUES (19, 'Hydrochlorothiazide');
INSERT INTO Medication VALUES (20, 'Azithromycin');

-- ── Extra Appointments (IDs 4–53, to reach 50+ fact rows) ──
-- Existing: 1,2,3 already inserted in final_project2.sql
INSERT INTO Appointment VALUES (4,  '2026-05-03', '09:00', 'Completed',  'Follow-up',     4,  2);
INSERT INTO Appointment VALUES (5,  '2026-05-03', '09:30', 'Scheduled',  'Checkup',        5,  1);
INSERT INTO Appointment VALUES (6,  '2026-05-03', '10:00', 'Completed',  'Consultation',   6,  3);
INSERT INTO Appointment VALUES (7,  '2026-05-04', '08:00', 'Scheduled',  'Checkup',        7,  4);
INSERT INTO Appointment VALUES (8,  '2026-05-04', '08:30', 'Completed',  'Follow-up',      8,  1);
INSERT INTO Appointment VALUES (9,  '2026-05-04', '09:00', 'Cancelled',  'Consultation',   9,  2);
INSERT INTO Appointment VALUES (10, '2026-05-05', '10:00', 'Completed',  'Checkup',       10,  5);
INSERT INTO Appointment VALUES (11, '2026-05-05', '10:30', 'Scheduled',  'Follow-up',     11,  3);
INSERT INTO Appointment VALUES (12, '2026-05-05', '11:00', 'Completed',  'Consultation',  12,  6);
INSERT INTO Appointment VALUES (13, '2026-05-06', '09:00', 'Scheduled',  'Checkup',       13,  1);
INSERT INTO Appointment VALUES (14, '2026-05-06', '09:30', 'Completed',  'Follow-up',     14,  4);
INSERT INTO Appointment VALUES (15, '2026-05-06', '10:00', 'Cancelled',  'Checkup',       15,  2);
INSERT INTO Appointment VALUES (16, '2026-05-07', '08:00', 'Completed',  'Consultation',  16,  5);
INSERT INTO Appointment VALUES (17, '2026-05-07', '08:30', 'Scheduled',  'Checkup',       17,  3);
INSERT INTO Appointment VALUES (18, '2026-05-07', '09:00', 'Completed',  'Follow-up',     18,  6);
INSERT INTO Appointment VALUES (19, '2026-05-08', '10:00', 'Completed',  'Checkup',       19,  1);
INSERT INTO Appointment VALUES (20, '2026-05-08', '10:30', 'Scheduled',  'Consultation',  20,  2);
INSERT INTO Appointment VALUES (21, '2026-05-09', '09:00', 'Completed',  'Follow-up',      1,  3);
INSERT INTO Appointment VALUES (22, '2026-05-09', '09:30', 'Completed',  'Checkup',        2,  4);
INSERT INTO Appointment VALUES (23, '2026-05-09', '10:00', 'Scheduled',  'Consultation',   3,  5);
INSERT INTO Appointment VALUES (24, '2026-05-10', '08:00', 'Completed',  'Checkup',        4,  6);
INSERT INTO Appointment VALUES (25, '2026-05-10', '08:30', 'Cancelled',  'Follow-up',      5,  1);
INSERT INTO Appointment VALUES (26, '2026-05-10', '09:00', 'Completed',  'Checkup',        6,  2);
INSERT INTO Appointment VALUES (27, '2026-05-11', '10:00', 'Scheduled',  'Consultation',   7,  3);
INSERT INTO Appointment VALUES (28, '2026-05-11', '10:30', 'Completed',  'Follow-up',      8,  4);
INSERT INTO Appointment VALUES (29, '2026-05-11', '11:00', 'Completed',  'Checkup',        9,  5);
INSERT INTO Appointment VALUES (30, '2026-05-12', '09:00', 'Completed',  'Consultation',  10,  6);
INSERT INTO Appointment VALUES (31, '2026-05-12', '09:30', 'Scheduled',  'Checkup',       11,  1);
INSERT INTO Appointment VALUES (32, '2026-05-12', '10:00', 'Cancelled',  'Follow-up',     12,  2);
INSERT INTO Appointment VALUES (33, '2026-05-13', '08:00', 'Completed',  'Checkup',       13,  3);
INSERT INTO Appointment VALUES (34, '2026-05-13', '08:30', 'Completed',  'Consultation',  14,  4);
INSERT INTO Appointment VALUES (35, '2026-05-13', '09:00', 'Scheduled',  'Follow-up',     15,  5);
INSERT INTO Appointment VALUES (36, '2026-05-14', '10:00', 'Completed',  'Checkup',       16,  6);
INSERT INTO Appointment VALUES (37, '2026-05-14', '10:30', 'Completed',  'Consultation',  17,  1);
INSERT INTO Appointment VALUES (38, '2026-05-14', '11:00', 'Cancelled',  'Checkup',       18,  2);
INSERT INTO Appointment VALUES (39, '2026-05-15', '09:00', 'Completed',  'Follow-up',     19,  3);
INSERT INTO Appointment VALUES (40, '2026-05-15', '09:30', 'Scheduled',  'Checkup',       20,  4);
INSERT INTO Appointment VALUES (41, '2026-05-16', '08:00', 'Completed',  'Consultation',   1,  5);
INSERT INTO Appointment VALUES (42, '2026-05-16', '08:30', 'Completed',  'Checkup',        2,  6);
INSERT INTO Appointment VALUES (43, '2026-05-17', '10:00', 'Scheduled',  'Follow-up',      3,  1);
INSERT INTO Appointment VALUES (44, '2026-05-17', '10:30', 'Completed',  'Checkup',        4,  2);
INSERT INTO Appointment VALUES (45, '2026-05-18', '09:00', 'Completed',  'Consultation',   5,  3);
INSERT INTO Appointment VALUES (46, '2026-05-18', '09:30', 'Cancelled',  'Checkup',        6,  4);
INSERT INTO Appointment VALUES (47, '2026-05-19', '08:00', 'Completed',  'Follow-up',      7,  5);
INSERT INTO Appointment VALUES (48, '2026-05-19', '08:30', 'Completed',  'Checkup',        8,  6);
INSERT INTO Appointment VALUES (49, '2026-05-20', '10:00', 'Scheduled',  'Consultation',   9,  1);
INSERT INTO Appointment VALUES (50, '2026-05-20', '10:30', 'Completed',  'Checkup',       10,  2);
INSERT INTO Appointment VALUES (51, '2026-05-21', '09:00', 'Completed',  'Follow-up',     11,  3);
INSERT INTO Appointment VALUES (52, '2026-05-21', '09:30', 'Cancelled',  'Checkup',       12,  4);
INSERT INTO Appointment VALUES (53, '2026-05-22', '08:00', 'Completed',  'Consultation',  13,  5);

-- ── Extra Prescriptions ──
INSERT INTO Prescription VALUES (3,  '2026-05-02', 'Take with water',       3);
INSERT INTO Prescription VALUES (4,  '2026-05-03', 'Rest recommended',      4);
INSERT INTO Prescription VALUES (5,  '2026-05-03', 'Avoid alcohol',         6);
INSERT INTO Prescription VALUES (6,  '2026-05-04', 'Monitor blood pressure',8);
INSERT INTO Prescription VALUES (7,  '2026-05-05', 'With food',            10);
INSERT INTO Prescription VALUES (8,  '2026-05-05', 'Stay hydrated',        12);
INSERT INTO Prescription VALUES (9,  '2026-05-06', 'Take in morning',      14);
INSERT INTO Prescription VALUES (10, '2026-05-07', 'Avoid sunlight',       16);
INSERT INTO Prescription VALUES (11, '2026-05-07', 'With breakfast',       18);
INSERT INTO Prescription VALUES (12, '2026-05-08', 'Monitor glucose',      19);

INSERT INTO Prescription_Medication VALUES (3,  3, '250mg', 'Three times daily');
INSERT INTO Prescription_Medication VALUES (4,  4, '400mg', 'Twice daily');
INSERT INTO Prescription_Medication VALUES (5,  5, '20mg',  'Once daily before bed');
INSERT INTO Prescription_Medication VALUES (6,  8, '10mg',  'Once daily morning');
INSERT INTO Prescription_Medication VALUES (7,  6, '500mg', 'With meals');
INSERT INTO Prescription_Medication VALUES (8,  7, '20mg',  'Once at night');
INSERT INTO Prescription_Medication VALUES (9,  1, '500mg', 'After food');
INSERT INTO Prescription_Medication VALUES (10, 4, '200mg', 'Three times daily');
INSERT INTO Prescription_Medication VALUES (11, 3, '500mg', 'Twice daily');
INSERT INTO Prescription_Medication VALUES (12, 6, '1000mg','With meals');
GO


-- =====================================================
-- STEP 2: CREATE DIMENSION TABLES
-- =====================================================

-- ── Dim_Patient ──────────────────────────────────────
CREATE TABLE Dim_Patient (
    Patient_Key   INT PRIMARY KEY IDENTITY(1,1),
    Patient_id    INT,
    Full_Name     VARCHAR(100),
    Gender        VARCHAR(10),
    Date_of_birth DATE,
    City_State    VARCHAR(50),
    Age_Group     VARCHAR(20)   -- derived attribute for analysis
);

-- ── Dim_Doctor ───────────────────────────────────────
CREATE TABLE Dim_Doctor (
    Doctor_Key  INT PRIMARY KEY IDENTITY(1,1),
    Doctor_id   INT,
    Full_name   VARCHAR(100),
    Speciality  VARCHAR(100)
);

-- ── Dim_Date ─────────────────────────────────────────
CREATE TABLE Dim_Date (
    Date_Key     INT PRIMARY KEY,   -- YYYYMMDD
    Full_Date    DATE,
    Day_Num      INT,
    Month_Num    INT,
    Month_Name   VARCHAR(20),
    Quarter      INT,
    Year_Num     INT,
    Weekday_Name VARCHAR(20)
);

-- ── Dim_Medication ───────────────────────────────────
CREATE TABLE Dim_Medication (
    Medication_Key  INT PRIMARY KEY IDENTITY(1,1),
    Medication_id   INT,
    Medication_Name VARCHAR(100)
);

-- ── Dim_Status ───────────────────────────────────────
-- Holds the appointment status descriptors
CREATE TABLE Dim_Status (
    Status_Key  INT PRIMARY KEY IDENTITY(1,1),
    Status_Name VARCHAR(50)
);

-- ── Dim_Reason ───────────────────────────────────────
-- Holds reason-of-visit categories
CREATE TABLE Dim_Reason (
    Reason_Key  INT PRIMARY KEY IDENTITY(1,1),
    Reason_Name VARCHAR(255)
);
GO


-- =====================================================
-- STEP 3: CREATE FACT TABLE  (keys + measures ONLY)
-- =====================================================
-- TRUE MEASURES (numeric, additive):
--   Appointment_Count   – always 1, used for COUNT aggregations
--   Has_Prescription    – 0/1 flag, summed to get prescription rate
--   Prescription_Count  – number of prescriptions per appointment
--   Medication_Count    – number of medications per appointment

CREATE TABLE Fact_Appointment (
    Fact_id            INT PRIMARY KEY IDENTITY(1,1),
    -- Foreign keys to dimensions
    Appointment_id     INT,
    Patient_Key        INT FOREIGN KEY REFERENCES Dim_Patient(Patient_Key),
    Doctor_Key         INT FOREIGN KEY REFERENCES Dim_Doctor(Doctor_Key),
    Date_Key           INT FOREIGN KEY REFERENCES Dim_Date(Date_Key),
    Status_Key         INT FOREIGN KEY REFERENCES Dim_Status(Status_Key),
    Reason_Key         INT FOREIGN KEY REFERENCES Dim_Reason(Reason_Key),
    Medication_Key     INT FOREIGN KEY REFERENCES Dim_Medication(Medication_Key),
    -- MEASURES only
    Appointment_Count  INT  DEFAULT 1,          -- additive count grain
    Has_Prescription   BIT,                     -- 1 = appointment generated a prescription
    Prescription_Count INT  DEFAULT 0,          -- how many prescriptions for this appointment
    Medication_Count   INT  DEFAULT 0           -- how many medications in those prescriptions
);
GO


-- =====================================================
-- STEP 5: ETL — POPULATE DIMENSION TABLES
-- =====================================================

-- ── Load Dim_Status ──────────────────────────────────
INSERT INTO Dim_Status (Status_Name)
SELECT DISTINCT Status FROM Appointment;

-- ── Load Dim_Reason ──────────────────────────────────
INSERT INTO Dim_Reason (Reason_Name)
SELECT DISTINCT Reason_of_visit FROM Appointment;

-- ── Load Dim_Patient ─────────────────────────────────
INSERT INTO Dim_Patient (Patient_id, Full_Name, Gender, Date_of_birth, City_State, Age_Group)
SELECT
    p.Patient_id,
    p.Full_Name,
    p.Gender,
    p.Date_of_birth,
    ISNULL(pa.City_State, 'Unknown'),
    CASE
        WHEN DATEDIFF(YEAR, p.Date_of_birth, GETDATE()) < 18  THEN 'Under 18'
        WHEN DATEDIFF(YEAR, p.Date_of_birth, GETDATE()) < 35  THEN '18–34'
        WHEN DATEDIFF(YEAR, p.Date_of_birth, GETDATE()) < 55  THEN '35–54'
        ELSE '55+'
    END AS Age_Group
FROM Patient p
LEFT JOIN Patient_Address pa ON p.Patient_id = pa.Patient_id;

-- ── Load Dim_Doctor ──────────────────────────────────
INSERT INTO Dim_Doctor (Doctor_id, Full_name, Speciality)
SELECT Doctor_id, Full_name, Speciality FROM Doctor;

-- ── Load Dim_Date (all distinct appointment dates) ───
INSERT INTO Dim_Date (Date_Key, Full_Date, Day_Num, Month_Num, Month_Name, Quarter, Year_Num, Weekday_Name)
SELECT DISTINCT
    CAST(FORMAT(Appointment_date, 'yyyyMMdd') AS INT),
    Appointment_date,
    DAY(Appointment_date),
    MONTH(Appointment_date),
    DATENAME(MONTH, Appointment_date),
    DATEPART(QUARTER, Appointment_date),
    YEAR(Appointment_date),
    DATENAME(WEEKDAY, Appointment_date)
FROM Appointment
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Date
    WHERE Date_Key = CAST(FORMAT(Appointment_date, 'yyyyMMdd') AS INT)
);

-- ── Load Dim_Medication ──────────────────────────────
INSERT INTO Dim_Medication (Medication_id, Medication_Name)
SELECT Medication_id, Medication_Name FROM Medication;
GO


-- =====================================================
-- STEP 6: ETL — POPULATE FACT TABLE
-- =====================================================
-- One row per appointment × medication combination.
-- Appointments with no prescription get one row with
-- Medication_Key = NULL and Has_Prescription = 0.

INSERT INTO Fact_Appointment (
    Appointment_id,
    Patient_Key,
    Doctor_Key,
    Date_Key,
    Status_Key,
    Reason_Key,
    Medication_Key,
    Appointment_Count,
    Has_Prescription,
    Prescription_Count,
    Medication_Count
)
SELECT
    a.Appointment_id,
    dp.Patient_Key,
    dd.Doctor_Key,
    CAST(FORMAT(a.Appointment_date, 'yyyyMMdd') AS INT)  AS Date_Key,
    ds.Status_Key,
    dr.Reason_Key,
    dm.Medication_Key,                          -- NULL when no medication
    1                                           AS Appointment_Count,
    CASE WHEN pr.Prescription_id IS NOT NULL
         THEN 1 ELSE 0 END                      AS Has_Prescription,
    -- count distinct prescriptions for this appointment
    ISNULL((
        SELECT COUNT(DISTINCT pr2.Prescription_id)
        FROM   Prescription pr2
        WHERE  pr2.Appointment_id = a.Appointment_id
    ), 0)                                       AS Prescription_Count,
    -- count medications in those prescriptions
    ISNULL((
        SELECT COUNT(pm2.Medication_id)
        FROM   Prescription pr2
        JOIN   Prescription_Medication pm2
               ON pr2.Prescription_id = pm2.Prescription_id
        WHERE  pr2.Appointment_id = a.Appointment_id
    ), 0)                                       AS Medication_Count
FROM Appointment a
JOIN Dim_Patient  dp ON a.Patient_id       = dp.Patient_id
JOIN Dim_Doctor   dd ON a.Doctor_id        = dd.Doctor_id
JOIN Dim_Status   ds ON a.Status           = ds.Status_Name
JOIN Dim_Reason   dr ON a.Reason_of_visit  = dr.Reason_Name
LEFT JOIN Prescription           pr  ON a.Appointment_id  = pr.Appointment_id
LEFT JOIN Prescription_Medication pm ON pr.Prescription_id = pm.Prescription_id
LEFT JOIN Dim_Medication          dm ON pm.Medication_id   = dm.Medication_id;
GO

-- Quick row count check (should be 50–100+)
SELECT COUNT(*) AS Fact_Row_Count FROM Fact_Appointment;
GO


-- =====================================================
-- STEP 7: ANALYTICAL QUERIES ON DATA WAREHOUSE
-- =====================================================

-- Q1: Total appointments per doctor
SELECT
    dd.Full_name             AS Doctor_Name,
    dd.Speciality,
    SUM(fa.Appointment_Count) AS Total_Appointments
FROM Fact_Appointment fa
JOIN Dim_Doctor dd ON fa.Doctor_Key = dd.Doctor_Key
GROUP BY dd.Full_name, dd.Speciality
ORDER BY Total_Appointments DESC;

-- Q2: Monthly appointment trend
SELECT
    dt.Year_Num,
    dt.Month_Name,
    SUM(fa.Appointment_Count) AS Monthly_Total
FROM Fact_Appointment fa
JOIN Dim_Date dt ON fa.Date_Key = dt.Date_Key
GROUP BY dt.Year_Num, dt.Month_Num, dt.Month_Name
ORDER BY dt.Year_Num, dt.Month_Num;

-- Q3: Most prescribed medications
SELECT
    dm.Medication_Name,
    COUNT(*) AS Times_Prescribed
FROM Fact_Appointment fa
JOIN Dim_Medication dm ON fa.Medication_Key = dm.Medication_Key
GROUP BY dm.Medication_Name
ORDER BY Times_Prescribed DESC;

-- Q4: Appointment status breakdown
SELECT
    ds.Status_Name,
    COUNT(*) AS Total
FROM Fact_Appointment fa
JOIN Dim_Status ds ON fa.Status_Key = ds.Status_Key
GROUP BY ds.Status_Name;

-- Q5: Appointments per patient per doctor (cross-analysis)
SELECT
    dp.Full_Name   AS Patient_Name,
    dd.Full_name   AS Doctor_Name,
    SUM(fa.Appointment_Count) AS Appointments
FROM Fact_Appointment fa
JOIN Dim_Patient dp ON fa.Patient_Key = dp.Patient_Key
JOIN Dim_Doctor  dd ON fa.Doctor_Key  = dd.Doctor_Key
GROUP BY dp.Full_Name, dd.Full_name
ORDER BY Appointments DESC;

-- Q6: Prescription rate per doctor (% of appointments with prescription)
SELECT
    dd.Full_name                                                       AS Doctor_Name,
    SUM(fa.Appointment_Count)                                          AS Total_Appointments,
    SUM(CAST(fa.Has_Prescription AS INT))                              AS With_Prescription,
    CAST(
        SUM(CAST(fa.Has_Prescription AS INT)) * 100.0
        / NULLIF(SUM(fa.Appointment_Count), 0)
    AS DECIMAL(5,2))                                                   AS Prescription_Rate_Pct
FROM Fact_Appointment fa
JOIN Dim_Doctor dd ON fa.Doctor_Key = dd.Doctor_Key
GROUP BY dd.Full_name
ORDER BY Prescription_Rate_Pct DESC;

-- Q7: Appointments by patient age group
SELECT
    dp.Age_Group,
    SUM(fa.Appointment_Count) AS Total_Appointments
FROM Fact_Appointment fa
JOIN Dim_Patient dp ON fa.Patient_Key = dp.Patient_Key
GROUP BY dp.Age_Group
ORDER BY Total_Appointments DESC;



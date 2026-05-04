// =====================================================
// SECTION 7: MongoDB — Appointment Collection
// Convert the Appointment table into a MongoDB collection
// Run these in MongoDB Shell (mongosh) or MongoDB Compass
// =====================================================

// ========================
// Connect & select database
// ========================
use HealthcareDB;

// ========================
// 7A: INSERT and Creation — Load appointments as documents
// Each document embeds the patient name and doctor name for easy querying
// ========================
db.Appointments.insertMany([
    {
        appointment_id: 1,
        appointment_date: new Date("2026-05-01"),
        appointment_time: "10:00",
        status: "Cancelled",
        reason_of_visit: "Checkup",
        patient: { id: 1, name: "Ahmed Ali", gender: "Male" },
        doctor: { id: 1, name: "Dr. John Smith", speciality: "Cardiology" }
    },
    {
        appointment_id: 2,
        appointment_date: new Date("2026-05-01"),
        appointment_time: "10:30",
        status: "Scheduled",
        reason_of_visit: "Follow-up",
        patient: { id: 2, name: "Sara Mohamed", gender: "Female" },
        doctor: { id: 1, name: "Dr. John Smith", speciality: "Cardiology" }
    },
    {
        appointment_id: 3,
        appointment_date: new Date("2026-05-02"),
        appointment_time: "11:00",
        status: "Scheduled",
        reason_of_visit: "Consultation",
        patient: { id: 3, name: "Omar Hassan", gender: "Male" },
        doctor: { id: 2, name: "Dr. Sara Ali", speciality: "Neurology" }
    },
    {
        appointment_id: 4,
        appointment_date: new Date("2026-06-01"),
        appointment_time: "09:00",
        status: "Scheduled",
        reason_of_visit: "Annual Checkup",
        patient: { id: 3, name: "Omar Hassan", gender: "Male" },
        doctor: { id: 2, name: "Dr. Sara Ali", speciality: "Neurology" }
    }
]);

// ========================
// 7B: FIND — Various query examples
// ========================

// Find all appointments
db.Appointments.find().pretty();

// Find all scheduled appointments
db.Appointments.find({ status: "Scheduled" }).pretty();

// Find appointments for a specific doctor
db.Appointments.find({ "doctor.name": "Dr. John Smith" }).pretty();

// Find appointments on a specific date
db.Appointments.find({ appointment_date: new Date("2026-05-01") }).pretty();

// Find appointments for male patients
db.Appointments.find({ "patient.gender": "Male" }).pretty();

// Find appointments with projection (show only patient name, date, status)
db.Appointments.find(
    { status: "Scheduled" },
    { "patient.name": 1, appointment_date: 1, status: 1, _id: 0 }
).pretty();

// Count appointments per doctor (aggregation)
db.Appointments.aggregate([
    {
        $group: {
            _id: "$doctor.name",
            total_appointments: { $sum: 1 }
        }
    },
    { $sort: { total_appointments: -1 } }
]);

// ========================
// 7C: UPDATE — Modify appointment status
// ========================

// Update a single appointment status to 'Completed'
db.Appointments.updateOne(
    { appointment_id: 2 },
    { $set: { status: "Completed" } }
);

// Update all appointments for a specific doctor to add a note field
db.Appointments.updateMany(
    { "doctor.id": 1 },
    { $set: { notes: "Patient must bring previous reports" } }
);

// Verify the update
db.Appointments.find({ "doctor.id": 1 }).pretty();

// ========================
// 7D: DELETE (bonus — not required but good to show)
// ========================

// Delete a cancelled appointment
db.Appointments.deleteOne({ appointment_id: 1, status: "Cancelled" });

// ========================
// 7E: Create an index in MongoDB (mirrors SQL optimization section)
// ========================

// Index on appointment_date for fast date-based lookups
db.Appointments.createIndex({ appointment_date: 1 });

// Compound index on doctor id + date
db.Appointments.createIndex({ "doctor.id": 1, appointment_date: 1 });

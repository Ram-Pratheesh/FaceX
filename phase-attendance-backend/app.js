// ✅ FaceX Backend (Updated Full Version)

const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");
const path = require("path");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const multer = require("multer");
const fs = require("fs");
const cron = require("node-cron"); // ✅ CRON for auto-absent

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/uploads')); // ✅ Updated


// ===== MongoDB Connection =====
mongoose.connect(process.env.MONGO_URI)
    .then(() => {
        console.log("✅ MongoDB Connected");
        createDefaultAdmin();
        app.listen(5000, () => console.log("🚀 Server running on port 5000"));
    })
    .catch((err) => console.error("❌ MongoDB Error:", err));

// ====== MODELS ======
const studentSchema = new mongoose.Schema({
    name: String,
    reg_no: { type: String, unique: true },
    email: { type: String, unique: true },
    password: String,
    face_image: String,
});
const Student = mongoose.model("Student", studentSchema);

const adminSchema = new mongoose.Schema({
    email: { type: String, unique: true },
    password: String,
});
const Admin = mongoose.model("Admin", adminSchema);

const attendanceSchema = new mongoose.Schema({
    reg_no: String,
    subject: String,
    date: { type: Date, default: Date.now },
    status: { type: String, enum: ['Present', 'Absent'], default: 'Present' }
});
const Attendance = mongoose.model("Attendance", attendanceSchema);

// ====== MULTER CONFIG ======
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const dir = 'D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/uploads'; // ✅ Update here
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        cb(null, dir);
    },
    filename: function (req, file, cb) {
        const ext = path.extname(file.originalname);
        cb(null, `${req.body.reg_no}${ext}`);
    }
});

const upload = multer({ storage: storage });

// ====== DEFAULT ADMIN CREATION ======
const createDefaultAdmin = async () => {
    const existing = await Admin.findOne({ email: "admin@gmail.com" });
    if (!existing) {
        const hashed = await bcrypt.hash("admin123", 10);
        await Admin.create({ email: "admin@gmail.com", password: hashed });
        console.log("🧑‍💻 Default admin created: admin@gmail.com / admin123");
    }
};

// ====== ROUTES ======

app.get("/", (req, res) => {
    res.send("🚀 Attendance Backend is Running");
});

app.post("/admin/add-student", upload.single("face_image"), async (req, res) => {
    try {
        const { name, reg_no, email, password } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);

        const student = new Student({
            name,
            reg_no,
            email,
            password: hashedPassword,
            face_image: req.file?.filename || null
        });

        await student.save();
        res.status(201).json({ message: "Student added successfully ✅" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post("/admin/login", async (req, res) => {
    const { email, password } = req.body;
    const admin = await Admin.findOne({ email });
    if (!admin) return res.status(404).json({ message: "Admin not found" });

    const isMatch = await bcrypt.compare(password, admin.password);
    if (!isMatch) return res.status(401).json({ message: "Invalid credentials" });

    const token = jwt.sign({ id: admin._id }, process.env.JWT_SECRET);
    res.json({ message: "Login success", token });
});

app.post("/student/login", async (req, res) => {
    const { email, password } = req.body;
    const student = await Student.findOne({ email });
    if (!student) return res.status(404).json({ message: "Student not found" });

    const isMatch = await bcrypt.compare(password, student.password);
    if (!isMatch) return res.status(401).json({ message: "Invalid credentials" });

    const token = jwt.sign({ id: student._id }, process.env.JWT_SECRET);
    res.json({ message: "Login success", token, name: student.name, reg_no: student.reg_no });
});

app.post("/attendance/mark", async (req, res) => {
    try {
        const { reg_no, subject } = req.body;
        const student = await Student.findOne({ reg_no });
        if (!student) return res.status(404).json({ message: "Student not found" });

        const newAttendance = new Attendance({ reg_no, subject, status: "Present" });
        await newAttendance.save();

        res.json({ message: `Attendance marked successfully for ${reg_no} ✅`, reg_no });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get("/attendance/status", async (req, res) => {
    const { reg_no, subject, date } = req.query;
    try {
        const dateStart = new Date(date);
        const dateEnd = new Date(date);
        dateStart.setHours(0, 0, 0, 0);
        dateEnd.setHours(23, 59, 59, 999);

        const record = await Attendance.findOne({
            reg_no,
            subject,
            date: { $gte: dateStart, $lte: dateEnd }
        });

        if (!record) return res.status(404).json({ message: "No attendance record found." });

        res.json({ status: record.status, date: record.date });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put("/attendance/update", async (req, res) => {
    const { reg_no, subject, date, status } = req.body;
    try {
        const dateStart = new Date(date);
        const dateEnd = new Date(date);
        dateStart.setHours(0, 0, 0, 0);
        dateEnd.setHours(23, 59, 59, 999);

        const updated = await Attendance.findOneAndUpdate({
            reg_no,
            subject,
            date: { $gte: dateStart, $lte: dateEnd }
        }, {
            status,
        }, { new: true });

        if (!updated) return res.status(404).json({ message: "No matching attendance record to update." });

        res.json({ message: "✅ Attendance updated", updated });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


app.post("/attendance/mark-auto", async (req, res) => {
    const { reg_no } = req.body;
    const subject = getCurrentSubject();

    if (!subject) {
        return res.status(400).json({ message: "❌ Not a valid class period currently." });
    }

    try {
        const student = await Student.findOne({ reg_no });
        if (!student) return res.status(404).json({ message: "Student not found" });

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const alreadyMarked = await Attendance.findOne({
            reg_no,
            subject,
            date: { $gte: today }
        });

        if (alreadyMarked) {
            return res.status(200).json({ message: "⏱ Already marked for this period." });
        }

        const newAttendance = new Attendance({ reg_no, subject, status: "Present" });
        await newAttendance.save();

        res.json({
            message: `✅ Marked Present for ${subject}`,
            reg_no,
            subject,
            time: new Date().toLocaleTimeString()
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete("/student/:reg_no", async (req, res) => {
    try {
        const reg_no = req.params.reg_no;
        const student = await Student.findOne({ reg_no });
        if (!student) return res.status(404).json({ message: "Student not found" });

        const filePath = path.join('D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/uploads', student.face_image); // ✅ Update here

        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

        await Student.deleteOne({ reg_no });
        res.json({ message: `Student ${reg_no} removed successfully` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get("/attendance/:reg_no", async (req, res) => {
    try {
        const attendanceRecords = await Attendance.find({ reg_no: req.params.reg_no });
        res.json(attendanceRecords);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get("/student/attendance/:reg_no", async (req, res) => {
    try {
        const reg_no = req.params.reg_no;
        const records = await Attendance.find({ reg_no });
        const summary = {};

        for (const rec of records) {
            const sub = rec.subject;
            if (!summary[sub]) summary[sub] = { present: 0, total: 0 };
            summary[sub].total += 1;
            if (rec.status === "Present") summary[sub].present += 1;
        }

        for (const sub in summary) {
            const s = summary[sub];
            s.percentage = Math.round((s.present / s.total) * 100);
        }

        res.json({ reg_no, summary });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get("/students", async (req, res) => {
    try {
        const all = await Student.find();
        res.json(all);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ========== ⏰ AUTO-ABSENT CRON LOGIC ==========
const TIMETABLE = {
    "10:00": "Software Construction",
    "11:00": "DBMS",
    "12:00": "AI",
    "14:00": "Web Development",
    "15:00": "Operating Systems",
};

const getCurrentSubject = () => {
    const now = new Date();
    const hour = now.getHours();
    const minute = now.getMinutes();
    const timeKey = `${hour.toString().padStart(2, '0')}:${minute < 30 ? '00' : '30'}`;
    return TIMETABLE[timeKey] || null;
};

const markAbsentees = async (timeKey, subject) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const students = await Student.find();
        const presentStudents = await Attendance.find({
            subject,
            date: { $gte: today },
            status: "Present"
        }).distinct("reg_no");

        const absentees = students
            .filter(s => !presentStudents.includes(s.reg_no))
            .map(s => ({
                reg_no: s.reg_no,
                subject,
                status: "Absent",
                date: new Date()
            }));

        if (absentees.length > 0) {
            await Attendance.insertMany(absentees);
            console.log(`🕐 Marked ${absentees.length} absent for ${subject}`);
        } else {
            console.log(`✅ All students scanned for ${subject}`);
        }
    } catch (err) {
        console.error("❌ Auto-Absent Error:", err.message);
    }
};

for (const [time, subject] of Object.entries(TIMETABLE)) {
    const [hour, minute] = time.split(":");
    cron.schedule(`${minute} ${hour} * * *`, () => {
        console.log(`⏱ Checking for absentees after ${subject}...`);
        markAbsentees(time, subject);
    });
}

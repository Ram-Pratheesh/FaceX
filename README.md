# 🎓 FaceX – Face Recognition Based Attendance System

**FaceX** is a full-stack facial recognition-based attendance tracker tailored for university environments. It automates attendance using facial recognition and provides manual admin-level controls for viewing and editing student records.

This project integrates a Flutter Web Admin Panel, Node.js + MongoDB Backend, and a Python Face Scanner using FaceNet.

---

## 🚀 Features

### 👨‍💼 Admin Panel (Flutter Web)
- Add new students with name, reg_no, email, password, and face image.
- Automatically renames face image to registration number.
- Dynamically view all added students in a sidebar list.
- Remove students with confirmation dialog.
- View subject-wise attendance for any student.
- Navigate to attendance manager for manual edits.

### 🤖 Face Scanner (Python + FaceNet)
- Captures face via webcam or uploads image.
- Generates face embeddings using FaceNet.
- Compares with stored embeddings using cosine similarity.
- Sends attendance record to backend using `/attendance/mark`.

### 🛠 Backend (Node.js + MongoDB)
- REST APIs for student and admin login, attendance management.
- Auto-marks students as **Absent** if not present during the scheduled slot.
- CRON-based absentee scheduler that runs as per time table.
- Image uploads are stored at a fixed path and cleaned on student deletion.

---

## ⚙️ Setup Guide

### 📦 Download Pretrained Model
Please download the **FaceNet pretrained model** manually from the following Google Drive link and place it in the correct scanner directory:

🔗 [Download FaceNet Model (Google Drive)](https://drive.google.com/drive/folders/1Y_GFgJyuPDmquWJlmc_6I4fQORA9EZWb?usp=sharing)

> Save the model folder as `facenet_model` inside the `FaceXScanner` directory.

---

### 🔧 Backend Setup

```bash
cd backend
npm install
```

Create a `.env` file:

```
MONGO_URI=mongodb+srv://<your_uri>
JWT_SECRET=your_jwt_secret
```

Start the server:

```bash
node server.js
```

> 📌 Ensure your upload path is correctly defined in `multer.diskStorage`:
```js
const dir = 'D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/uploads';
```

---

### 🌐 Flutter Web Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

> Requires Flutter SDK and Chrome browser installed.

---

### 🧠 Face Scanner (Python)

```bash
cd FaceXScanner
pip install -r requirements.txt
python app.py
```

Make sure you update paths inside `app.py`:
```python
MODEL_DIR = "D:/FaceX/facenet_model"
UPLOAD_DIR = "D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/uploads"
ATTENDANCE_API = "http://localhost:5000/attendance/mark"
SIMILARITY_THRESHOLD = 0.7
```

---

## 📊 Attendance Flow

1. Admin adds students from Flutter UI with face image.
2. Image gets renamed to registration number and saved to `uploads/`.
3. Scanner captures live face, encodes embedding via FaceNet.
4. Backend compares and marks **Present** if match found.
5. At each subject end time, CRON checks for unmarked students and adds **Absent** records.

---

## 🗂 API Endpoints Summary

| Method | Route                            | Purpose                        |
|--------|----------------------------------|--------------------------------|
| POST   | `/admin/add-student`            | Add student with face image    |
| DELETE | `/student/:reg_no`              | Remove student + delete image  |
| POST   | `/attendance/mark`              | Mark attendance (face scan)    |
| GET    | `/attendance/:reg_no`           | Get all attendance records     |
| GET    | `/student/attendance/:reg_no`   | Attendance summary by subject  |
| POST   | `/admin/login`                  | Admin login                    |
| POST   | `/student/login`                | Student login                  |
| GET    | `/students`                     | Get all registered students    |

---

## 🛠 Built With

- **Flutter Web** – UI frontend
- **Node.js + Express** – Backend server
- **MongoDB Atlas** – NoSQL database
- **Python + FaceNet** – Face recognition model
- **Multer** – For handling image uploads
- **CRON Jobs** – For auto-absentee logic

---

## 📌 Future Additions

- Live attendance charts
- Real-time notifications to students
- Admin dashboard analytics
- Offline fallback mode using QR

---

## 🙌 Developed With Love by Team FaceX – Rajalakshmi Engineering College

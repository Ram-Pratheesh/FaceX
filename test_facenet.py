import os
import cv2
import numpy as np
import tensorflow as tf
from PIL import Image
from mtcnn import MTCNN
from numpy.linalg import norm
import requests
from datetime import datetime

# =========================
# CONFIGURATION
# =========================
# 🔁 Update these paths:
MODEL_DIR = "D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/facenet_model"
UPLOAD_DIR = "D:/Downloads/My Apps(Built Ones)/FaceX/FaceXScanner/uploads"
ATTENDANCE_API = "http://localhost:5000/attendance/mark"  # This is still valid
SIMILARITY_THRESHOLD = 0.6


# 🕐 Timetable (24-hour format)
TIMETABLE = {
    "09:00-10:00": "Software Construction",
    "10:00-11:00": "DBMS",
    "11:00-12:00": "AI",
    "13:00-14:00": "Web Development",
    "14:00-15:00": "Operating Systems",
    "22:00-23:59": "Testing Period"  # ✅ Add this temporarily
}


# =========================
# Get current subject based on time
# =========================
def get_current_subject():
    now = datetime.now().strftime("%H:%M")
    for time_range, subject in TIMETABLE.items():
        start, end = time_range.split("-")
        if start <= now <= end:
            return subject
    return None

# =========================
# Load FaceNet Model
# =========================
def load_model(model_dir):
    print("[INFO] Loading FaceNet model...")
    model = tf.saved_model.load(model_dir)
    return model.signatures["serving_default"]

# =========================
# Detect + Crop Face (with padding)
# =========================
def extract_face_from_frame(frame):
    detector = MTCNN()
    results = detector.detect_faces(frame)

    if not results:
        print("[ERROR] No face detected.")
        return None

    x, y, w, h = results[0]["box"]
    x, y = max(x, 0), max(y, 0)
    x2, y2 = x + w, y + h

    padding = 20
    x = max(0, x - padding)
    y = max(0, y - padding)
    x2 = min(frame.shape[1], x2 + padding)
    y2 = min(frame.shape[0], y2 + padding)

    face = frame[y:y2, x:x2]
    face = cv2.resize(face, (160, 160))
    return face

# =========================
# Get Face Embedding
# =========================
def get_embedding(model, face_pixels):
    face_pixels = face_pixels.astype("float32") / 255.0
    face_pixels = np.expand_dims(face_pixels, axis=0)
    input_tensor = tf.convert_to_tensor(face_pixels)
    embedding = model(input_tensor)["Bottleneck_BatchNorm"]
    return embedding.numpy()[0]

# =========================
# Cosine Similarity
# =========================
def cosine_similarity(a, b):
    return np.dot(a, b) / (norm(a) * norm(b))

# =========================
# Load Student Embeddings
# =========================
def load_all_student_embeddings(model):
    embeddings = []
    for file in os.listdir(UPLOAD_DIR):
        if file.lower().endswith((".jpg", ".png")):
            reg_no = file.split(".")[0]
            image_path = os.path.join(UPLOAD_DIR, file)
            try:
                img = Image.open(image_path).convert("RGB")
                img = np.asarray(img.resize((160, 160)))
                emb = get_embedding(model, img)
                embeddings.append((reg_no, emb))
            except Exception as e:
                print(f"[WARN] Failed to process {file}: {e}")
    return embeddings

# =========================
# Mark Attendance via API
# =========================
def mark_attendance(reg_no, subject):
    payload = {
        "reg_no": reg_no,
        "subject": subject
    }
    try:
        response = requests.post(ATTENDANCE_API, json=payload)
        if response.status_code == 200:
            print(f"✅ Attendance marked for {reg_no} in {subject}")
        else:
            print("❌ Error marking attendance:", response.text)
    except Exception as e:
        print("❌ Request failed:", e)

# =========================
# Main Scanner Logic
# =========================
def main():
    model = load_model(MODEL_DIR)
    student_embeddings = load_all_student_embeddings(model)

    print("[INFO] Starting camera for scanning... Press 's' to scan | 'q' to quit")
    cap = cv2.VideoCapture(0)

    while True:
        ret, frame = cap.read()
        if not ret:
            print("[ERROR] Failed to grab frame.")
            break

        cv2.imshow("Face Scanner - Press 's' to scan", frame)
        key = cv2.waitKey(1)

        if key == ord("s"):
            current_subject = get_current_subject()
            if not current_subject:
                print("⛔ No subject scheduled at this time.")
                continue

            print(f"[SCAN] Period in session: {current_subject}")
            face = extract_face_from_frame(frame)
            if face is None:
                print("[SCAN] Try again with better lighting or clearer face.")
                continue

            scanned_emb = get_embedding(model, face)

            matched = False
            for reg_no, known_emb in student_embeddings:
                similarity = cosine_similarity(scanned_emb, known_emb)
                print(f"🔍 Comparing with {reg_no} → Similarity: {similarity:.4f}")

                if similarity > SIMILARITY_THRESHOLD:
                    print(f"✅ Match found: {reg_no}")
                    mark_attendance(reg_no, current_subject)
                    matched = True
                    break

            if not matched:
                print("❌ No match found. Try scanning again.")

        elif key == ord("q"):
            print("[INFO] Quitting scanner...")
            break

    cap.release()
    cv2.destroyAllWindows()

# =========================
# Run
# =========================
if __name__ == "__main__":
    main()

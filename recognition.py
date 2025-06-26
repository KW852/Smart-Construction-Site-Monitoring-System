from flask import Flask, Response
import cv2
import threading
import time
import firebase_admin
from firebase_admin import credentials, db
from ultralytics import YOLO

app = Flask(__name__)

cred = credentials.Certificate(
    "xxx.json"
)
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xxx/'
})

class_labels = ['helmet', 'no_helmet']
class_colors = {
    'helmet': (0, 255, 0),     
    'no_helmet': (0, 0, 255)   
}

model = YOLO("model/weights/best.pt")
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    print("Error")
    exit()

frame_lock = threading.Lock()
frame = None
detection_result = []
last_firebase_update_time = time.time()

def update_firebase(no_helmet_count):
    ref = db.reference('x/no_helmet')
    ref.set(no_helmet_count)


def detect_objects():
    global frame, detection_result, last_firebase_update_time

    while True:
        if frame is not None:
            try:
                with frame_lock:
                    results = model(frame)
                detection_result = results

                current_time = time.time()
                if current_time - last_firebase_update_time >= 1.0:
                    no_helmet_count = sum(
                        int(box.cls[0]) == 1
                        for result in results
                        for box in result.boxes
                    )
                    update_firebase(no_helmet_count)
                    last_firebase_update_time = current_time

            except Exception as e:
                print(f"YOLO Error: {e}")

def gen_frames():
    global frame
    while True:
        ret, frame_read = cap.read()
        if not ret:
            break

        with frame_lock:
            frame = frame_read.copy()

            for result in detection_result:
                boxes = result.boxes
                for box in boxes:
                    x1, y1, x2, y2 = box.xyxy[0].int().tolist()
                    confidence = box.conf[0]
                    class_id = int(box.cls[0])
                    label = f"{class_labels[class_id]}: {confidence:.2f}"
                    color = class_colors[class_labels[class_id]]

                    cv2.rectangle(frame_read, (x1, y1), (x2, y2), color, 2)
                    cv2.putText(frame_read, label, (x1, y1 - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.9, color, 2)

        ret, buffer = cv2.imencode('.jpg', frame_read)
        if not ret:
            continue

        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

@app.route('/video_feed')
def video_feed():
    return Response(gen_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == "__main__":
    detection_thread = threading.Thread(target=detect_objects, daemon=True)
    detection_thread.start()

    app.run(host='0.0.0.0', port=5001, threaded=True)
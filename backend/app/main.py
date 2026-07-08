import cv2
import uvicorn
from fastapi import FastAPI
from fastapi.responses import StreamingResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware

from app.camera import Camera
from app.detector import CatDetector
from app.mqtt_client import connect, manual_feed
import app.mqtt_client as mqtt_client

app = FastAPI(title="Cat Feeder Vision API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

connect()
camera = Camera()
detector = CatDetector()


def generate_frames():
    while True:
        frame = camera.get_frame()
        if frame is None:
            continue

        frame = detector.detect(frame)
        frame = cv2.resize(frame, (480, 270))

        _, buffer = cv2.imencode(
            ".jpg",
            frame,
            [cv2.IMWRITE_JPEG_QUALITY, 55]
        )
        frame_bytes = buffer.tobytes()

        yield (
            b"--frame\r\n"
            b"Content-Type: image/jpeg\r\n\r\n"
            + frame_bytes +
            b"\r\n"
        )


@app.get("/video")
def video_stream():
    return StreamingResponse(
        generate_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )


@app.get("/status")
def get_status():
    return {
        "cooldown": mqtt_client.cooldown_remaining
    }


@app.post("/feed/manual")
def feed_manual():
    """Called from the 'Feed Now' button in the Flutter app."""
    manual_feed()
    return {"success": True, "message": "Manual feed command sent to ESP32"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=False
    )
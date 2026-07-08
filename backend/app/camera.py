import cv2
import os
import time
import threading
import queue
import numpy as np

class Camera:
    def __init__(self):
        self.cap = None
        self.frame_queue = queue.Queue(maxsize=2)
        self.running = False
        self.capture_thread = None

        video_devices = sorted([f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")])
        print("Found devices:", video_devices)

        for dev in video_devices:
            print(f"🔄 Trying camera: {dev}")
            cap = cv2.VideoCapture(dev, cv2.CAP_V4L2)

            cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            cap.set(cv2.CAP_PROP_FPS, 30)
            cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)
            cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'))
            cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)
            cap.set(cv2.CAP_PROP_AUTO_EXPOSURE, 1)
            cap.set(cv2.CAP_PROP_EXPOSURE, 100)

            time.sleep(0.5)

            if cap.isOpened():
                ret, frame = cap.read()
                if ret:
                    print(f"Camera ACTIVE at {dev}")
                    self.cap = cap
                    self.start_capture_thread()
                    return
                else:
                    print(f"Opened but no frame from {dev}")

            cap.release()

        raise RuntimeError("No working camera detected")

    def start_capture_thread(self):
        self.running = True
        self.capture_thread = threading.Thread(target=self._capture_frames, daemon=True)
        self.capture_thread.start()
        print(" Capture thread started")

    def _capture_frames(self):
        frame_count = 0
        fps_timer = time.time()

        while self.running and self.cap.isOpened():
            try:
                ret, frame = self.cap.read()
                if not ret:
                    time.sleep(0.01)
                    continue

                frame_count += 1
                if frame_count % 100 == 0:
                    fps_timer = time.time()

                if self.frame_queue.full():
                    try:
                        self.frame_queue.get_nowait()
                    except queue.Empty:
                        pass

                self.frame_queue.put(frame.copy(), block=False)
                time.sleep(0.001)

            except Exception as e:
                print(f"Capture error: {e}")
                time.sleep(0.1)

    def get_frame(self):
        if not self.running or self.frame_queue.empty():
            return None
        try:
            return self.frame_queue.get_nowait()
        except queue.Empty:
            return None

    def stop(self):
        self.running = False
        if self.capture_thread:
            self.capture_thread.join(timeout=1.0)
        if self.cap:
            self.cap.release()
        print("📷 Camera stopped")

    def release(self):
        self.stop()
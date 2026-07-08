# Cat Feeder Vision App

Cat Feeder Vision App is a full-stack project for a smart cat feeder that uses a camera, computer vision, and MQTT to detect cats and trigger feeding actions.

The system consists of:

- Backend: FastAPI service for streaming video, exposing status endpoints, and communicating with MQTT.
- Frontend: Flutter mobile/web app to view the camera stream, monitor status, and trigger manual feeding.
- Hardware integration: ESP32-based feeder controller and MQTT messaging for real-time communication.

## Project Structure

```text
cat_feeder_vision_app/
├── backend/
│   ├── app/
│   │   ├── camera.py
│   │   ├── detector.py
│   │   ├── main.py
│   │   └── mqtt_client.py
│   └── requirements.txt
├── frontend/
│   ├── lib/
│   │   ├── config/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── service/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
├── .gitignore
└── README.md
```

## Requirements

### Hardware

- Raspberry Pi or a Linux-based machine with a camera module or USB webcam
- ESP32 board connected to the feeder mechanism
- Stable Wi-Fi network
- Optional: power supply and relay module for the feeder

### Software

- Python 3.10+
- Flutter SDK 3.12+
- Git
- A working camera device connected to the backend machine

## Backend Setup

### 1. Create a Python virtual environment

From the project root:

```bash
cd backend
python -m venv venv
source venv/bin/activate
```

On Windows PowerShell:

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Verify camera access

Make sure your camera is available to OpenCV. You can test it with:

```bash
python -c "import cv2; print(cv2.__version__)"
```

### 4. Run the backend server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The backend will expose:

- /video for MJPEG-style camera stream
- /status for current feeder status
- /feed/manual for manual feeding trigger
- /health for health checks

## Frontend Setup

### 1. Install Flutter dependencies

From the project root:

```bash
cd frontend
flutter pub get
```

### 2. Configure backend URL

Open [frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart) and make sure the backend IP address matches your machine:

```dart
static const String baseUrl = "http://YOUR_BACKEND_IP:8000";
```

If the backend runs on the same local network, use the Raspberry Pi or computer IP address, not localhost.

### 3. Run the frontend app

```bash
flutter run
```

For Android build:

```bash
flutter build apk --debug
```

## MQTT Configuration

The backend uses MQTT to communicate with the ESP32 feeder controller.

### Required MQTT settings

- Broker: broker.emqx.io
- Port: 1883
- Topics:
  - cat/feeding
  - cat/status

### How it works

- The backend detects a cat using computer vision.
- When a cat is detected, it publishes a message to the feeder topic.
- The ESP32 listens for that topic and triggers the feeder mechanism.
- The backend also publishes status updates so the Flutter app can display current state.

## Cat Detection Setup

The cat detection pipeline uses Ultralytics YOLO.

### Notes

- The first run may download the YOLO model automatically.
- A camera must be available and accessible by OpenCV.
- Detection performance depends on CPU/GPU, camera quality, and lighting.

If the model is not downloaded automatically, you may need to ensure internet access during the first run.

## ESP32 Integration

The ESP32 should be configured to:

- connect to the same MQTT broker
- subscribe to cat/feeding
- publish status updates to cat/status
- trigger the feeder relay when the feed topic is received

Example behavior:

1. Backend detects a cat.
2. Backend publishes to cat/feeding.
3. ESP32 receives the message.
4. ESP32 activates the feeder servo/relay.
5. ESP32 publishes status back to the app.

## Troubleshooting

### Backend cannot connect to camera

- Check that the webcam is connected.
- Verify OpenCV can access the device.
- Try another camera index or device path.

### Frontend cannot connect to backend

- Confirm the backend IP in [frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart).
- Make sure the backend is running and reachable from the phone/device.
- Check firewall rules on the backend machine.

### MQTT not working

- Verify internet access to the broker.
- Ensure the ESP32 and backend use the same topics.
- Check the MQTT connection logs in the backend console.

## Development Notes

- Keep the backend and frontend in separate terminals while developing.
- Use a virtual environment for Python dependencies.
- For production, consider changing the MQTT broker and securing the network.

## License

This project is intended for personal or educational use. Adapt it as needed for your hardware setup.

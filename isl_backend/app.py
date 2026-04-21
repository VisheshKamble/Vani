from fastapi import FastAPI, WebSocket, WebSocketDisconnect  # FastAPI framework + WebSocket support
from fastapi.middleware.cors import CORSMiddleware  # Middleware to handle CORS (cross-origin requests)
import cv2  # OpenCV for image processing
import numpy as np  # NumPy for array handling
import base64  # For encoding/decoding image data
import asyncio  # For async operations (important for real-time)
import os  # For environment variables and file handling
import time  # For time-based operations (frame control)
import logging  # For logging events
from collections import deque  # Used for smoothing predictions
from urllib.request import urlopen  # For downloading model
import gdown  # For downloading from Google Drive
from ultralytics import YOLO  # YOLO model for object detection


# LOGGING SETUP

logging.basicConfig(
    level=logging.INFO,  # Log level (INFO = important messages)
    format="%(asctime)s  [%(levelname)s]  %(message)s",  # Format of log output
    datefmt="%H:%M:%S",  # Time format
)
log = logging.getLogger("vani")  # Create logger named "vani"


# FASTAPI CONFIG

app = FastAPI(title="VANI ISL Backend", version="2.2.0")  # Initialize FastAPI app


# Function to convert comma-separated environment variable into list
def _parse_csv_env(name: str) -> list[str]:
    raw = os.getenv(name, "")  # Get env variable value
    return [item.strip() for item in raw.split(",") if item.strip()]  # Clean and split


# Read allowed origins for CORS
cors_origins = _parse_csv_env("VANI_CORS_ORIGINS")

# Regex pattern for allowed origins (localhost + railway apps)
cors_origin_regex = os.getenv(
    "VANI_CORS_ORIGIN_REGEX",
    r"^(https?://(localhost|127\.0\.0\.1)(:\d+)?|https://.*\.up\.railway\.app)$",
)

# Add CORS middleware to allow frontend to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,  # Specific allowed domains
    allow_origin_regex=None if cors_origins else cors_origin_regex,  # Use regex if no explicit origins
    allow_credentials=True,  # Allow cookies/auth headers
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)


# MODEL MANAGEMENT (YOLOv11 + G-DRIVE)


os.makedirs("model", exist_ok=True)  # Create model folder if not exists

MODEL_PATH = os.path.join("model", "isl_best.pt")  # Path where model will be stored

FILE_ID = "1TcCNyM1MtbixlN3wZgFttOlvuJutTPqB"  # Google Drive file ID

MIN_MODEL_BYTES = 10_000_000  # Minimum expected size (to detect corruption)


# Function to download model using direct URL
def _download_model(url: str, destination: str) -> None:
    with urlopen(url) as response, open(destination, "wb") as target:
        while True:
            chunk = response.read(1024 * 1024)  # Read in chunks (1MB)
            if not chunk:
                break
            target.write(chunk)  # Write to file


# Function to download model from Google Drive
def _download_model_from_drive(file_id: str, destination: str) -> None:
    url = f"https://drive.google.com/uc?id={file_id}"

    try:
        # Primary method using gdown
        gdown.download(url, destination, quiet=False, fuzzy=True)
        return
    except Exception as e:
        log.warning(f"gdown download failed, trying urllib fallback: {e}")

    # Fallback method if gdown fails
    _download_model(url, destination)


# Check if model file is valid
def _is_model_file_valid(path: str) -> bool:
    return os.path.exists(path) and os.path.getsize(path) >= MIN_MODEL_BYTES


# Function to initialize model
def initialize_model():
    """Downloads model if missing/corrupt and loads into memory."""

    # Delete corrupted file if too small
    if os.path.exists(MODEL_PATH) and os.path.getsize(MODEL_PATH) < MIN_MODEL_BYTES:
        log.info("Deleting corrupted model file...")
        os.remove(MODEL_PATH)

    # Download model if not present
    if not os.path.exists(MODEL_PATH):
        try:
            log.info(f"Downloading model ID: {FILE_ID}")
            _download_model_from_drive(FILE_ID, MODEL_PATH)

            # Validate downloaded file
            if not _is_model_file_valid(MODEL_PATH):
                raise RuntimeError(
                    f"Downloaded file appears invalid (size={os.path.getsize(MODEL_PATH)} bytes)."
                )

            log.info("Download complete!")
        except Exception as e:
            log.error(f"Download failed: {e}")
            return None

    # Load YOLO model
    try:
        loaded_model = YOLO(MODEL_PATH)  # Load model
        loaded_model.to("cpu")  # Run on CPU
        loaded_model.fuse()  # Optimize model (faster inference)
        log.info(f"YOLO Model loaded successfully from {MODEL_PATH}")
        return loaded_model
    except Exception as e:
        log.error(f"Model failed to load: {e}")
        return None


# Load model globally when server starts
model = initialize_model()


# INFERENCE LOGIC


CONF_THRESHOLD = 0.30  # Minimum confidence to consider detection
MAX_DET = 1  # Maximum detections per frame
FRAME_SKIP_MS = 80  # Skip frames to control FPS (~12 FPS)


# Class to smooth predictions (avoid flickering results)
class PredictionSmoother:
    def __init__(self, window: int = 5):
        self._buf = deque(maxlen=window)  # Store last N predictions

    def push(self, label: str, conf: float):
        self._buf.append((label, conf))  # Add new prediction

        labels = [l for l, _ in self._buf]  # Extract labels
        dominant = max(set(labels), key=labels.count)  # Most frequent label

        # Average confidence for dominant label
        avg_conf = sum(c for l, c in self._buf if l == dominant) / labels.count(dominant)

        return dominant, round(avg_conf, 2)

    def reset(self):
        self._buf.clear()  # Clear history


# ─────────────────────────────────────────────
# WEBSOCKET ENDPOINT
# ─────────────────────────────────────────────

@app.websocket("/ws")  # WebSocket route for real-time communication
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()  # Accept connection
    log.info(f"WebSocket Connected: {websocket.client}")
    
    # If model failed to load, send error
    if model is None:
        await websocket.send_json({"type": "error", "message": "Model not available on server"})
        await websocket.close()
        return

    smoother = PredictionSmoother()  # Initialize smoother
    last_infer_time = 0.0  # Last inference timestamp
    frame_count = 0  # Frame counter

    try:
        while True:
            # Receive frame data (Base64 string)
            try:
                raw_data = await asyncio.wait_for(websocket.receive_text(), timeout=20.0)
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "ping"})  # Keep connection alive
                continue

            # Handle special commands
            if raw_data == "__PING__":
                await websocket.send_json({"type": "pong"})
                continue
            if raw_data == "__STOP__":
                smoother.reset()
                continue

            # Frame skipping logic for performance
            current_time = time.monotonic() * 1000
            if (current_time - last_infer_time) < FRAME_SKIP_MS:
                continue

            try:
                # Convert Base64 → bytes → NumPy → OpenCV image
                header, encoded = raw_data.split(",", 1) if "," in raw_data else (None, raw_data)
                img_bytes = base64.b64decode(encoded)
                np_img = np.frombuffer(img_bytes, dtype=np.uint8)
                frame = cv2.imdecode(np_img, cv2.IMREAD_COLOR)

                if frame is None:
                    continue
                #model prediction (non-blocking)
                # Run model inference in separate thread (non-blocking)
                loop = asyncio.get_running_loop()
                results = await loop.run_in_executor(None, lambda: model.predict(
                    frame, 
                    device="cpu", 
                    verbose=False, 
                    conf=CONF_THRESHOLD, 
                    max_det=MAX_DET
                )[0])

                last_infer_time = time.monotonic() * 1000
                frame_count += 1

                # Process prediction result
                if len(results.boxes) > 0:
                    box = results.boxes[0]
                    cls_id = int(box.cls[0])  # Class index
                    raw_label = model.names[cls_id]  # Class name
                    raw_conf = float(box.conf[0])  # Confidence
                    label, conf = smoother.push(raw_label, raw_conf)
                else:
                    label, conf = smoother.push("No Sign", 0.0)

                # Send prediction back to client
                await websocket.send_json({
                    "type": "prediction",
                    "label": label,
                    "confidence": conf,
                    "frame": frame_count
                })

            except Exception as e:
                log.debug(f"Frame processing error: {e}")
                continue

    except WebSocketDisconnect:
        log.info(f"WebSocket Disconnected: {websocket.client}")
    finally:
        smoother.reset()


# SYSTEM ENDPOINTS


@app.get("/health")  # Health check API
def health_check():
    return {
        "status": "online",
        "model_loaded": model is not None,
        "engine": "YOLOv11-CPU"
    }


# Run server directly (for local execution)
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))  # Get port from environment
    uvicorn.run("app:app", host="0.0.0.0", port=port, log_level="info")

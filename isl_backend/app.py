from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import base64
import asyncio
import os
import time
import logging
from collections import deque
import gdown
from ultralytics import YOLO

# ─────────────────────────────────────────────
# LOGGING SETUP
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  [%(levelname)s]  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("vani")

# ─────────────────────────────────────────────
# FASTAPI CONFIG
# ─────────────────────────────────────────────
app = FastAPI(title="VANI ISL Backend", version="2.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────
# MODEL MANAGEMENT (YOLOv11 + G-DRIVE)
# ─────────────────────────────────────────────
os.makedirs("model", exist_ok=True)
MODEL_PATH = os.path.join("model", "isl_best.pt")
# Direct ID from your link
FILE_ID = "1TcCNyM1MtbixlN3wZgFttOlvuJutTPqB"

def initialize_model():
    """Downloads model if missing/corrupt and loads into memory."""
    # 1. Clean up old/failed downloads (HTML error pages are usually < 1MB)
    if os.path.exists(MODEL_PATH) and os.path.getsize(MODEL_PATH) < 1_000_000:
        log.info("🗑️ Deleting corrupted model file (size too small)...")
        os.remove(MODEL_PATH)

    # 2. Download from Google Drive
    if not os.path.exists(MODEL_PATH):
        try:
            log.info(f"📥 Downloading model ID: {FILE_ID}")
            url = f"https://drive.google.com/uc?id={FILE_ID}"
            gdown.download(url, MODEL_PATH, quiet=False)
            log.info("✅ Download complete!")
        except Exception as e:
            log.error(f"❌ Download failed: {e}")
            return None

    # 3. Load YOLO model
    try:
        # Note: 'ultralytics>=8.3.0' is required for YOLOv11 (C3k2 layer)
        loaded_model = YOLO(MODEL_PATH)
        loaded_model.to("cpu")
        loaded_model.fuse() 
        log.info(f"✅ YOLO Model loaded successfully from {MODEL_PATH}")
        return loaded_model
    except Exception as e:
        log.error(f"❌ Model failed to load: {e}")
        return None

# Global model instance
model = initialize_model()

# ─────────────────────────────────────────────
# INFERENCE LOGIC
# ─────────────────────────────────────────────
CONF_THRESHOLD = 0.30
MAX_DET = 1
FRAME_SKIP_MS = 80  # Max ~12 FPS for CPU stability

class PredictionSmoother:
    def __init__(self, window: int = 5):
        self._buf = deque(maxlen=window)

    def push(self, label: str, conf: float):
        self._buf.append((label, conf))
        labels = [l for l, _ in self._buf]
        dominant = max(set(labels), key=labels.count)
        avg_conf = sum(c for l, c in self._buf if l == dominant) / labels.count(dominant)
        return dominant, round(avg_conf, 2)

    def reset(self):
        self._buf.clear()

# ─────────────────────────────────────────────
# WEBSOCKET ENDPOINT
# ─────────────────────────────────────────────
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    log.info(f"🔌 WebSocket Connected: {websocket.client}")
    
    if model is None:
        await websocket.send_json({"type": "error", "message": "Model not available on server"})
        await websocket.close()
        return

    smoother = PredictionSmoother()
    last_infer_time = 0.0
    frame_count = 0

    try:
        while True:
            # Receive data (Base64 string)
            try:
                raw_data = await asyncio.wait_for(websocket.receive_text(), timeout=20.0)
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "ping"})
                continue

            # Handling Protocol Commands
            if raw_data == "__PING__":
                await websocket.send_json({"type": "pong"})
                continue
            if raw_data == "__STOP__":
                smoother.reset()
                continue

            # Frame Throttling
            current_time = time.monotonic() * 1000
            if (current_time - last_infer_time) < FRAME_SKIP_MS:
                continue

            try:
                # Decode Base64 to OpenCV Image
                header, encoded = raw_data.split(",", 1) if "," in raw_data else (None, raw_data)
                img_bytes = base64.b64decode(encoded)
                np_img = np.frombuffer(img_bytes, dtype=np.uint8)
                frame = cv2.imdecode(np_img, cv2.IMREAD_COLOR)

                if frame is None:
                    continue

                # Run Inference in thread pool to keep loop responsive
                loop = asyncio.get_event_loop()
                results = await loop.run_in_executor(None, lambda: model.predict(
                    frame, 
                    device="cpu", 
                    verbose=False, 
                    conf=CONF_THRESHOLD, 
                    max_det=MAX_DET
                )[0])

                last_infer_time = time.monotonic() * 1000
                frame_count += 1

                # Process Results
                if len(results.boxes) > 0:
                    box = results.boxes[0]
                    cls_id = int(box.cls[0])
                    raw_label = model.names[cls_id]
                    raw_conf = float(box.conf[0])
                    label, conf = smoother.push(raw_label, raw_conf)
                else:
                    label, conf = smoother.push("No Sign", 0.0)

                # Send Response
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
        log.info(f"🔌 WebSocket Disconnected: {websocket.client}")
    finally:
        smoother.reset()

# ─────────────────────────────────────────────
# SYSTEM ENDPOINTS
# ─────────────────────────────────────────────
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "model_loaded": model is not None,
        "engine": "YOLOv11-CPU"
    }

if __name__ == "__main__":
    import uvicorn
    # Railway sets the PORT environment variable automatically
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("app:app", host="0.0.0.0", port=port, log_level="info")
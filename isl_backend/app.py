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
import urllib.request
from ultralytics import YOLO

# ─────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  [%(levelname)s]  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("vani")

# ─────────────────────────────────────────────
# APP & CORS
# ─────────────────────────────────────────────
app = FastAPI(title="VANI ISL Backend", version="2.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────
# MODEL LOAD (CPU FORCED & AUTO-DOWNLOAD)
# ─────────────────────────────────────────────
os.makedirs("model", exist_ok=True)
MODEL_PATH = os.path.join("model", "isl_best.pt")

# Insert the URL you copied from GitHub Releases here:
DOWNLOAD_URL = "https://github.com/VisheshKamble/ISL/blob/main/isl_backend/model/isl_best.pt"

# If the file doesn't exist OR it's a tiny fake Git LFS file (under 1MB)
if not os.path.exists(MODEL_PATH) or os.path.getsize(MODEL_PATH) < 1000000:
    log.info(f"Downloading model weights from {DOWNLOAD_URL}...")
    try:
        urllib.request.urlretrieve(DOWNLOAD_URL, MODEL_PATH)
        log.info("✅ Download complete!")
    except Exception as e:
        log.error(f"❌ Failed to download model: {e}")
        raise

try:
    model = YOLO(MODEL_PATH)
    model.to("cpu")  # Force CPU
    log.info(f"✅ Model loaded successfully from {MODEL_PATH}")
except Exception as e:
    log.error(f"❌ Model failed to load: {e}")
    raise

# ─────────────────────────────────────────────
# INFERENCE CONFIG
# ─────────────────────────────────────────────
CONF_THRESHOLD = 0.30
MAX_DET = 1
SMOOTH_WINDOW = 5
FRAME_SKIP_MS = 80  # ~12 FPS

# ─────────────────────────────────────────────
# TEMPORAL SMOOTHER
# ─────────────────────────────────────────────
class PredictionSmoother:
    def __init__(self, window: int = SMOOTH_WINDOW):
        self._window = window
        self._buf = deque(maxlen=window)

    def push(self, label: str, conf: float):
        self._buf.append((label, conf))
        if len(self._buf) < self._window:
            return label, conf

        labels = [l for l, _ in self._buf]
        dominant = max(set(labels), key=labels.count)
        avg_conf = sum(
            c for l, c in self._buf if l == dominant
        ) / labels.count(dominant)

        return dominant, round(avg_conf, 2)

    def reset(self):
        self._buf.clear()

# ─────────────────────────────────────────────
# WEBSOCKET ENDPOINT
# ─────────────────────────────────────────────
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    client = websocket.client
    log.info(f"🔌 Connected {client}")

    smoother = PredictionSmoother()
    last_infer = 0.0
    frame_count = 0
    err_count = 0
    MAX_ERRORS = 10

    try:
        while True:
            try:
                raw = await asyncio.wait_for(
                    websocket.receive_text(), timeout=15.0
                )
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "ping"})
                continue

            # Stop signal
            if raw == "__STOP__":
                smoother.reset()
                await websocket.send_json({"type": "stopped"})
                continue

            if raw == "__PING__":
                await websocket.send_json({"type": "pong"})
                continue

            # Frame throttle
            now_ms = time.monotonic() * 1000
            if (now_ms - last_infer) < FRAME_SKIP_MS:
                await asyncio.sleep(0.005)
                continue

            # Decode base64 image
            try:
                b64 = raw.split(",")[-1]
                img_bytes = base64.b64decode(b64)
                np_img = np.frombuffer(img_bytes, dtype=np.uint8)
                frame = cv2.imdecode(np_img, cv2.IMREAD_COLOR)

                if frame is None:
                    raise ValueError("Invalid frame")

                err_count = 0
            except Exception as e:
                err_count += 1
                log.warning(f"Decode error ({err_count}/{MAX_ERRORS}): {e}")
                if err_count >= MAX_ERRORS:
                    await websocket.send_json(
                        {"type": "error", "message": "Too many bad frames"}
                    )
                    break
                continue

            # Inference (non-blocking)
            try:
                loop = asyncio.get_event_loop()
                results = await loop.run_in_executor(
                    None,
                    lambda: model.predict(
                        frame,
                        device="cpu",
                        verbose=False,
                        conf=CONF_THRESHOLD,
                        max_det=MAX_DET,
                    )[0],
                )
            except Exception as e:
                log.error(f"Inference error: {e}")
                await websocket.send_json(
                    {"type": "error", "message": "Inference failed"}
                )
                continue

            last_infer = time.monotonic() * 1000
            frame_count += 1

            # Build response
            if len(results.boxes) > 0:
                box = results.boxes[0]
                raw_label = model.names[int(box.cls[0])]
                raw_conf = float(box.conf[0])
                label, conf = smoother.push(raw_label, raw_conf)

                payload = {
                    "type": "prediction",
                    "label": label,
                    "confidence": conf,
                    "frame": frame_count,
                }
            else:
                smoother.push("No Sign", 0.0)
                payload = {
                    "type": "prediction",
                    "label": "No Sign",
                    "confidence": 0.0,
                    "frame": frame_count,
                }

            await websocket.send_json(payload)
            await asyncio.sleep(0.001)

    except WebSocketDisconnect:
        log.info(f"Disconnected {client}")
    except Exception as e:
        log.error(f"Unexpected error: {e}")
    finally:
        smoother.reset()
        log.info(f"Session cleaned for {client}")

# ─────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_PATH}

# ─────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info",
    )
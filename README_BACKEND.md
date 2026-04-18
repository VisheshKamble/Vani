# VANI Backend README

This document explains your backend architecture, code flow, and line-by-line logic for exam preparation.

## 1) Backend overview

Backend stack:

- FastAPI for HTTP + WebSocket server
- Uvicorn runtime
- Ultralytics YOLO for ISL inference
- OpenCV + NumPy for image decoding
- gdown/urllib for model download

Main backend file:

- `isl_backend/app.py`

Other backend files:

- `isl_backend/requirements.txt`
- `isl_backend/Dockerfile`
- `isl_backend/railway.json`

## 2) API contract

### HTTP endpoint

- `GET /health`
- Returns server status, model load status, engine info

Example:

```json
{
  "status": "online",
  "model_loaded": true,
  "engine": "YOLOv11-CPU"
}
```

### WebSocket endpoint

- `WS /ws`
- Input:
  - Base64 frame text (with or without data URI prefix)
  - `__PING__`
  - `__STOP__`
- Output:
  - prediction payloads
  - protocol keepalive messages
  - error payload if model unavailable

## 3) High-level runtime flow

```text
Client connects to /ws
  -> server accepts websocket
  -> validates model availability
  -> receives Base64 frames
  -> decodes frame into OpenCV image
  -> runs YOLO on CPU
  -> smoothes prediction
  -> sends label+confidence JSON
```

## 4) Detailed code walkthrough of app.py (top to bottom)

This section explains the backend code in execution order, so you can present it as "line-by-line logic" in viva.

### Block A: Imports

- `FastAPI`, `WebSocket`, `WebSocketDisconnect`: API server and socket handling
- `CORSMiddleware`: CORS control for frontend origins
- `cv2`, `numpy`, `base64`: image decode pipeline
- `asyncio`, `time`: async control + throttling
- `os`: env and filesystem operations
- `logging`: structured runtime logs
- `deque`: smoothing buffer
- `urlopen`, `gdown`: model download sources
- `YOLO`: model loading/inference

Why it matters: these imports directly map to each pipeline step (network, decode, infer, respond).

### Block B: Logging setup

- Configures global logging level and format.
- Creates `log` logger named `vani`.

Why: production debugging becomes much easier in Railway logs.

### Block C: FastAPI app config

- Creates `app = FastAPI(title="VANI ISL Backend", version="2.2.0")`.
- Defines helper `_parse_csv_env` to parse CSV origin allow-lists.
- Reads env vars:
  - `VANI_CORS_ORIGINS`
  - `VANI_CORS_ORIGIN_REGEX`
- Applies CORS middleware.

Why: controls who can call your backend and keeps browser requests valid.

### Block D: Model management constants

- Ensures `model/` directory exists.
- Sets model file path `model/isl_best.pt`.
- Stores Google Drive file id.
- Defines `MIN_MODEL_BYTES` as corruption guard.

Why: backend can auto-recover model artifact and avoid loading broken files.

### Block E: Download helpers

- `_download_model(url, destination)`: raw chunked binary download.
- `_download_model_from_drive(...)`: first try `gdown`, fallback to urllib.
- `_is_model_file_valid(path)`: verifies file exists and minimum size.

Why: robust startup in cloud environments where direct Drive link behavior can vary.

### Block F: initialize_model()

Startup logic:

1. Deletes suspiciously small existing model file.
2. Downloads model if missing.
3. Validates downloaded file size.
4. Loads YOLO from path.
5. Forces CPU mode.
6. Calls `fuse()` to optimize inference graph.
7. Returns loaded model or `None` on failure.

Global model object:

- `model = initialize_model()`

Why: model is initialized once at process start, reducing per-request overhead.

### Block G: Inference constants

- `CONF_THRESHOLD = 0.30`
- `MAX_DET = 1`
- `FRAME_SKIP_MS = 80`

Why:

- threshold filters weak detections
- max_det simplifies one-sign prediction
- frame skip keeps CPU stable

### Block H: PredictionSmoother class

Methods:

- `push(label, conf)`:
  - append current prediction into fixed-size deque
  - compute dominant label by frequency
  - compute average confidence for dominant class
  - return stabilized `(label, confidence)`
- `reset()` clears history

Why: reduces flicker and improves UX sentence building.

### Block I: WebSocket endpoint `/ws`

Flow inside `websocket_endpoint(websocket)`:

1. `accept()` connection
2. if model unavailable:
   - send error JSON
   - close socket
3. initialize per-session state:
   - smoother
   - inference timing
   - frame count
4. loop forever:
   - receive text with timeout
   - on timeout -> send ping and continue
   - process protocol commands:
     - `__PING__` -> send pong
     - `__STOP__` -> reset smoother
   - apply frame throttle (`FRAME_SKIP_MS`)
   - decode Base64 frame
   - run YOLO in thread executor (keeps event loop responsive)
   - parse first box if exists
   - apply smoothing
   - send prediction JSON
5. handle disconnect and cleanup

Why run inference in executor:

- model.predict is CPU-bound
- keeps async websocket loop from freezing

### Block J: Health endpoint

- `@app.get("/health")`
- returns online/model info

Why: deployment health checks and quick diagnostics.

### Block K: Uvicorn entrypoint

- reads `PORT` env (Railway-compatible)
- runs `uvicorn app:app --host 0.0.0.0`

Why: same file works for local and cloud start.

## 5) WebSocket message behavior in detail

### Incoming message types

1. Frame payload: base64 image string
2. `__PING__`: client keepalive check
3. `__STOP__`: reset temporal smoothing window

### Outgoing message types

1. Prediction:

```json
{
  "type": "prediction",
  "label": "hello",
  "confidence": 0.87,
  "frame": 42
}
```

2. Keepalive:

```json
{"type": "ping"}
{"type": "pong"}
```

3. Error:

```json
{"type": "error", "message": "Model not available on server"}
```

## 6) requirements.txt explained

- `fastapi`, `uvicorn[standard]`: web server framework
- `numpy`, `opencv-python-headless`: image decoding/processing
- `torch`, `torchvision` CPU builds: inference backend
- `ultralytics>=8.3.0`: YOLO framework
- `gdown`: model fetch from Drive
- `python-multipart`: FastAPI form/multipart support

Special line:

- `--extra-index-url https://download.pytorch.org/whl/cpu`

This ensures CPU wheels for torch are installed reliably.

## 7) Dockerfile explained

1. Base image: `python:3.10-slim-bullseye`
2. Installs system libs required by OpenCV (`libgl1`, `libglib2.0-0`)
3. Sets workdir `/app`
4. Copies `requirements.txt` and installs dependencies
5. Copies full backend source
6. Exposes `8000`
7. Starts Uvicorn with Railway-compatible port fallback

## 8) railway.json explained

- Uses Dockerfile builder
- deploys single replica
- restart policy `ON_FAILURE` with retry budget

This is minimal but valid production config.

## 9) Backend reliability and safety features

- Corrupt model detection by file size
- Download fallback path (`gdown` -> `urllib`)
- Socket timeout keepalive
- Per-frame exception isolation (bad frame does not crash server)
- Graceful model-unavailable response
- CORS restriction support via environment variables

## 10) End-to-end backend code flow for exam answer

You can write this summary:

The backend starts FastAPI, configures CORS from environment variables, validates or downloads YOLO model weights, loads the model on CPU, and exposes two endpoints: `/health` and `/ws`. The Flutter client streams Base64 camera frames to `/ws`. Each frame is decoded with NumPy/OpenCV, inferred by YOLO, smoothed with a short history buffer, and returned as JSON label-confidence output. Additional protocol messages (`__PING__`, `__STOP__`) support connection health and session reset. The service is containerized with Docker and deploy-ready for Railway.

## 11) Suggested backend improvements

1. Add auth token check on WebSocket connections.
2. Move heavy inference to worker queue when scaling users.
3. Add structured metrics (latency, FPS, detection rate).
4. Add explicit model version endpoint.
5. Add request tracing IDs for debugging multi-user sessions.

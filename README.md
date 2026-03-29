# VANI

VANI is a cross-platform accessibility platform for Indian Sign Language (ISL).

It combines:
- a Flutter client app (Web, Android, iOS, Desktop targets)
- a FastAPI + YOLO inference backend over WebSocket

The system is designed for real-time sign-to-text assistance, two-way communication, emergency workflows, and multilingual UI support.

## Table of Contents

1. Overview
2. Core Features
3. Architecture
4. Repository Structure
5. Tech Stack
6. Prerequisites
7. Local Development Setup
8. Runtime Configuration
9. API Contract
10. Deployment Guide
11. Model Management
12. Localization
13. Emergency Module Details
14. Build and Release Commands
15. Troubleshooting
16. Current Status

## Overview

VANI focuses on practical communication support for Deaf and Hard-of-Hearing users in India.

Key runtime flow:
1. Flutter client captures camera frames.
2. Client sends frames (base64) through WebSocket to backend `/ws`.
3. Backend runs YOLO inference on each frame.
4. Backend returns prediction payloads with label + confidence.
5. Client displays real-time results and builds usable sentence output.

## Core Features

- Real-time ISL sign recognition and sentence support
- Two-way communication screen for Deaf/hearing interaction
- Emergency SOS workflow with:
  - local emergency contacts (Hive)
  - optional location embedding
  - mobile shake trigger
  - SMS launch via `url_launcher`
- ISL signs reference screen
- Detailed objective pages (Accessibility, Bridging, Inclusivity, Privacy, Offline, Education)
- Language switching (English, Hindi, Marathi)
- Light/dark theming

## Architecture

### Client (Flutter)

- Main app entry: `lib/main.dart`
- Primary screens:
  - `lib/screens/TranslateScreen.dart`
  - `lib/screens/TwoWayScreen.dart`
  - `lib/screens/EmergencyScreen.dart`
  - `lib/screens/EmergencySetupScreen.dart`
  - `lib/screens/Signspage.dart`
  - `lib/screens/HomeScreen.dart`
- Localization source: `lib/l10n/AppLocalizations.dart`
- Emergency services:
  - `lib/services/EmergencyService.dart`
  - `lib/services/LocationService.dart`

### Backend (FastAPI + YOLO)

- Backend entry: `isl_backend/app.py`
- Health endpoint: `GET /health`
- Inference socket: `WS /ws`
- Model path: `isl_backend/model/isl_best.pt`

### Production Transport

- Client uses secure WebSocket (`wss://`) to Railway host.
- Current host is hardcoded in:
  - `lib/screens/TranslateScreen.dart`
  - `lib/screens/TwoWayScreen.dart`

## Repository Structure

```text
vani/
  lib/
    components/
    l10n/
    models/
    screens/
      objectives/
    services/
    utils/
    main.dart
  isl_backend/
    app.py
    Dockerfile
    railway.json
    requirements.txt
    model/
      isl_best.pt
  android/
  ios/
  web/
  windows/
  linux/
  macos/
  pubspec.yaml
  README.md
```

## Tech Stack

### Flutter Client

- Flutter SDK (Dart 3.11)
- `camera`
- `web_socket_channel`
- `http`
- `flutter_tts`
- `hive` + `hive_flutter`
- `geolocator`
- `url_launcher`
- `shake`
- `vibration`
- `speech_to_text`

### Backend

- Python 3.10
- FastAPI
- Uvicorn
- Ultralytics YOLO
- PyTorch CPU
- OpenCV (headless)
- gdown

## Prerequisites

Install before setup:

- Flutter SDK (stable channel)
- Python 3.10+
- Git
- Git LFS (recommended for large model file workflows)

Quick checks:

```powershell
flutter --version
python --version
git --version
git lfs version
```

## Local Development Setup

## 1) Clone Repository

```powershell
git clone https://github.com/VisheshKamble/ISL.git
cd ISL
```

## 2) Model Artifact (Choose One)

Option A: Pull model via Git LFS (recommended)

```powershell
git lfs install
git lfs pull
```

Option B: Let backend auto-download model from Google Drive

- If `isl_backend/model/isl_best.pt` is missing, backend downloads it at startup.

## 3) Start Backend

```powershell
cd isl_backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python app.py
```

Backend defaults:
- host: `0.0.0.0`
- port: `8000` (or `PORT` env variable if present)

## 4) Start Flutter Client

Open a second terminal at repo root:

```powershell
cd ..
flutter pub get
flutter run -d chrome
```

Examples:

```powershell
flutter run -d emulator-5554
flutter run -d windows
```

## Runtime Configuration

Current production socket host is hardcoded:

- `lib/screens/TranslateScreen.dart`
- `lib/screens/TwoWayScreen.dart`

Current value:
- `isl-production-57d4.up.railway.app`

To switch environments, update `_kRailwayHost` in both files.

## API Contract

## `GET /health`

Response shape:

```json
{
  "status": "online",
  "model_loaded": true,
  "engine": "YOLOv11-CPU"
}
```

## `WS /ws`

Input messages:
- base64 image frame string (optionally with `data:image/...;base64,` prefix)
- control messages:
  - `__PING__`
  - `__STOP__`

Output messages:

Prediction:

```json
{
  "type": "prediction",
  "label": "hello",
  "confidence": 0.92,
  "frame": 118
}
```

Protocol keepalive:

```json
{"type": "ping"}
{"type": "pong"}
```

Error example:

```json
{"type": "error", "message": "Model not available on server"}
```

## Deployment Guide

## Backend Deployment (Railway)

Backend already includes:
- `isl_backend/Dockerfile`
- `isl_backend/railway.json`

Docker startup command:

```bash
uvicorn app:app --host 0.0.0.0 --port ${PORT:-8000}
```

Recommended Railway settings:
- Root directory: `isl_backend`
- Builder: Dockerfile
- Health check path: `/health`
- Restart on failure: enabled

Post-deploy checks:
1. Open `https://<your-domain>/health`
2. Confirm `model_loaded` is true
3. Validate WebSocket from app (`wss://<your-domain>/ws`)

## Frontend Deployment (Flutter Web)

Build web bundle:

```powershell
flutter build web --release
```

Output:
- `build/web/`

Deploy `build/web/` to your static hosting target (Netlify, Vercel, Firebase Hosting, Cloudflare Pages, S3+CDN, etc.).

Important:
- Keep backend on HTTPS and WebSocket on WSS for browser compatibility.

## Model Management

Primary model file:
- `isl_backend/model/isl_best.pt`

Current size in repository:
- 121,378,638 bytes (about 121 MB)

Notes:
- For GitHub, large model files should be tracked with Git LFS.
- Backend includes fallback auto-download via `gdown` when model is missing.

## Localization

Localization class:
- `lib/l10n/AppLocalizations.dart`

Supported locales:
- `en`
- `hi`
- `mr`

Behavior:
- `t(key)` first checks active locale.
- Falls back to English.
- Asserts in debug if key is missing in all locales.

## Emergency Module Details

Storage:
- Hive box: `emergency_contacts`
- Max contacts: 5

Platform behavior:
- Shake trigger: mobile only
- SMS send path: mobile only
- GPS: mobile + web

Main emergency files:
- `lib/services/EmergencyService.dart`
- `lib/services/LocationService.dart`
- `lib/models/EmergencyContact.dart`

## Build and Release Commands

## Flutter

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

Release builds:

```powershell
flutter build web --release
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
```

## Backend

```powershell
cd isl_backend
pip install -r requirements.txt
python app.py
```

Container build (optional local test):

```powershell
cd isl_backend
docker build -t vani-backend .
docker run -p 8000:8000 vani-backend
```

## Troubleshooting

### 1) WebSocket connection fails

- Verify backend is running and reachable.
- Confirm client host in `_kRailwayHost` is correct in both screen files.
- Ensure endpoint is WSS in production.
- Check browser console/network for blocked mixed-content errors.

### 2) Backend starts but model is unavailable

- Confirm `isl_backend/model/isl_best.pt` exists.
- If missing, allow startup download via `gdown`.
- Verify outbound internet access on deployment runtime.

### 3) Slow inference or dropped frames

- Backend currently runs CPU inference.
- Scale instance size or optimize model variant for production load.
- Tune frame interval in client (`_kFrameIntervalMs`).

### 4) SOS does not send messages

- On desktop/web, direct SMS sending is not supported.
- On mobile, ensure contacts are configured and permissions granted.

### 5) Localization crashes in debug

- Missing keys trigger assertion in debug builds.
- Add missing key to active locale and English fallback map.

## Current Status

- Deployment architecture in place (Railway backend + Flutter web/mobile clients).
- WebSocket production host wired in both live translation screens.
- Large model artifact integrated and tracked in repository workflow.
- Objective pages updated to use valid localization keys.

---

If you want, the next upgrade can be centralizing backend host config into one shared environment/config file so you update it once for all screens.

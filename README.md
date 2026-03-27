# VANI

VANI is a Flutter accessibility platform for Indian Sign Language (ISL), built for both:

- Mobile app (Android, iOS)
- Web app (browser-based experience)

It combines real-time sign-to-text inference, emergency workflows, and multilingual UX.

## What VANI Includes

- Real-time ISL translation
- Two-way communication bridge
- Emergency SOS with contacts + location context
- ISL signs reference library
- Runtime language + theme switching

## App + Web Architecture

Current system has two major runtime parts:

1. Flutter client (single codebase, multiple targets)
2. Python inference backend (FastAPI + YOLO over WebSocket)

Both the mobile app and web app use the same inference protocol (`/ws`) and prediction payload shape.

## Current Runtime Flow

1. Client captures camera frames.
2. Frames are sent to backend over WebSocket as base64 payloads.
3. Backend performs YOLO inference.
4. Backend sends `{type,label,confidence,frame}` prediction payloads.
5. Client renders label stream and builds sentence output.

## Future Deployment Plan (Akamai Cloud)

You can move inference to Akamai while keeping one shared API contract for both app and web clients.

### Target Topology

- `vani-web`: static web hosting (Flutter web build)
- `vani-api`: FastAPI service behind HTTPS/WSS
- `vani-ml`: inference worker(s) with model artifact
- Managed edge/WAF/rate limiting in front of API

### Inference Strategy for Both Clients

- Mobile app and web app call the same secured endpoint (`wss://<domain>/ws`)
- Keep response schema unchanged to avoid client-specific divergence
- Version inference contract (`v1`, `v2`) before introducing schema changes

### Recommended Evolution

- Stage 1: containerize current `isl_backend`
- Stage 2: add env-based runtime config (host, ws URL, model path)
- Stage 3: add authentication and rate limiting for `/ws`
- Stage 4: add autoscaling + health-based rollout
- Stage 5: optional split between API gateway and dedicated model workers

## Repository Structure

```text
vani/
  lib/
    components/
    l10n/
    models/
    screens/
    services/
    main.dart
  isl_backend/
    app.py
    requirements.txt
    model/
      best .pt
  android/
  ios/
  linux/
  macos/
  web/
  windows/
  pubspec.yaml
```

## Core Modules

### Real-time Translation

- Client screen: `lib/screens/TranslateScreen.dart`
- Backend service: `isl_backend/app.py`

### Two-way Communication

- `lib/screens/TwoWayScreen.dart`

### Emergency SOS

- `lib/screens/EmergencyScreen.dart`
- `lib/screens/EmergencySetupScreen.dart`
- `lib/services/EmergencyService.dart`
- `lib/services/LocationService.dart`

### Signs Library

- `lib/screens/Signspage.dart`

## Local Development Setup

### Prerequisites

- Flutter SDK (stable)
- Python 3.10+ (3.11 recommended)
- Git LFS (for model files)

```powershell
flutter --version
python --version
git lfs version
```

### 1) Pull model artifacts

```powershell
git lfs install
git lfs pull
```

### 2) Start backend

```powershell
cd isl_backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python app.py
```

Default backend endpoints:

- Health: `http://127.0.0.1:8000/health`
- WebSocket: `ws://127.0.0.1:8000/ws`

### 3) Start Flutter client

From repository root:

```powershell
flutter pub get
flutter run -d chrome
```

Android emulator example:

```powershell
flutter run -d emulator-5554
```

## WebSocket Behavior by Platform (Current)

- Web: uses current browser host + port 8000
- Android emulator: uses `10.0.2.2:8000`
- Desktop: uses `127.0.0.1:8000`

## API Contract (Current)

### `GET /health`

Returns service status and loaded model path.

### `WS /ws`

Input:

- base64 frame payloads
- control messages: `__PING__`, `__STOP__`

Output:

- prediction messages
- ping/pong keepalive
- error messages when decode/inference fails

## Emergency Module Notes

- Contacts stored in Hive box: `emergency_contacts`
- Up to 5 contacts
- Shake-triggered SOS on supported mobile platforms
- Location added when available

## Localization

Supported locales:

- `en`
- `hi`
- `mr`

## Build/Codegen Notes

If Hive model definitions change:

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

### Web cannot connect to backend

- Ensure backend is running on port 8000
- Ensure firewall allows traffic
- Verify browser host can resolve backend host

### Emulator cannot connect

- Use `10.0.2.2` for Android emulator localhost mapping

### Large model push fails

- Ensure model artifacts are tracked with Git LFS

## Entry Points

- Flutter app: `lib/main.dart`
- Backend app: `isl_backend/app.py`

## Vision

VANI is designed as a shared accessibility platform where a single inference backbone powers both web and mobile experiences at production scale.

# VANI

VANI is a Flutter-based accessibility app focused on Indian Sign Language (ISL) communication. It combines a real-time sign recognition backend with multiple user-facing experiences:

- Real-time sign-to-text translation
- Two-way communication bridge between deaf/mute and hearing users
- Emergency SOS workflows with location-aware alerts
- ISL signs library
- Multilingual interface (English, Hindi, Marathi)

The project includes:

- A Flutter frontend in this repository root
- A Python FastAPI + YOLO backend in the folder isl_backend

## Core Features

### 1) Real-time ISL Translation

- Camera feed is captured in Flutter
- Frames are sent over WebSocket to backend
- Backend runs YOLO inference on each frame
- Predictions are returned and shown live in UI
- SentenceBuilder logic helps convert gesture streams into natural text

Main files:

- lib/screens/TranslateScreen.dart
- isl_backend/app.py

### 2) Two-way Communication Screen

- Deaf/mute side signs to camera
- Hearing side can type responses
- Shared conversation thread for both sides
- Quick phrases support for hearing user

Main file:

- lib/screens/TwoWayScreen.dart

### 3) Emergency SOS Module

- Configurable emergency contacts stored locally with Hive
- Multi-scenario SOS categories (medical, police, fire, etc.)
- Mobile shake detection to trigger emergency help
- Location embedding in outgoing SOS message
- Platform-aware sending strategy (mobile/web/desktop)

Main files:

- lib/screens/EmergencyScreen.dart
- lib/screens/EmergencySetupScreen.dart
- lib/services/EmergencyService.dart
- lib/services/LocationService.dart

### 4) ISL Signs Library

- Searchable and filterable signs catalog
- Includes alphabet, numbers, and common words
- Uses localization keys for multilingual labels and descriptions

Main file:

- lib/screens/Signspage.dart

### 5) Localization and Theme

- Locales: English (en), Hindi (hi), Marathi (mr)
- Runtime language switching from navbar
- Dark and light themes

Main files:

- lib/l10n/AppLocalizations.dart
- lib/components/GlobalNavbar.dart

## Tech Stack

### Frontend

- Flutter (Dart)
- Camera package for live camera frames
- WebSocket channel for backend communication
- Hive for local persistent emergency contacts
- Geolocator, url_launcher, vibration, shake, flutter_tts

### Backend

- FastAPI
- Uvicorn
- Ultralytics YOLO
- OpenCV
- NumPy

## Project Structure

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

## Prerequisites

Install the following:

- Flutter SDK (recommended stable channel)
- Dart SDK (included with Flutter)
- Python 3.10 or 3.11
- Git LFS (required for model files)

Verify tools:

```powershell
flutter --version
python --version
git lfs version
```

## Setup

### 1) Clone and prepare model files

If using a fresh clone, ensure LFS files are pulled:

```powershell
git lfs install
git lfs pull
```

### 2) Backend setup (FastAPI + YOLO)

From repository root:

```powershell
cd isl_backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python app.py
```

Backend default URL:

- HTTP health: http://127.0.0.1:8000/health
- WebSocket: ws://127.0.0.1:8000/ws

Important:

- The backend currently expects model path: isl_backend/model/best .pt
- Keep the exact filename as used in app.py unless you also update MODEL_PATH

### 3) Flutter setup

Open a new terminal at repository root:

```powershell
flutter pub get
flutter run -d chrome
```

For Android emulator:

```powershell
flutter run -d emulator-5554
```

## Running the Full System

Run both services together:

1. Start backend in isl_backend folder
2. Start Flutter app from repository root
3. Open Translate or Bridge screen
4. Confirm backend connection indicator is live

WebSocket host behavior in Flutter:

- Web: uses current host with port 8000
- Android emulator: uses 10.0.2.2:8000
- Desktop: uses 127.0.0.1:8000

## Backend API Summary

### GET /health

Returns backend status and model path.

### WebSocket /ws

Input:

- Base64-encoded image frames (text payload)
- Control messages: __PING__, __STOP__

Output:

- Prediction payload with label and confidence
- Keepalive and error payloads when applicable

Backend behavior highlights:

- CPU inference mode
- Temporal smoothing via prediction window
- Frame throttling for stability
- Decode/inference error handling with limits

## Emergency Module Notes

- Contacts are stored in Hive box emergency_contacts
- Max 5 contacts are allowed
- Phone numbers are normalized with India-centric defaults
- Mobile supports shake-triggered SOS for quick help
- Message payload includes location when available

## Localization

Supported locales are configured in AppLocalizations:

- en
- hi
- mr

Navbar language switch updates app locale at runtime.

## Development Notes

- Hive model adapter file is generated (EmergencyContact.g.dart)
- If you modify Hive models, run code generation:

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

- Lint rules are configured via analysis_options.yaml

## Troubleshooting

### Backend not connecting from Flutter web

- Ensure backend is running on port 8000
- Use same host in browser and backend machine
- Confirm firewall allows local traffic

### Android emulator cannot reach backend

- Use 10.0.2.2 for localhost mapping (already implemented)

### Push rejected due to model size

- Ensure Git LFS is installed
- Track model files with git lfs track "*.pt"
- Re-add large model files so they are committed as LFS pointers

### Camera or permissions issues

- Test on supported browser/device
- Verify camera permissions are granted
- On mobile, ensure platform permissions are set

## Current Entry Points

- Frontend app start: lib/main.dart
- Backend app start: isl_backend/app.py

## Acknowledgement

VANI is designed to reduce communication barriers and improve emergency accessibility for deaf and mute communities through practical, real-time tooling.

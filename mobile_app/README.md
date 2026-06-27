## Campus Hazard Mobile App

Phase 1 Flutter app for the campus hazard detection project.

### Current features

- Pick an image from the phone gallery
- Upload it to the Spring Boot backend
- Show final hazard, confidence, severity, recommendation, and raw detections
- Keep the backend base URL editable for emulator vs physical device testing

### Backend endpoint

The app calls:

`POST /api/hazard/detect`

Example base URLs:

- Android emulator: `http://10.0.2.2:8080`
- Local desktop Flutter run: `http://localhost:8080`
- Physical phone: `http://YOUR_COMPUTER_IP:8080`

### Run

```powershell
cd mobile_app
flutter pub get
flutter run
```

Start the YOLO service and Spring Boot backend first.

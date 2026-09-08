# IST Trainer Evaluation — Mobile (Flutter)

Android client for the IST Trainer Evaluation System. This app has nothing to talk to on its own —
it's the frontend half of a backend/mobile pair; see the
[backend repo's README](https://github.com/Sylvr3k/Android-Back-End-Laravel#readme) for the full
architecture writeup and the **Quick start** section covering how to bring both apps up together
in sync.

## Requirements

- Flutter 3.47+ (stable channel), Dart 3.13+
- Android Studio / Android SDK (emulator or physical device)
- A running instance of the [backend](https://github.com/Sylvr3k/Android-Back-End-Laravel) — start
  that first

## Setup

```bash
flutter pub get
```

## Run

Point `API_BASE_URL` at wherever the backend is running (this is what keeps the two apps in sync):

```bash
# Android emulator, backend running on the host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Physical device on the same LAN — replace with your machine's actual LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
```

A physical device's LAN IP needs adding to
`android/app/src/debug/res/xml/network_security_config_debug.xml` (debug builds only) to permit
cleartext HTTP for local testing.

## Tests

```bash
flutter analyze
flutter test
```

## Build

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://evaluations.ist.ac.ke/api/v1
```

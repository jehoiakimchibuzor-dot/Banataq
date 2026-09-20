# Banataq — Ask. Learn. Create.

Premium AI workspace for Nigerian students and professionals. Flutter + Firebase. Tagline: “Ask. Learn. Create.”

## Current Release

- **Version:** `1.0.0+2` (`versionName 1.0.0`, `versionCode 2`) — first release candidate (RC1). Previous `1.0.0+1` was the initial backup (82009e3) with no Play Store submission.
- **Why `+2`:** `+1` was the pre-PR#1 backup. `+2` is the next build number for the first RC that includes Phase 1–3F (Firestore, Storage, Briefing, Timeline, Files). No `versionName` bump to `1.0.1` yet — `1.0.0` remains the marketing version until first Play Store submission; `+2` tracks the binary.

## Tech Stack

- Flutter 3.44.1 / Dart 3.12.1, `flutter_bloc` 9.1.1, `get_it`, `firebase_core`/`auth`/`firestore`/`storage`, `flutter_secure_storage`
- `firebase.json` wires `firestore.rules` + `storage.rules` + `emulators` (firestore 8080, storage 9199)

## Quick Start

```bash
flutter pub get
# Dev keys via --dart-define (never committed)
flutter run --no-pub -d 8323d3330508 \
  --dart-define=GEMINI_KEY=... --dart-define=GROQ_KEY=... --dart-define=OPENROUTER_KEY=...

# Tests + rules
flutter test --no-pub
dart analyze lib && dart analyze test
npm ci && firebase emulators:exec --only firestore,storage "npx mocha firestore.rules.test.js storage.rules.test.js --timeout 20000"

# Release (requires android/key.properties + SHA-1 in Firebase Console — see docs/)
flutter build appbundle --release
```

## Docs

- `docs/RELEASE_CHECKLIST.md` — release gate (version, signing, SHA-1, rules deploy, CI, secrets, proxy)
- `docs/GOOGLE_AUTH_SETUP.md` — SHA-1 (debug `03:D4:08...` + Play App Signing) → `google-services.json` `client_type:1`
- `docs/SECRET_AUDIT.md` — `String.fromEnvironment` + `SecureKeyStore` migration
- `docs/intelligence_layer.md` — offline-first LLM/RAG/memory/tools


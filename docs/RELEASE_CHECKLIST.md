# Banataq Release Checklist — RC1 (1.0.0+2)

**Current origin/main:** `b1be163` (chore: harden release pipeline). Worktree clean. Next RC is `1.0.0+2` (`versionName 1.0.0`, `versionCode 2`). Verified `pubspec.yaml:4` is `1.0.0+2`.

> Do not mark a release as production-ready until every blocker is completed or explicitly acknowledged as unresolved.

## Version
- [ ] `pubspec.yaml:4` is `1.0.0+2` (bumped from `1.0.0+1` backup; `+2` = first RC with Phase1–3F). `README.md:12` documents why `+2` not `1.0.1`.
- [ ] `android/app/build.gradle.kts:25-28` `versionCode = flutter.versionCode` / `versionName = flutter.versionName` will read `+2`.
- [ ] `CHANGELOG.md` (if exists) updated — currently no changelog, acceptable for RC1.

## Signing
- [ ] `android/key.properties.example` exists (committed) — template with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
- [ ] `android/key.properties` **NOT** committed (`gitignored:62`), real file created locally from example.
- [ ] `android/app/upload-keystore.jks` **NOT** committed (`gitignored:63`, `*.jks`), real file at `storeFile` path.
- [ ] `android/app/build.gradle.kts:31-48` release `signingConfig` now **fails fast** with `GradleException: Missing android/key.properties` instead of silently using `debug`. No `debug` fallback.
- [ ] Local: `flutter build appbundle --release` succeeds only when `key.properties` + `upload-keystore.jks` present; otherwise fails with clear message (expected, not a code defect).
- [ ] CI: `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` secrets injected → `echo "$KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks` + `key.properties` created (see `ci.yaml:41-55`).

## Debug / Release SHA-1
- [x] Debug SHA-1 derived: `03:D4:08:24:6B:F7:9D:0F:1B:6D:E0:57:9D:09:C9:70:68:D2:56:14` (`keytool -list -v -keystore ~/.android/debug.keystore`).
- [x] Debug SHA-256 derived: `AD:D4:57:44:A1:8C:94:F1:63:01:1C:C2:0E:93:D4:13:A9:D1:90:0D:E9:B8:63:F4:10:AB:31:B2:C5:33:5D:54`.
- [ ] **MANUAL (Firebase Console):** Project `banataq-80a9b` → Project Settings → Android `com.banataq.banataq` → Add SHA certificate fingerprints → paste debug SHA-1 (and SHA-256) → Save.
- [ ] **MANUAL (Play App Signing):** After creating upload keystore (`android/key.properties` + `upload-keystore.jks`), copy its SHA-1 (`keytool -list -v -keystore upload-keystore.jks`) **and** if using Play App Signing, copy Play Console → Setup → App signing → App signing key certificate SHA-1. Add **both** as separate fingerprints in Firebase Console → Save.

## Google Sign-In
- [ ] After SHA-1 added, download new `android/app/google-services.json` (Project Settings → General → Download).
- [ ] Verify file now contains **two** `oauth_client` entries: `client_type:1` (Android, `certificate_hash: 03d4...`) + `client_type:3` (Web). Check: `Select-String -Path android/app/google-services.json -Pattern "client_type.*1"`.
- [ ] Rebuild warm: `flutter build apk --debug --no-pub` (no `flutter clean`), if hangs: `taskkill /F /IM java.exe` → `Remove-Item -Recurse -Force "$env:LOCALAPPDATA\kotlin"` + `C:\flutter\packages\flutter_tools\gradle\build` → `gradlew --stop` (see `docs/GOOGLE_AUTH_SETUP.md:72`).
- [ ] Test on device `8323d3330508`: `flutter run --no-pub -d 8323d3330508` → tap Google Sign-In → account chooser appears, not `ApiException:10 DEVELOPER_ERROR`.
- Current `google-services.json:15` only `client_type:3` → **BLOCKER until manual SHA-1 step done**.

## Firestore Deployment
- [ ] `firebase.json:1` wires `firestore.rules` (and `storage.rules` + `emulators:8080/9199`).
- [ ] Manual or CI: `firebase deploy --only firestore:rules --project banataq-80a9b` (requires Owner `firebase.rules.admin` via `FIREBASE_TOKEN` or `GOOGLE_APPLICATION_CREDENTIALS` (`firebase login:ci`)). Do **not** commit `service-account.json` (gitignored `*.json`).
- [ ] Verify in Console → Firestore → Rules → published `rules_version='2'` + `match /users/{uid}/workspaces/{workspaceId}/{document=**} allow if auth.uid==uid`.

## Storage Deployment
- [ ] `storage.rules:1-45` `rules_version='2'` owner `users/{uid}/workspaces/.../files/{fid}/{fileName}` `size <=50*1024*1024` on `create/update`, owner `read/delete`, `chats` owner, `avatars` public read.
- [ ] `firebase.json:1` wires `storage.rules`.
- [ ] Manual or CI: `firebase deploy --only storage --project banataq-80a9b` (same auth as above).

## CI Tests
- [ ] `flutter analyze` → 0 issues (`dart analyze lib` + `dart analyze test` with `--fatal-infos --fatal-warnings`).
- [ ] `flutter test --no-pub` → 296/296 (`pr3f` 33, `briefing` 25, `timeline` 25, etc.).
- [ ] `npm ci` → installs `@firebase/rules-unit-testing`, `firebase-admin`, `mocha` from `package.json:26` (no `node_modules` committed, `.gitignore:37`).
- [ ] `firebase emulators:exec --only firestore "npx mocha firestore.rules.test.js --timeout 20000"` → owner allowed, stranger/anon denied.
- [ ] `firebase emulators:exec --only storage "npx mocha storage.rules.test.js --timeout 20000"` → **9/9** `A owner CRUD, B cross-user, C unauth, D size, E workspace isolation, F default deny, G chat/avatar` (also `npm run test:rules` combines both).
- [ ] CI `ci.yaml:1` runs all above + fails if any.

## Security Tests
- [ ] Firestore emulator `firestore.rules.test.js:1` `banataq-80a9b` seed `users/user-owner/workspaces/ws-1` (owner vs stranger vs anon).
- [ ] Storage emulator `storage.rules.test.js:1` `demo-test` 9 tests above.

## Release Build
- [ ] `flutter build appbundle --release` (no `flutter clean`) → `build/app/outputs/bundle/release/app-release.aab` (unsigned if no `key.properties`, signed if present). CI `ci.yaml:60-80` runs `flutter build appbundle --release --verbose` with `isMinifyEnabled false` (no R8), uploads AAB artifact + `build.log`.
- [ ] If missing `android/key.properties` → build **fails** with `GradleException: Missing android/key.properties` (expected, not a code defect) → provide CI secrets (`KEYSTORE_BASE64` etc.) per `key.properties.example`.

## APK/AAB Artifact
- [ ] Debug `build/app/outputs/flutter-apk/app-debug.apk` (warm `flutter build apk --debug --no-pub`) for device QA `8323d3330508`.
- [ ] Release `build/app/outputs/bundle/release/app-release.aab` for Play Internal Track.

## Secrets Audit
- [ ] `app_keys.dart:4` `String.fromEnvironment(defaultValue:'')` — no embedded `GEMINI_KEY` etc., `proxyUrl` via `--dart-define`, BYOK via `SecureKeyStore` (`secure_key_store.dart:1`), `StorageService` migration verified `pr1_secure_storage_test:103`.
- [ ] `google-services.json` `api_key` public (ok), `android/key.properties`/`*.jks` gitignored, `functions/.env` gitignored, `serviceAccountKey` gitignored, `.env` gitignored, `node_modules` gitignored, `build/` gitignored.
- [ ] No `gsk_`, `sk-or`, `AQ.` in `git log --all -p` beyond test fixtures (`pr1:106` `gsk_test123`).
- [ ] `functions/index.js:5` secrets via `runWith({secrets:[...]})` Secret Manager, not in repo.

## Proxy Security
- [ ] `functions/index.js:1-35` now `admin.initializeApp()` + `verifyIdToken` on `Authorization: Bearer` before routing to `GEMINI_KEY`/`GROQ_KEY`/`OPENROUTER_KEY`/`OPENAI_KEY`. `chat` and `chatStream` both `401` if missing/invalid. `cors({origin:true})` remains but gated.
- [ ] `lib/services/chat_proxy.dart:10` `_authHeaders()` sends `FirebaseAuth.instance.currentUser.getIdToken()` as `Authorization: Bearer` when `AppKeys.useProxy` (when `PROXY_URL` set). Direct BYOK path unchanged.
- [ ] **Status after fix:** `PROXY SECURITY: PASS` (was `BLOCKED` due to unauth `cors` + no `verifyIdToken`).

## Manual Firebase Actions (Owner)
1. Add debug SHA-1 (and SHA-256) in Firebase Console → Download `google-services.json` → verify `client_type:1`.
2. Create upload keystore (`keytool -genkey ...`), add its SHA-1 (+ Play App Signing SHA-1 if using Play Signing) as additional fingerprints → re-download `google-services.json`.
3. `firebase deploy --only firestore:rules --only storage` with `FIREBASE_TOKEN` (from `firebase login:ci`) or service account.

## Final Release Approval Gate
- [ ] All above manual SHA-1 steps done (debug + release).
- [ ] `google-services.json` contains `client_type:1`.
- [ ] `android/key.properties` + `upload-keystore.jks` present locally (not committed) and CI secrets (`KEYSTORE_BASE64` etc.) configured.
- [ ] `firebase deploy` for `firestore.rules` + `storage.rules` verified in Console.
- [ ] CI `validate` job green (analyze + 296 tests + 9+4 rules tests).
- [ ] `flutter build appbundle --release` succeeds and AAB uploaded.
- [ ] `docs/SECRET_AUDIT.md` + `docs/GOOGLE_AUTH_SETUP.md` reviewed, no secrets in APK via `String.fromEnvironment`.
- [ ] Owner approves **BUILD** → push to `main` → Internal Track.

> **Current blockers until manual steps:** `google-services.json` `client_type:1` missing, `android/key.properties` missing locally/CI, `firebase deploy` not yet run from authorized environment.

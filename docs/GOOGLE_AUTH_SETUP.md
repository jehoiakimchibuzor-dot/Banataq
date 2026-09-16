# Banataq — Google Sign-In Setup (Phase 1 P1)

**Problem (2026-09-16):** `android/app/google-services.json` contains only `client_type: 3` (Web OAuth). Android Google Sign-In requires `client_type: 1` (Android OAuth) bound to the app's SHA-1 certificate fingerprint. Without it, `google_sign_in` returns `ApiException: 10` / `DEVELOPER_ERROR` on device `8323d3330508`.

## Required manual action (Firebase Console — one-time)

Firebase Console does not allow SHA-1 to be added via CLI/terraform without service-account trust; the owner must do this once in the UI. Takes ~2 minutes.

1. Open **Firebase Console** → project **banataq-80a9b** → **Project Settings** (gear) → **General** tab.
2. Scroll to **Your apps** → **Android** `com.banataq.banataq` (`1:703260191557:android:35b3fbc38d8ce09de82c2c`).
3. Under **SHA certificate fingerprints** click **Add fingerprint**.
4. Paste the **debug SHA-1** (this workstation):

   ```
   03:D4:08:24:6B:F7:9D:0F:1B:6D:E0:57:9D:09:C9:70:68:D2:56:14
   ```

   Optional but recommended — also add **SHA-256**:

   ```
   AD:D4:57:44:A1:8C:94:F1:63:01:1C:C2:0E:93:D4:13:A9:D1:90:0D:E9:B8:63:F4:10:AB:31:B2:C5:33:5D:54
   ```

5. For **release / Play Store** builds, repeat with the release keystore / Play App Signing SHA-1 (generated when you create `android/key.properties` + `upload-keystore.jks`). If you use Play App Signing, copy the SHA-1 from **Play Console → Setup → App signing**.
6. Click **Save**. Firebase regenerates the OAuth clients (takes ~30s).
7. Back in **Project Settings → General**, click **Download google-services.json** (or `firebase apps:sdkconfig android`).
8. Replace `android/app/google-services.json` in this repo with the downloaded file.
9. Verify the new file now contains **two** oauth_client entries:

   ```json
   "oauth_client": [
     { "client_id": "....apps.googleusercontent.com", "client_type": 1, "certificate_hash": "03d408..." },
     { "client_id": "....apps.googleusercontent.com", "client_type": 3 }
   ]
   ```

   - `client_type: 1` = Android OAuth (SHA-1 bound) ← **required**
   - `client_type: 3` = Web OAuth (existing) — used for `serverClientId` flows

10. Rebuild: see [Build](#warm-build) below. No `flutter clean` needed.

## How to re-derive SHA-1 on this machine

```powershell
# Debug keystore (Android Studio default)
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android -keypass android | Select-String SHA1

# Or via Gradle (slower, uses Kotlin daemon)
cd android; .\gradlew signingReport --no-daemon
```

Expected output for debug:

```
SHA1: 03:D4:08:24:6B:F7:9D:0F:1B:6D:E0:57:9D:09:C9:70:68:D2:56:14
SHA-256: AD:D4:57:44:A1:8C:94:F1:63:01:1C:C2:0E:93:D4:13:A9:D1:90:0D:E9:B8:63:F4:10:AB:31:B2:C5:33:5D:54
```

## Verification

```powershell
# 1. Check google-services.json has Android OAuth
Select-String -Path android/app/google-services.json -Pattern "client_type.*1"

# 2. On device, test Google Sign-In (requires wired SHA-1 to match APK signature):
flutter run --no-pub -d 8323d3330508
# Tap Sign in with Google → should show account chooser, not DEVELOPER_ERROR
```

## Warm build (no `flutter clean` — 6 GB re-download risk)

```powershell
flutter build apk --debug --no-pub
# If Gradle hangs at assembleDebug → Kotlin daemon lock:
taskkill /F /IM java.exe
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\kotlin" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\flutter\packages\flutter_tools\gradle\build" -ErrorAction SilentlyContinue
Set-Location android; .\gradlew --stop; Set-Location ..
flutter build apk --debug --no-pub
```

## Security note

`google-services.json` contains `api_key` and `mobilesdk_app_id` which are **not secret** per Firebase (they're embedded in the APK by design). The OAuth `client_id` values are public identifiers. No secret rotation needed for this file. The keys that *are* secret are `GEMINI_KEY` / `GROQ_KEY` etc. — those are passed via `--dart-define` and stored in `flutter_secure_storage`, never in `google-services.json`.

## Status

- [x] SHA-1 derived: `03:D4:08:24:6B:F7:9D:0F:1B:6D:E0:57:9D:09:C9:70:68:D2:56:14`
- [ ] SHA-1 added in Firebase Console (requires owner login)
- [ ] New `google-services.json` downloaded and committed (contains `client_type: 1`)
- [ ] Verified on device `8323d3330508`

# Banataq Temporary AI Gateway — Render Free

This is a **temporary** cloud-hosted replacement for `Firebase Functions /chat` during private testing.
It **mirrors** `functions/index.js` logic and will be deleted once `Firebase Functions` deployment is unblocked.

## Architecture

```
Banataq Android (ChatProxy) --HTTPS--> Render Express --Auth/AppCheck--> provider (Gemini/Groq/OpenRouter/OpenAI)
```

- `POST /chat` `{prompt,model,history}` → `{text}` or `{error,code}`
- `POST /chat/stream` SSE `data: <chunk>` `data: [DONE]`
- `GET /` → `Banataq AI gateway OK`

Auth: `Authorization: Bearer <Firebase ID token>` → `admin.auth().verifyIdToken`
AppCheck: `X-Firebase-AppCheck` → `admin.appCheck().verifyToken` (`REQUIRE_APP_CHECK=true` prod)

## Render Deployment (Owner)

1. **Render Dashboard > New Web Service > Connect GitHub banataq**
   - Root Directory: `render-gateway`
   - Build Command: `npm install`
   - Start Command: `node index.js`
   - Environment: `Node 20`
   - Health Check Path: `/`

2. **Environment > Secret File** `/etc/secrets/service-account.json`
   - Create Service Account `banataq-temp@banataq-80a9b.iam.gserviceaccount.com`
   - Roles: `roles/firebaseauth.viewer`, `roles/firebaseappcheck.tokenVerifier` (NOT Owner)
   - Download JSON → Add as Secret File at `/etc/secrets/service-account.json`

3. **Environment Variables (Secret)**
   - `GEMINI_KEY` = `aistudio.google.com` value
   - `GROQ_KEY` = `console.groq.com` `gsk_`
   - `OPENROUTER_KEY` = `openrouter.ai` `sk-or-`
   - `OPENAI_KEY` = `platform.openai.com` `sk-`
   - `REQUIRE_APP_CHECK` = `true` (prod)

   Add each via `Environment > Add Secret File` or `Environment Variable` (masked). Never commit.

4. Deploy → URL `https://banataq-temp.onrender.com`

## Flutter Build

No code change — only build flag:

```
flutter build apk --release --dart-define PROXY_URL=https://banataq-temp.onrender.com
flutter run --dart-define PROXY_URL=https://banataq-temp.onrender.com --no-pub -d 8323d3330508
```

`lib/core/constants/app_keys.dart:29` `String.fromEnvironment('PROXY_URL')` already reads it. `ChatProxy` handles `backend_unavailable` if empty.

## Migration to Firebase Functions

Change flag back:

```
--dart-define PROXY_URL=https://us-central1-banataq-80a9b.cloudfunctions.net
```

No agent rewrite. Delete Render service after `firebase deploy --only functions` succeeds.

## Security Notes

- Master keys never in `Flutter` `APK` `SecureStorage` — only `process.env.*` server.
- `BYOK` (`SecureKeyStore` `gsk_/sk-or-`) remains user-owned, separate.
- `firestore.rules` `aiUsage` `allow false` — gateway uses in-memory `30/min 3 concurrent` for private testing (resets on cold start, documented).
- Logs `hashUid` only, never secrets.

## Local Test

```
npm install --no-audit --no-fund
npm test
```

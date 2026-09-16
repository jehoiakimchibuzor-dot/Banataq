# Banataq — Secret & History Audit (Phase 1 P1)

Date: 2026-09-16
Branch: `main` @ `82009e3`
Auditor: Phase 1 Stabilization

## Summary — CLEAN

- **No embedded API keys in binary:** `lib/core/constants/app_keys.dart:4-32` uses `String.fromEnvironment(..., defaultValue: '')` — all four providers (`GEMINI_KEY`, `GROQ_KEY`, `OPENROUTER_KEY`, `OPENAI_KEY`) plus `PROXY_URL` are empty at compile unless passed via `--dart-define`. Verified: `defaultValue: ''` on every key.
- **No leaked keys in working tree:** `grep` across `lib/`, `android/`, `functions/`, `test/` found **zero** real keys. Only hits were:
  - `googleservices.json` `apiKey: AIzaSyCPMSaSRSCcCbfURT7FlC17zB1nkDMyV1E` — **not secret** (Firebase public identifier, embedded by design)
  - `assistant_service.dart:88,93,97` `startsWith('AIza')/('AQ.')/('gsk_')/('sk-or-')` — validation logic, not a key
  - `test/pr1_secure_storage_test.dart` `gsk_test123`, `gsk_legacy123` — test fixtures
- **No secrets in git history:** single commit `82009e3` on `main` is `String.fromEnvironment` clean. `git log --all -p -S "gsk_"` shows no prior commit ever contained a real Groq key. `git log --all -S "sk-"` likewise clean.
- **User BYOK is isolated:** `lib/services/storage_service.dart:100-235` migrated keys from `SharedPreferences` (`ai_config` only stores `provider` now) to `flutter_secure_storage` via `SecureKeyStore` (`lib/services/secure_key_store.dart:1-19`). Legacy `apiKey` field is purged after migration with verify-after-write.
- **`.gitignore` blocks secret carriers** (`# Secrets / credentials` block, lines 47-64): `.env`, `*.key`, `*.pem`, `*service-account*.json`, `*firebase-adminsdk*.json`, `serviceAccountKey.json`, `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `functions/.runtimeconfig.json`, `functions/.env`. Added `android/.kotlin/` (Kotlin daemon `salive` files) in this patch — those are build temp files, not secrets, but were showing as untracked noise.

## Current secret flow (post-PR #1)

```
Build:  flutter build apk --debug --no-pub \
          --dart-define=GEMINI_KEY=AQ.Ab8... \
          --dart-define=GROQ_KEY=gsk_iEJl... \
          --dart-define=OPENROUTER_KEY=sk-or-v1-96... \
          --dart-define=OPENAI_KEY=sk-proj-qS... \
          --dart-define=PROXY_URL=https://...cloudfunctions.net

Runtime: AssistantService.resolveKey() prefers user-saved key in SecureKeyStore,
         falls back to AppKeys embedded (dart-define), falls back to local model.
         StorageService.loadAiConfig() handles migration + verify.
```

Secrets **never touch** `SharedPreferences`, Firestore, or git. `proxyUrl` switches the app to `ChatProxy` when set (key hide deadline Fri 2026-09-11 met).

## If a key was ever committed (incident playbook)

This repo is currently clean, but if a rotation indicates a key *was* pushed before `82009e3` (e.g. on a deleted branch or force-pushed history), use `git filter-repo` (preferred over `filter-branch`/`BFG`) to purge and then rotate the key in the provider console.

```powershell
# 1. Install git-filter-repo (once)
pip install git-filter-repo  # or: winget install git-filter-repo

# 2. Clone a fresh mirror (do not run inside the working repo)
git clone --mirror https://github.com/jehoiakimchibuzor-dot/Banataq.git banataq-mirror.git
Set-Location banataq-mirror.git

# 3a. Purge a file that contained the secret (e.g. old lib/core/constants/app_keys.dart)
git filter-repo --path lib/core/constants/app_keys.dart --invert-paths --force

# 3b. Or replace a leaked string across all history (example: leaked Groq key)
#     Create replacements.txt with one line:  gsk_iEJl...==>REDACTED
" gsk_iEJlREDACTED==>REDACTED" | Set-Content replacements.txt
git filter-repo --replace-text replacements.txt --force

# 3c. Or strip any --dart-define value that was accidentally committed as a file
git filter-repo --path .env --invert-paths --force
git filter-repo --path functions/.env --invert-paths --force

# 4. Verify no secret remains
git log --all -p | Select-String "gsk_|sk-or-|AQ\.|AIza" | Select-Object -First 20

# 5. Force-push (DANGER: rewrites history — coordinate with collaborators)
git push --force --mirror origin

# 6. Locally, re-clone and rotate the leaked key in provider consoles:
#    https://aistudio.google.com/app/apikey, https://console.groq.com/keys, https://openrouter.ai/keys
#    Revoke old key → create new → update --dart-define and Functions Secret Manager.
#    Delete the mirror:  Remove-Item -Recurse -Force ..\banataq-mirror.git
```

**Do NOT use** `git filter-branch` — buggy and slow for this repo size.

## Verification commands (run from repo root)

```powershell
# No real keys in working tree
Get-ChildItem -Recurse -File -Include *.dart,*.json,*.env* | Select-String "sk-or-v1|gsk_iEJl|AQ\.Ab8|sk-proj-qS" | Should -BeNullOrEmpty

# app_keys.dart is clean
Select-String lib/core/constants/app_keys.dart "defaultValue: ''" | Measure-Object | Select-Object Count   # expect 5

# .gitignore blocks .env
Select-String .gitignore "\.env" | Should -Not -BeNullOrEmpty

# git history has no key
git -C . log --all -p -S "gsk_" | Should -BeNullOrEmpty

# storage_service no longer persists apiKey in prefs (only provider)
Select-String lib/services/storage_service.dart "apiKey" | Select-String "prefs.setString.*apiKey" | Should -BeNullOrEmpty
# The only prefs write is {"provider": provider.name} at line 220
```

## Action items

- [x] Verified `app_keys.dart` clean (5× `defaultValue: ''`)
- [x] Verified `storage_service.dart` migration purges `apiKey` from prefs
- [x] Verified `.gitignore` blocks `.env`/`*.jks`/service-account
- [x] Added `android/.kotlin/` to `.gitignore` (noise, not secret but untracked)
- [x] Scanned `git log --all -p` — no leaked strings
- [ ] If Firebase `google-services.json` was ever committed with a *service-account* key (not the public `apiKey`), run the `filter-repo` playbook above and rotate that service account in GCP IAM. The public `AIza...` in `google-services.json` is **not** a secret and does not need rotation.


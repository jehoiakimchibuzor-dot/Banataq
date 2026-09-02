# Phase 1 Implementation Plan (Approved)

## Scope
Only these four features. Nothing else.

```
Phase 1:
+-- Authentication (Google, Email, Apple-ready, Anonymous)
+-- User Profile (name, photo, country, language, persona)
+-- Cloud Sync (conversations, settings, memories, auto-sync)
+-- Settings (theme, provider, memory controls, privacy, export, delete)
```

## Explicitly Excluded from Phase 1
- Voice input/output
- Image upload / camera
- File upload (PDF, DOCX, etc.)
- Memory system (planned Phase 2)
- Student features (planned Phase 4)
- Business tools (planned Phase 6)
- AI marketplace (planned Phase 7)
- Agent mode (planned Phase 8)
- Banataq OS (planned Phase 9)

## Implementation Order

### Step 1: Project Setup (Day 1)
- [ ] Add Firebase dependencies to pubspec.yaml
- [ ] Configure google-services.json for Android
- [ ] Configure GoogleService-Info.plist for iOS
- [ ] Initialize Firebase in main.dart
- [ ] Set up Remote Config defaults
- [ ] Run `flutterfire configure`

### Step 2: Core Infrastructure (Day 1-2)
- [ ] Set up Isar local database
- [ ] Implement `AppResult<T>` and error classes
- [ ] Implement network connectivity service
- [ ] Set up BLoC infrastructure (base classes, observer)
- [ ] Create abstract repository interfaces in domain layer
- [ ] Create folder structure

### Step 3: Authentication (Day 2-4)
- [ ] Implement Firebase Auth service
- [ ] Implement Google Sign-In
- [ ] Implement Email/Password sign-up + sign-in
- [ ] Implement anonymous sign-in
- [ ] Set up Apple Sign-In architecture (proxy, implement later)
- [ ] Implement password reset flow
- [ ] Implement account linking
- [ ] Build auth BLoC (events: signInWithGoogle, signInWithEmail, signUp, signOut, resetPassword)
- [ ] Build Login screen (Google button, Email/Password form, Forgot Password link)
- [ ] Build Sign-up screen
- [ ] Build Forgot Password screen
- [ ] Build Account Linking UI (Settings > Account > Link Google)
- [ ] Auth state listener in main.dart

### Step 4: User Profile (Day 4-5)
- [ ] Create Firestore user document on first sign-in
- [ ] Implement profile repository (local + remote)
- [ ] Build profile BLoC
- [ ] Build profile screen (name, photo, country, language, persona)
- [ ] Implement avatar upload to Cloud Storage
- [ ] Profile editing with optimistic local update

### Step 5: Cloud Sync Engine (Day 5-8)
- [ ] Implement Firestore datasource for conversations
- [ ] Implement Firestore datasource for settings
- [ ] Implement Isar local datasource for conversations
- [ ] Implement Isar local datasource for settings
- [ ] Build SyncQueueManager (queue, retry, backoff)
- [ ] Build ConflictResolver (latest timestamp wins)
- [ ] Build ChangeTracker (tracks what needs syncing)
- [ ] Build SyncEngine (orchestrates local -> remote -> merge)
- [ ] Connect connectivity listener to auto-sync
- [ ] Migrate existing SharedPreferences data to Isar + Firestore

### Step 6: Settings (Day 8-9)
- [ ] Build settings repository (local + remote)
- [ ] Build settings BLoC
- [ ] Build settings screen:
  - [ ] Theme toggle (dark/light/system)
  - [ ] Language selector
  - [ ] Default AI provider selector
  - [ ] API key input (encrypted storage)
  - [ ] Memory controls (enable/disable)
  - [ ] Privacy controls (analytics opt-in, data export, delete account)
  - [ ] Notification preferences

### Step 7: Integration & Polish (Day 9-10)
- [ ] Wire auth flow into existing entry point (replace onboarding check with auth check)
- [ ] Wire cloud sync into existing chat
- [ ] Wire settings into existing AI provider selection
- [ ] Handle offline states gracefully (show indicators)
- [ ] Error handling for all auth/sync operations
- [ ] Loading states for all async operations

## Acceptance Criteria (Gate)
- [ ] User can sign up with email/password
- [ ] User can sign in with Google
- [ ] User can sign in anonymously
- [ ] User can reset password
- [ ] Session persists across app restarts
- [ ] Profile created on first sign-in with default values
- [ ] Conversations sync to Firestore
- [ ] Saved answers sync to Firestore
- [ ] Settings sync to Firestore
- [ ] Works offline, queues writes, syncs when online
- [ ] Conflict resolution works (latest timestamp wins)
- [ ] User can edit profile (name, photo, country, language, persona)
- [ ] User can toggle theme (dark/light/system)
- [ ] User can select default AI provider
- [ ] User can enter/manage API keys (encrypted)
- [ ] User can export data
- [ ] User can delete account (with confirmation, deletes all data)
- [ ] All existing features continue working (chat, conversations, saved answers)

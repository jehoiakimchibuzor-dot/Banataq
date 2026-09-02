## 5. Security Architecture

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
      allow create: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.data.keys().hasAll(['uid', 'email', 'createdAt']);
    }

    match /conversations/{conversationId} {
      allow read, write: if request.auth != null
                         && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
                   && request.resource.data.userId == request.auth.uid;
      match /messages/{messageId} {
        allow read, write: if request.auth != null
          && get(/databases/$(database)/documents/conversations/$(conversationId)).data.userId == request.auth.uid;
      }
    }

    match /memories/{memoryId} {
      allow read, write: if request.auth != null
                         && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
                   && request.resource.data.userId == request.auth.uid;
    }

    match /saved_items/{itemId} {
      allow read, write: if request.auth != null
                         && resource.data.userId == request.auth.uid;
    }

    match /settings/{userId} {
      allow read, write: if request.auth != null
                         && userId == request.auth.uid;
    }

    match /feedback/{feedbackId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null
                  && request.auth.token.isAdmin == true;
    }

    match /usage_stats/{statId} {
      allow read, write: if request.auth != null
                         && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
                  && request.auth.uid == userId
                  && request.resource.size < 5 * 1024 * 1024
                  && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    match /uploads/{userId}/{fileName} {
      allow read, write: if request.auth != null
                        && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    match /public/{fileName} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### API Key Protection Strategy
1. Keys NEVER stored in client code
2. Keys encrypted at rest using flutter_secure_storage (AES-256)
3. Keys transmitted only to the AI provider's direct endpoint
4. Optional: Proxy through Cloud Functions to hide keys entirely
5. Rate limiting per user via Firestore writes check
6. Abuse detection: if >100 requests/min from same user, throttle

---

## 6. Authentication Flow

### Sequence Diagram: Google Sign-In

```
User            App             Firebase Auth       Firestore
 |               |                  |                  |
 | Tap "Sign in with Google"        |                  |
 |-------------->|                  |                  |
 |               | Launch GoogleAuth flow             |
 |               |----------------->|                  |
 | Google consent|                  |                  |
 |<--------------+                  |                  |
 | Approve       |                  |                  |
 |-------------->|                  |                  |
 |               | Google credential|                  |
 |               |----------------->|                  |
 |               | ID token + access token             |
 |               |<-----------------+                  |
 |               |                  |                  |
 |               | signInWithCredential                |
 |               |----------------->|                  |
 |               | UserCredential   |                  |
 |               |<-----------------+                  |
 |               |                  |                  |
 |               | Check if user doc exists            |
 |               |------------------------------------>|
 |               | null or doc      |                  |
 |               |<------------------------------------+|
 |               |                  |                  |
 |  [if new]     |                  |                  |
 |               | Create user doc  |                  |
 |               |------------------------------------>|
 |               | Create settings doc                 |
 |               |------------------------------------>|
 |               |                  |                  |
 | Navigate Home |                  |                  |
 |<--------------+                  |                  |
```

### Sequence Diagram: Email Sign-Up

```
User            App             Firebase Auth       Firestore
 |               |                  |                  |
 | Enter email + pwd                |                  |
 |-------------->|                  |                  |
 |               | createUserWithEmailAndPassword      |
 |               |----------------->|                  |
 |               | UserCredential   |                  |
 |               |<-----------------+                  |
 |               |                  |                  |
 |               | Send email verification             |
 |               |----------------->|                  |
 |               |                  |                  |
 |               | Create user doc  |                  |
 |               |------------------------------------>|
 |               | Create settings doc                 |
 |               |------------------------------------>|
 |               |                  |                  |
 | "Verify email sent"              |                  |
 |<--------------+                  |                  |
```

### Account Linking Flow
1. User signs in with Email
2. Goes to Settings > Account > Link Google
3. App calls: currentUser.linkWithCredential(GoogleAuthProvider.credential)
4. Both providers now under one account
5. Future sign-in with either method works

### Session Management
- Firebase Auth handles token refresh automatically
- Auth state listener in main.dart
- On token expiry, silent refresh
- On refresh failure, show re-auth dialog
- Sessions persist across app restarts (Firebase SDK)
- Sign-out clears local data + revokes tokens

---

## 7. Cloud Sync Strategy

### Architecture

```
+-----------------------------------------------------------+
|                     Sync Engine                           |
|                                                           |
|  +--------------+    +--------------+                     |
|  |  Local DB    |    |  Change      |                     |
|  |  (Isar)      |<-->|  Tracker     |                     |
|  +--------------+    +------+-------+                     |
|                             |                             |
|  +--------------+    +------+-------+                     |
|  |  Conflict    |<-->|  Queue       |                     |
|  |  Resolver    |    |  Manager     |                     |
|  +--------------+    +------+-------+                     |
|                             |                             |
|  +--------------+    +------+-------+                     |
|  |  Network     |<-->|  Firestore   |                     |
|  |  Detector    |    |  Adapter     |                     |
|  +--------------+    +--------------+                     |
+-----------------------------------------------------------+
```

### Offline-First Strategy
1. ALL reads hit local DB first (instant UI)
2. Write to local DB immediately (optimistic)
3. Queue change for Firestore sync
4. When online:
   a. Flush pending writes
   b. Pull remote changes
   c. Merge with conflict resolution
5. Conflict resolution: "Last write wins" by default
   - Messages: appends are idempotent, no conflict
   - Settings: latest timestamp wins
   - Profile: field-level merge
6. On connectivity change: auto-sync

### Sync Queue Manager
```dart
class SyncQueueManager {
  // Pending operations stored in local DB
  // Each operation has: id, type, collection, docId, data, timestamp, retryCount
  // Operations: create, update, delete
  // On success, remove from queue
  // On failure, retry with exponential backoff (max 5 retries)
  // After max retries, mark as failed, alert user
  // Queue is FIFO with priority:
  //   1. Auth operations
  //   2. Message sends
  //   3. Settings updates
  //   4. Conversation metadata
  //   5. Analytics
}
```

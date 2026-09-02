# Banataq — Architecture & Design

## Identity Document

### Mission
Help Africans get things done with AI.

### Vision
Become Africa's most trusted AI assistant.

### Core Principles
- **Fast** — Every interaction under 2 seconds
- **Reliable** — Works offline-first, syncs seamlessly
- **Privacy-first** — User data is encrypted, portable, and deletable
- **Practical** — Every feature solves a real daily problem
- **Multilingual** — English, Hausa, Yoruba, Igbo, Pidgin
- **Offline-friendly** — Core features work without internet
- **Affordable** — Free tier viable; premium adds value, not ransom

### Target Users
1. Students
2. Professionals
3. Small business owners
4. Developers (via API)

### Non-goals
- Not a social network
- Not a generic chatbot wrapper
- No gimmick features that don't serve daily utility

---

## 1. Overall System Architecture

```
+-----------------------------------------------------------+
|                     Client (Flutter)                       |
|  +----------+  +----------+  +---------------------------+ |
|  |   UI     |  |  State   |  |     Sync Engine           | |
|  |  Layer   |<-|  (BLoC)  |<-|  Offline-first            | |
|  |          |  |          |  |  Conflict resolution       | |
|  +----------+  +----------+  +------------+--------------+ |
|         |              |                   |               |
|  +------+--------------+-------------------+-----------+  |
|  |                 Service Layer                       |  |
|  |  +--------+ +--------+ +--------+ +--------+      |  |
|  |  | Auth   | |  AI    | |Storage | |Memory  |      |  |
|  |  |Service | |Provider| |Service | |Service |      |  |
|  |  +--------+ +--------+ +--------+ +--------+      |  |
|  +-----------------------------------------------------+ |
+----------------------------+-----------------------------+
                             | HTTPS / WebSocket / SSE
+----------------------------+-----------------------------+
|                     Cloud (Firebase)                     |
|  +----------+  +----------+  +-------------------------+ |
|  | Firestore |  |  Auth    |  |  Cloud Storage         | |
|  | (NoSQL DB)|  |          |  |  (Files, images)       | |
|  +----------+  +----------+  +-------------------------+ |
|  +----------+  +----------+  +-------------------------+ |
|  |Functions |  |Analytics |  |  Remote Config          | |
|  |(Tool exe)|  |          |  |  (Feature flags)        | |
|  +----------+  +----------+  +-------------------------+ |
+----------------------------+-----------------------------+
                             |
+----------------------------+-----------------------------+
|                   External AI APIs                       |
|  +----------+  +----------+  +-------------------------+ |
|  |  OpenAI  |  |  Gemini  |  |  Local (offline)       | |
|  +----------+  +----------+  +-------------------------+ |
+-----------------------------------------------------------+
```

### Data Flow: Chat Sync
```
User sends message
  -> Local write (optimistic)
  -> UI updates immediately
  -> Sync engine enqueues
  -> Firestore write (background)
  -> AI response received
  -> Local write + Firestore write
  -> UI updates
```

---

## 2. Firestore Database Schema

### Collections
- `users/{userId}`
- `conversations/{conversationId}`
- `memories/{userId}`
- `saved_items/{savedItemId}`
- `settings/{userId}`
- `feedback/{feedbackId}`
- `usage_stats/{statId}`

### Document Schemas

#### `users/{userId}`
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "username": "string",
  "photoUrl": "string",
  "bio": "string",
  "country": "string",
  "language": "string",
  "timezone": "string",
  "persona": "student | business | creator | general",
  "preferredAiModel": "local | openai | gemini",
  "preferredResponseStyle": "concise | detailed | balanced",
  "subscriptionTier": "free | premium",
  "subscriptionExpiry": "timestamp | null",
  "usageStats": {
    "messagesSent": 0,
    "conversationsCreated": 0,
    "storageUsedBytes": 0
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "lastLoginAt": "timestamp"
}
```

#### `conversations/{conversationId}`
```json
{
  "id": "string",
  "userId": "string",
  "title": "string",
  "aiProvider": "local | openai | gemini",
  "aiModel": "string",
  "messages": [
    {
      "id": "string",
      "role": "user | assistant | system",
      "content": "string",
      "timestamp": "timestamp",
      "metadata": {
        "tokensUsed": 0,
        "model": "string",
        "processingTimeMs": 0
      }
    }
  ],
  "tags": ["string"],
  "isStarred": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "lastMessageAt": "timestamp",
  "deletedAt": "timestamp | null"
}
```

#### `memories/{userId}`
```json
{
  "id": "string",
  "userId": "string",
  "type": "preference | fact | project | style",
  "key": "string",
  "value": "string",
  "context": "string",
  "source": "explicit | inferred",
  "confirmed": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### `saved_items/{savedItemId}`
```json
{
  "id": "string",
  "userId": "string",
  "type": "answer | prompt | message",
  "content": "string",
  "tags": ["string"],
  "conversationId": "string | null",
  "aiProvider": "string",
  "createdAt": "timestamp"
}
```

#### `settings/{userId}`
```json
{
  "userId": "string",
  "theme": "dark | light | system",
  "language": "en | ha | yo | ig | pcm",
  "defaultAiProvider": "local | openai | gemini",
  "apiKeys": {
    "openai": "encrypted_string",
    "gemini": "encrypted_string"
  },
  "memoryEnabled": true,
  "analyticsEnabled": true,
  "notificationsEnabled": {
    "dailyReminder": false,
    "studyReminder": false,
    "productivityReminder": false
  },
  "privacy": {
    "shareUsageData": true,
    "saveChatHistory": true,
    "allowTraining": false
  },
  "updatedAt": "timestamp"
}
```

#### `feedback/{feedbackId}`
```json
{
  "userId": "string",
  "type": "bug | feature | improvement | rating",
  "category": "string",
  "message": "string",
  "rating": 0,
  "metadata": {
    "appVersion": "string",
    "platform": "android | ios | web",
    "conversationId": "string | null"
  },
  "createdAt": "timestamp"
}
```

#### `usage_stats/{statId}`
```json
{
  "userId": "string",
  "date": "YYYY-MM-DD",
  "messagesSent": 0,
  "aiRequests": {
    "local": 0,
    "openai": 0,
    "gemini": 0
  },
  "featuresUsed": {
    "chat": 0,
    "voice": 0,
    "camera": 0,
    "files": 0,
    "quiz": 0,
    "flashcards": 0
  },
  "sessionDurationMs": 0,
  "createdAt": "timestamp"
}
```

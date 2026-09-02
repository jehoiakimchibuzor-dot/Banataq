## 8. AI Provider Abstraction

```dart
// Current abstraction is good, extend for streaming
abstract class AiProvider {
  String get name;
  String get modelName;
  bool get supportsStreaming;
  bool get supportsFunctions;

  Future<String> generateResponse({
    required String prompt,
    String? persona,
    List<Map<String, String>>? history,
    List<Memory>? memories,
  });

  // Streaming support (Phase 2)
  Stream<String> generateResponseStream({
    required String prompt,
    String? persona,
    List<Map<String, String>>? history,
    List<Memory>? memories,
  });

  // Function/tool calling (Phase 9)
  Future<AiFunctionResponse> generateWithFunctions({
    required String prompt,
    required List<AiFunction> functions,
  });
}

// Provider routing
class AiService {
  final Map<AiProviderType, AiProvider> _providers;
  final PromptManager _promptManager;

  Future<String> reply({
    required String input,
    required AiProviderType preferredProvider,
    String? persona,
    List<Map<String, String>>? history,
    List<Memory>? memories,
  }) async {
    final provider = _providers[preferredProvider];
    if (provider == null) throw AiProviderNotFoundException();
    final prompt = _promptManager.buildPrompt(input, persona: persona, memories: memories);
    return provider.generateResponse(
      prompt: prompt, persona: persona, history: history, memories: memories,
    );
  }
}
```

---

## 9. Sequence Diagram: Chat Sync

```
User            Local DB        Sync Engine       Firestore       AI Provider
 |                 |                |                 |                |
 | Type message    |                |                 |                |
 +---------------->|                |                 |                |
 | Optimistic      |                |                 |                |
 |<----------------+                |                 |                |
 |                 |                |                 |                |
 | UI shows msg    |                |                 |                |
 |                 |                |                 |                |
 | Send tap        |                |                 |                |
 +---------------->|                |                 |                |
 |                 | Add to queue   |                 |                |
 |                 +--------------->|                 |                |
 |                 |                | Write message   |                |
 |                 |                +---------------->|                |
 |                 |                | Acknowledge     |                |
 |                 |                |<----------------+                |
 |                 | Remove from q  |                 |                |
 |                 |<---------------+                 |                |
 |                 |                |                 |                |
 |                 |                | Read memories   |                |
 |                 |                +---------------->|                |
 |                 |                | Memories        |                |
 |                 |                |<----------------+                |
 |                 |                |                 |                |
 |                 |                | Send to AI      |                |
 |                 |                +--------------------------------->|
 |                 |                | Stream response |                |
 |                 |                |<---------------------------------+|
 |                 |                |                 |                |
 | Stream AI reply |                |                 |                |
 |<----------------+                |                 |                |
 |                 |                |                 |                |
 | Write AI reply  |                |                 |                |
 +---------------->|                |                 |                |
 |                 | Add to queue   |                 |                |
 |                 +--------------->|                 |                |
 |                 |                | Write response  |                |
 |                 |                +---------------->|                |
 |                 |                |                 |                |
 | Done            |                |                 |                |
 |<----------------+                |                 |                |
```

---

## 10. Local Database Schema (Isar)

```dart
import 'package:isar/isar.dart';

@collection
class LocalConversation {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String title;
  late String aiProvider;
  late String aiModel;
  late bool isStarred;
  late String? tags;
  late DateTime createdAt;
  late DateTime updatedAt;
  late DateTime lastMessageAt;
  late DateTime? deletedAt;
  late bool isSynced;
  late DateTime? lastSyncedAt;

  @Backlink(to: 'conversation')
  final messages = IsarLinks<LocalMessage>();
}

@collection
class LocalMessage {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String conversationId;
  late String role;
  late String content;
  late DateTime timestamp;
  late int? tokensUsed;
  late bool isSynced;
  final conversation = IsarLink<LocalConversation>();
}

@collection
class LocalMemory {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String type;
  late String key;
  late String value;
  late String? context;
  late String source;
  late bool confirmed;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;
}

@collection
class SyncQueueEntry {
  Id id = Isar.autoIncrement;
  late String operation;
  late String collection;
  late String docId;
  late String? data;
  late DateTime createdAt;
  late int retryCount;
  late String status;
  late String? error;
}
```

---

## 11. Analytics Architecture

```dart
// Privacy-conscious, all analytics opt-in
abstract class AnalyticsService {
  Future<void> trackEvent(String name, {Map<String, dynamic>? properties});
  Future<void> trackScreen(String screenName);
  Future<void> identifyUser(String userId, {Map<String, dynamic>? traits});
  Future<void> setConsent(bool granted);
}

// Implementation uses Firebase Analytics
// No PII sent to analytics
// User can opt-out in Settings > Privacy
// Events: message_sent, ai_response_received, file_uploaded,
//         quiz_generated, flashcard_created, feature_used
```

---

## 12. Error Handling Strategy

```dart
sealed class AppResult<T> {
  const AppResult();
}

class Success<T> extends AppResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends AppResult<T> {
  final AppError error;
  const Failure(this.error);
}

sealed class AppError {
  const AppError();
}

class NetworkError extends AppError {}
class AuthError extends AppError {}
class ServerError extends AppError {}
class CacheError extends AppError {}
class AiProviderError extends AppError {}
class ValidationError extends AppError {}
class NotFoundError extends AppError {}
class SyncConflictError extends AppError {}
```

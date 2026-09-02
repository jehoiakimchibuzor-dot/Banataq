# Memory Architecture

## Layered Memory System

```
+-----------------------------------------------------------+
|                    Memory Service                         |
|                                                           |
|  +---------------+  +----------+  +--------------------+  |
|  | User Profile  |  | Long-Term|  | Short-Term Context |  |
|  | (Persistent)  |  | (Persist)|  | (Session-scoped)  |  |
|  +---------------+  +----------+  +--------------------+  |
|  +----------+  +------------+                            |
|  | Session  |  | Project    |                            |
|  | (Runtime)|  | (Timed)    |                            |
|  +----------+  +------------+                            |
+-----------------------------------------------------------+
```

## 1. Memory Types & Lifecycles

| Type | Scope | Persistence | Example | TTL |
|------|-------|-------------|---------|-----|
| **User Profile** | Global | Permanent | "User is a student" | Never |
| **Long-term** | Global | Permanent | "User prefers concise answers" | Until deleted |
| **Short-term Context** | Conversation | Conversation | "We were discussing calculus" | Conversation ends |
| **Session** | App session | Runtime only | "User asked about limits" | App close |
| **Project** | Tagged scope | Configurable | "User is building a fintech app" | Until archived |

## 2. Firestore Schema

### `memories/{userId}` — Embedded subcollection approach

```dart
enum MemoryType {
  profile,     // Permanent user attributes
  fact,        // Things the user has told Banataq
  preference,  // Stylistic preferences (tone, detail level)
  project,     // Project/task context
  session,     // Temporary (synced but can be purged)
}

class Memory {
  final String id;
  final String userId;
  final MemoryType type;
  final String key;       // e.g., "study_level", "preferred_language"
  final String value;     // e.g., "university", "concise"
  final String? context;  // e.g., "User mentioned this during exam prep"
  final MemorySource source; // explicit (user told) or inferred (AI guessed)
  final double confidence;   // 0.0 to 1.0 for inferred memories
  bool confirmed;            // User has verified this memory
  final DateTime createdAt;
  DateTime updatedAt;
  final DateTime? expiresAt; // null = permanent, set = TTL
}
```

## 3. Memory Injection into AI Prompts

```dart
class MemoryService {
  Future<String> buildMemoryContext(String userId) async {
    final profile = await _getProfileMemories(userId);    // Always included
    final longTerm = await _getLongTermMemories(userId);  // Always included
    final project = await _getActiveProjectMemory(userId); // If project active
    final session = _sessionCache[userId];                 // From memory

    if (profile.isEmpty && longTerm.isEmpty) return '';

    return '''
## Banataq's Knowledge About You
${profile.map((m) => '- ${m.key}: ${m.value}').join('\n')}
${longTerm.map((m) => '- ${m.key}: ${m.value}').join('\n')}
${project.isNotEmpty ? '## Current Project\n${project.map((m) => '- ${m.key}: ${m.value}').join('\n')}' : ''}
---
This memory persists across conversations. User can view, edit, or delete any memory.
''';
  }

  // Extract potential memories from AI responses
  Future<void> extractMemories(
    String userId,
    String userMessage,
    String aiResponse,
  ) async {
    // Phase 1: Rule-based extraction (simple)
    // Phase 2: AI-assisted extraction (send to LLM to extract facts)
    // Phase 3: Fully automated with confidence scoring
  }
}
```

## 4. Memory Lifecycle Rules

```
User Profile:   Created on sign-up, updated by user, never auto-deleted
Long-term:      Created by user or inferred+confirmed, deleted by user only
Short-term:     Auto-created from conversation, deleted when conversation deleted
Session:        Lives in memory cache, deleted on app close
Project:        Created by user, auto-archived after 90 days of inactivity
```

## 5. UI Representation

- **Profile screen**: User profile fields (name, photo, persona, preferences)
- **Memory manager screen**: Long-term memories with edit/delete
- **Memory is shown** as a subtle chip/banner in chat: "Banataq remembers you prefer..."
- **User can say**: "Forget that" or "Remember this" directly in chat

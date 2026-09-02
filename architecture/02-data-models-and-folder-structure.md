## 3. Data Models (Dart)

```dart
// lib/core/models/user_profile.dart
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? bio;
  final String country;
  final String language;
  final String timezone;
  final UserPersona persona;
  final AiProviderType preferredAiModel;
  final ResponseStyle preferredResponseStyle;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final UsageStats usageStats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLoginAt;
}

// lib/core/models/conversation.dart
class Conversation {
  final String id;
  final String userId;
  String title;
  final AiProviderType aiProvider;
  final String aiModel;
  List<ChatMessage> messages;
  List<String> tags;
  bool isStarred;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime lastMessageAt;
  DateTime? deletedAt;
  bool get isDeleted => deletedAt != null;
}

// lib/core/models/chat_message.dart
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageMetadata? metadata;
}

// lib/core/models/memory.dart
class Memory {
  final String id;
  final String userId;
  final MemoryType type;
  final String key;
  final String value;
  final String? context;
  final MemorySource source;
  bool confirmed;
  final DateTime createdAt;
  DateTime updatedAt;
}

// lib/core/models/saved_item.dart
class SavedItem {
  final String id;
  final String userId;
  final SavedItemType type;
  final String content;
  List<String> tags;
  final String? conversationId;
  final String aiProvider;
  final DateTime createdAt;
}

// lib/core/models/user_settings.dart
class UserSettings {
  final String userId;
  ThemeMode theme;
  String language;
  AiProviderType defaultAiProvider;
  Map<String, String> apiKeys;
  bool memoryEnabled;
  bool analyticsEnabled;
  NotificationPreferences notifications;
  PrivacySettings privacy;
}

// lib/core/models/feedback.dart
class Feedback {
  final String? id;
  final String userId;
  final FeedbackType type;
  final String? category;
  final String message;
  final int? rating;
  final FeedbackMetadata? metadata;
}

// lib/core/models/usage_stats.dart
class UsageStats {
  final String userId;
  final String date;
  int messagesSent;
  Map<AiProviderType, int> aiRequests;
  Map<String, int> featuresUsed;
  int sessionDurationMs;
}
```

---

## 4. Folder Structure (Clean Architecture)

```
lib/
+-- core/
|   +-- constants/
|   |   +-- app_constants.dart
|   |   +-- firestore_constants.dart
|   |   +-- api_constants.dart
|   +-- errors/
|   |   +-- exceptions.dart
|   |   +-- failures.dart
|   +-- network/
|   |   +-- connectivity_service.dart
|   |   +-- network_info.dart
|   +-- theme/
|   |   +-- app_theme.dart
|   |   +-- theme_service.dart
|   +-- utils/
|   |   +-- validators.dart
|   |   +-- formatters.dart
|   |   +-- debouncer.dart
|   +-- models/
|       +-- user_profile.dart
|       +-- conversation.dart
|       +-- chat_message.dart
|       +-- memory.dart
|       +-- saved_item.dart
|       +-- user_settings.dart
|       +-- feedback.dart
|       +-- usage_stats.dart
+-- data/
|   +-- datasources/
|   |   +-- local/
|   |   |   +-- local_database.dart
|   |   |   +-- shared_prefs_datasource.dart
|   |   |   +-- secure_storage_datasource.dart
|   |   +-- remote/
|   |   |   +-- firestore_datasource.dart
|   |   |   +-- auth_datasource.dart
|   |   |   +-- storage_datasource.dart
|   |   |   +-- ai_datasource.dart
|   |   +-- cache/
|   |       +-- memory_cache.dart
|   |       +-- disk_cache.dart
|   +-- repositories/
|   |   +-- auth_repository_impl.dart
|   |   +-- conversation_repository_impl.dart
|   |   +-- memory_repository_impl.dart
|   |   +-- saved_item_repository_impl.dart
|   |   +-- settings_repository_impl.dart
|   |   +-- ai_repository_impl.dart
|   |   +-- feedback_repository_impl.dart
|   |   +-- usage_stats_repository_impl.dart
|   +-- sync/
|       +-- sync_engine.dart
|       +-- conflict_resolver.dart
|       +-- queue_manager.dart
|       +-- change_tracker.dart
+-- domain/
|   +-- entities/
|   |   +-- user_profile.dart
|   |   +-- conversation.dart
|   |   +-- chat_message.dart
|   |   +-- memory.dart
|   |   +-- saved_item.dart
|   |   +-- user_settings.dart
|   |   +-- feedback.dart
|   |   +-- usage_stats.dart
|   +-- repositories/
|   |   +-- auth_repository.dart
|   |   +-- conversation_repository.dart
|   |   +-- memory_repository.dart
|   |   +-- saved_item_repository.dart
|   |   +-- settings_repository.dart
|   |   +-- ai_repository.dart
|   |   +-- feedback_repository.dart
|   |   +-- usage_stats_repository.dart
|   +-- usecases/
|       +-- auth/
|       |   +-- sign_in_with_google.dart
|       |   +-- sign_in_with_email.dart
|       |   +-- sign_up_with_email.dart
|       |   +-- sign_out.dart
|       |   +-- reset_password.dart
|       |   +-- get_current_user.dart
|       +-- conversation/
|       |   +-- create_conversation.dart
|       |   +-- delete_conversation.dart
|       |   +-- get_conversations.dart
|       |   +-- send_message.dart
|       |   +-- star_conversation.dart
|       +-- memory/
|       |   +-- get_memories.dart
|       |   +-- create_memory.dart
|       |   +-- confirm_memory.dart
|       |   +-- delete_memory.dart
|       +-- settings/
|           +-- get_settings.dart
|           +-- update_settings.dart
|           +-- export_data.dart
+-- presentation/
|   +-- blocs/
|   |   +-- auth_bloc/
|   |   +-- chat_bloc/
|   |   +-- conversation_bloc/
|   |   +-- memory_bloc/
|   |   +-- settings_bloc/
|   |   +-- sync_bloc/
|   |   +-- profile_bloc/
|   +-- screens/
|   |   +-- auth/ (login, signup, forgot_password, widgets/)
|   |   +-- home/ (home_screen, widgets/)
|   |   +-- chat/ (chat_screen, widgets/)
|   |   +-- profile/ (profile_screen, widgets/)
|   |   +-- settings/ (settings_screen, widgets/)
|   |   +-- saved/ (saved_items_screen, widgets/)
|   +-- router/
|       +-- app_router.dart
|       +-- route_names.dart
+-- services/
|   +-- ai/
|   |   +-- ai_provider.dart (abstract)
|   |   +-- local_assistant.dart
|   |   +-- openai_provider.dart
|   |   +-- gemini_provider.dart
|   |   +-- ai_service.dart
|   |   +-- streaming_service.dart
|   |   +-- prompt_manager.dart
|   +-- auth/
|   |   +-- auth_service.dart
|   |   +-- google_auth_service.dart
|   |   +-- email_auth_service.dart
|   +-- storage/
|   |   +-- storage_service.dart
|   |   +-- local_storage_service.dart
|   |   +-- cloud_storage_service.dart
|   +-- sync/
|   |   +-- firestore_sync_service.dart
|   +-- analytics/
|   |   +-- analytics_service.dart
|   |   +-- screen_tracker.dart
|   +-- feedback/
|       +-- feedback_service.dart
+-- main.dart
```

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../models/onboarding_preferences.dart';
import 'assistant_service.dart';
import 'secure_key_store.dart';

class StorageService {
  static const _profileKey = 'user_profile';
  static const _conversationsKey = 'conversations';
  static const _savedAnswersKey = 'saved_answers';
  static const _aiConfigKey = 'ai_config';
  static const _ollamaUrlKey = 'ollama_server_url';
  static const _ollamaModelKey = 'ollama_model_name';
  static const _geminiModelKey = 'gemini_model_name';
  static const _groqModelKey = 'groq_model_name';
  static const _openRouterModelKey = 'openrouter_model_name';
  static const _onboardingKey = 'onboarding_complete';
  static const _personalizationKey = 'onboarding_preferences';
  static const _personalizationDoneKey = 'personalization_complete';
  static const _firstRunCompleteKey = 'first_run_complete';

  /// True once the user has been through the first-run onboarding.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Scopes a key to a user so switching accounts never leaks data. Falls back
  /// to the unscoped key when no uid is available (e.g. guest/onboarding).
  String _scoped(String baseKey, String? userId) {
    if (userId == null || userId.isEmpty) return baseKey;
    return '${baseKey}_$userId';
  }

  Future<UserProfile?> loadProfile({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_profileKey, userId));
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoped(_profileKey, userId),
      jsonEncode(profile.toJson()),
    );
  }

  Future<List<Conversation>> loadConversations({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_conversationsKey, userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConversations(
    List<Conversation> conversations, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoped(_conversationsKey, userId),
      jsonEncode(conversations.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<ChatMessage>> loadSavedAnswers({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_savedAnswersKey, userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSavedAnswers(
    List<ChatMessage> answers, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoped(_savedAnswersKey, userId),
      jsonEncode(answers.map((a) => a.toJson()).toList()),
    );
  }

  // --- helpers for SecureKeyStore migration ---
  static SecureKeyStore? _testSecureStore;
  // Visible for testing — inject a fake to avoid platform channel.
  static void setTestSecureStore(SecureKeyStore? store) => _testSecureStore = store;

  SecureKeyStore get _secure => _testSecureStore ?? SecureKeyStore();

  Future<String?> _readSecureForProvider(AiProviderType type) async {
    try {
      switch (type) {
        case AiProviderType.gemini:
          return await _secure.readGemini().timeout(const Duration(milliseconds: 800), onTimeout: () => null);
        case AiProviderType.groq:
          return await _secure.readGroq().timeout(const Duration(milliseconds: 800), onTimeout: () => null);
        case AiProviderType.openRouter:
          return await _secure.readOpenRouter().timeout(const Duration(milliseconds: 800), onTimeout: () => null);
        case AiProviderType.openai:
          return await _secure.readOpenAI().timeout(const Duration(milliseconds: 800), onTimeout: () => null);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecureForProvider(AiProviderType type, String key) async {
    try {
      switch (type) {
        case AiProviderType.gemini:
          return await _secure.writeGemini(key).timeout(const Duration(milliseconds: 800), onTimeout: () {});
        case AiProviderType.groq:
          return await _secure.writeGroq(key).timeout(const Duration(milliseconds: 800), onTimeout: () {});
        case AiProviderType.openRouter:
          return await _secure.writeOpenRouter(key).timeout(const Duration(milliseconds: 800), onTimeout: () {});
        case AiProviderType.openai:
          return await _secure.writeOpenAI(key).timeout(const Duration(milliseconds: 800), onTimeout: () {});
        default:
          return;
      }
    } catch (_) {}
  }

  Future<void> _removeLegacyApiKey(
    SharedPreferences prefs,
    AiProviderType provider,
  ) async {
    final raw = prefs.getString(_aiConfigKey);
    if (raw == null) return;
    try {
      jsonDecode(raw) as Map<String, dynamic>;
      // Keep provider, drop apiKey
      await prefs.setString(
        _aiConfigKey,
        jsonEncode({'provider': provider.name}),
      );
    } catch (_) {
      await prefs.setString(
        _aiConfigKey,
        jsonEncode({'provider': provider.name}),
      );
    }
  }

  Future<Map<String, dynamic>> loadAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_aiConfigKey);
    AiProviderType provider = AiProviderType.ollama;
    String legacyApiKey = '';
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        provider = AiProviderType.values.firstWhere(
          (e) => e.name == data['provider'],
          orElse: () => AiProviderType.ollama,
        );
        legacyApiKey = data['apiKey'] as String? ?? '';
      } catch (_) {
        // corrupted, treat as ollama with no key
      }
    }

    // 1. Secure already contains key → use it, clean legacy if needed (idempotent)
    try {
      final secureKey = await _readSecureForProvider(provider);
      if (secureKey != null && secureKey.trim().isNotEmpty) {
        if (legacyApiKey.isNotEmpty) {
          await _removeLegacyApiKey(prefs, provider);
        }
        return {'provider': provider, 'apiKey': secureKey};
      }
    } catch (_) {
      // secure read failed — fall through to legacy
    }

    // 2. No secure key, but legacy has one → migrate
    if (legacyApiKey.trim().isNotEmpty) {
      try {
        await _writeSecureForProvider(provider, legacyApiKey.trim());
        final verify = await _readSecureForProvider(provider);
        if (verify == legacyApiKey.trim()) {
          await _removeLegacyApiKey(prefs, provider);
          return {'provider': provider, 'apiKey': verify ?? ''};
        }
      } catch (_) {
        // migration failed — return legacy without destroying
        return {'provider': provider, 'apiKey': legacyApiKey};
      }
      // verify mismatch — return legacy to avoid data loss
      return {'provider': provider, 'apiKey': legacyApiKey};
    }

    // 3. No credential configured
    return {'provider': provider, 'apiKey': ''};
  }

  Future<void> saveAiConfig(AiProviderType provider, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = apiKey.trim();
    // Non-secret provider stays in SharedPreferences
    await prefs.setString(
      _aiConfigKey,
      jsonEncode({'provider': provider.name}),
    );
    // Secret goes to SecureKeyStore (or cleared)
    if (trimmed.isEmpty) {
      // Clear secure for this provider (best-effort)
      try {
        if (provider == AiProviderType.gemini) await _secure.delete('gemini_api_key').timeout(const Duration(milliseconds: 800), onTimeout: () {});
        if (provider == AiProviderType.groq) await _secure.delete('groq_api_key').timeout(const Duration(milliseconds: 800), onTimeout: () {});
        if (provider == AiProviderType.openRouter) await _secure.delete('openrouter_api_key').timeout(const Duration(milliseconds: 800), onTimeout: () {});
        if (provider == AiProviderType.openai) await _secure.delete('openai_api_key').timeout(const Duration(milliseconds: 800), onTimeout: () {});
      } catch (_) {}
      return;
    }
    await _writeSecureForProvider(provider, trimmed);
  }

  Future<String> loadOllamaUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ollamaUrlKey) ?? '';
  }

  Future<void> saveOllamaUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ollamaUrlKey, url);
  }

  Future<String> loadOllamaModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ollamaModelKey) ?? '';
  }

  Future<void> saveOllamaModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ollamaModelKey, model);
  }

  Future<String> loadGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiModelKey) ?? '';
  }

  Future<void> saveGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiModelKey, model);
  }

  Future<String> loadGroqModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groqModelKey) ?? '';
  }

  Future<void> saveGroqModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groqModelKey, model);
  }

  Future<String> loadOpenRouterModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openRouterModelKey) ?? '';
  }

  Future<void> saveOpenRouterModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openRouterModelKey, model);
  }

  Future<OnboardingPreferences?> loadOnboardingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personalizationKey);
    if (raw == null) return null;
    try {
      return OnboardingPreferences.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOnboardingPreferences(OnboardingPreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_personalizationKey, prefs.encode());
    await sp.setBool(_personalizationDoneKey, prefs.isComplete);
  }

  Future<bool> isPersonalizationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_personalizationDoneKey) ?? false;
  }

  Future<void> setPersonalizationComplete({bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_personalizationDoneKey, value);
  }

  Future<bool> isFirstRunComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunCompleteKey) ?? false;
  }

  Future<void> setFirstRunComplete({bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunCompleteKey, value);
  }

  Future<void> clearOnboardingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_personalizationKey);
    await prefs.remove(_personalizationDoneKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
